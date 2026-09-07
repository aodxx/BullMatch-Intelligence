"""Operational source-agnostic collection orchestration.

This module composes the already-approved runtime boundaries into one safe poll:
approved source registry -> persisted checkpoint -> SOURCE_MONITORING run ->
validated connector execution -> atomic source-item/evidence/checkpoint persistence.

It intentionally exposes no canonical Bull/Match/history write path and performs
no source-specific network access by itself.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping, Protocol

from .orchestration import CollectionRunState
from .persistence import IngestionPersistenceAdapter, PersistenceResult, persist_poll_execution
from .registry import ApprovedSourceRegistry
from .runner import Connector, JsonObject, PollExecution, run_connector_poll


class CheckpointReader(Protocol):
    def read_checkpoint(self, source_id: str) -> JsonObject | None: ...


class CollectionRunStore(Protocol):
    def save(self, state: CollectionRunState) -> None: ...


@dataclass(frozen=True)
class OperationalRunResult:
    run: JsonObject
    poll_request: JsonObject
    execution: PollExecution
    persistence: PersistenceResult


def run_collection_once(
    *,
    registry: ApprovedSourceRegistry,
    source_id: str,
    connector: Connector,
    checkpoint_reader: CheckpointReader,
    persistence: IngestionPersistenceAdapter,
    run_store: CollectionRunStore,
    agent_version: str,
    started_at: str,
    completed_at: str,
    initial_cursor: Mapping[str, Any],
    run_id: str | None = None,
    correlation_id: str | None = None,
    window_from: str | None = None,
    window_to: str | None = None,
    deadline_at: str | None = None,
    max_items: int | None = None,
    max_requests: int | None = None,
) -> OperationalRunResult:
    """Execute and persist one connector poll under BullMatch trust boundaries.

    ``initial_cursor`` is used only when no persisted source checkpoint exists.
    Callers must choose it from the connector/source contract; this function does
    not invent source-specific cursor semantics.

    Failures are persisted as a terminal SOURCE_MONITORING run when possible and
    then re-raised. Error details deliberately record only the exception type so
    credentials or source response bodies cannot leak into persisted run state.
    """

    source = registry.get_pollable(source_id)
    persisted_cursor = checkpoint_reader.read_checkpoint(source_id)
    cursor = dict(persisted_cursor if persisted_cursor is not None else initial_cursor)

    state = CollectionRunState.start(
        source,
        agent_version=agent_version,
        started_at=started_at,
        run_id=run_id,
        correlation_id=correlation_id,
    )
    run_store.save(state)

    try:
        request = state.build_poll_request(
            source,
            cursor=cursor,
            window_from=window_from,
            window_to=window_to,
            deadline_at=deadline_at,
            max_items=max_items,
            max_requests=max_requests,
        )
        execution = run_connector_poll(connector, request)
        persisted = persist_poll_execution(persistence, execution, expected_cursor=cursor)

        created = sum(1 for item in persisted.staged_items if item.created)
        evidence_refs = sum(len(item.evidence_refs) for item in persisted.staged_items)
        state.metrics["items_persisted_created"] = created
        state.metrics["evidence_refs_persisted"] = evidence_refs
        state.record_execution(execution)
        terminal = state.finish(completed_at=completed_at)
        run_store.save(state)
        return OperationalRunResult(
            run=terminal,
            poll_request=request,
            execution=execution,
            persistence=persisted,
        )
    except Exception as exc:
        if state.status == "RUNNING":
            state.fail(
                code="COLLECTION_RUN_FAILED",
                message="Source-agnostic collection run failed before successful completion.",
                occurred_at=completed_at,
                retryable=False,
                details={"exception_type": type(exc).__name__},
            )
            run_store.save(state)
        raise
