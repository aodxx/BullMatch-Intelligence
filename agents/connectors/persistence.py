"""Persistence-neutral transactional staging for connector output.

The interfaces in this module define the atomic boundary future database
adapters must implement: normalized source items/evidence are staged together
with the safe connector checkpoint, then committed once. No canonical BullMatch
history is writable through this contract.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass
from typing import Any, Mapping, Protocol

from .runner import ContractError, JsonObject, PollExecution


class PersistenceError(ContractError):
    """Raised when staging/checkpoint invariants are violated."""


@dataclass(frozen=True)
class StagedItem:
    item_ref: str
    created: bool
    evidence_refs: tuple[str, ...]


@dataclass(frozen=True)
class PersistenceResult:
    staged_items: tuple[StagedItem, ...]
    committed_cursor: JsonObject
    checkpoint_advanced: bool


class IngestionTransaction(Protocol):
    """One atomic source/run persistence transaction."""

    source_id: str
    run_id: str
    correlation_id: str

    def stage_item(self, envelope: Mapping[str, Any]) -> StagedItem: ...

    def set_checkpoint(self, cursor: Mapping[str, Any], *, advanced: bool) -> None: ...

    def commit(self) -> None: ...

    def rollback(self) -> None: ...


class IngestionPersistenceAdapter(Protocol):
    """Adapter boundary for future PostgreSQL/Supabase implementations."""

    def begin(
        self,
        *,
        source_id: str,
        run_id: str,
        correlation_id: str,
        expected_cursor: Mapping[str, Any],
    ) -> IngestionTransaction: ...


def persist_poll_execution(
    adapter: IngestionPersistenceAdapter,
    execution: PollExecution,
    *,
    expected_cursor: Mapping[str, Any],
) -> PersistenceResult:
    """Atomically persist validated normalized items/evidence + safe checkpoint.

    ``execution`` must already come from ``run_connector_poll``. If any staging
    operation or checkpoint update fails, the transaction is rolled back and the
    adapter must leave both staged evidence and cursor state unchanged.
    """

    result = execution.result
    tx = adapter.begin(
        source_id=result["source_id"],
        run_id=result["run_id"],
        correlation_id=result["correlation_id"],
        expected_cursor=expected_cursor,
    )
    staged: list[StagedItem] = []
    try:
        for envelope in result["items"]:
            if envelope["source_id"] != tx.source_id:
                raise PersistenceError("persistence transaction rejected cross-source envelope")
            if envelope["correlation_id"] != tx.correlation_id:
                raise PersistenceError("persistence transaction rejected cross-correlation envelope")
            staged.append(tx.stage_item(envelope))

        tx.set_checkpoint(execution.committed_cursor, advanced=execution.checkpoint_advanced)
        tx.commit()
    except Exception:
        tx.rollback()
        raise

    return PersistenceResult(
        staged_items=tuple(staged),
        committed_cursor=dict(execution.committed_cursor),
        checkpoint_advanced=execution.checkpoint_advanced,
    )


class InMemoryIngestionPersistence:
    """Deterministic adapter used only for conformance tests.

    It models the future database transaction semantics without network or
    Production writes. State is copied at transaction start and replaced only
    by ``commit``.
    """

    def __init__(self) -> None:
        self.items: dict[tuple[str, str], JsonObject] = {}
        self.evidence: dict[str, tuple[JsonObject, ...]] = {}
        self.cursors: dict[str, JsonObject] = {}

    def begin(
        self,
        *,
        source_id: str,
        run_id: str,
        correlation_id: str,
        expected_cursor: Mapping[str, Any],
    ) -> "InMemoryIngestionTransaction":
        current = self.cursors.get(source_id)
        if current is not None and current != dict(expected_cursor):
            raise PersistenceError("stored checkpoint does not match expected cursor")
        if current is None:
            self.cursors[source_id] = copy.deepcopy(dict(expected_cursor))
        return InMemoryIngestionTransaction(
            adapter=self,
            source_id=source_id,
            run_id=run_id,
            correlation_id=correlation_id,
            expected_cursor=dict(expected_cursor),
        )


class InMemoryIngestionTransaction:
    def __init__(
        self,
        *,
        adapter: InMemoryIngestionPersistence,
        source_id: str,
        run_id: str,
        correlation_id: str,
        expected_cursor: JsonObject,
    ) -> None:
        self.adapter = adapter
        self.source_id = source_id
        self.run_id = run_id
        self.correlation_id = correlation_id
        self.expected_cursor = copy.deepcopy(expected_cursor)
        self._items = copy.deepcopy(adapter.items)
        self._evidence = copy.deepcopy(adapter.evidence)
        self._cursor = copy.deepcopy(adapter.cursors[source_id])
        self._finished = False

    def _require_open(self) -> None:
        if self._finished:
            raise PersistenceError("persistence transaction is already closed")

    def stage_item(self, envelope: Mapping[str, Any]) -> StagedItem:
        self._require_open()
        payload = copy.deepcopy(dict(envelope))
        if payload["source_id"] != self.source_id:
            raise PersistenceError("source item does not belong to transaction source")
        if payload["correlation_id"] != self.correlation_id:
            raise PersistenceError("source item does not belong to transaction correlation")

        key = (self.source_id, payload["dedupe_key"])
        item_ref = f"source-item:{self.source_id}:{payload['dedupe_key']}"
        existing = self._items.get(key)
        if existing is not None:
            if existing != payload:
                raise PersistenceError("dedupe_key already exists with different normalized payload")
            evidence_refs = tuple(f"{item_ref}:evidence:{index}" for index, _ in enumerate(existing["evidence"]))
            return StagedItem(item_ref=item_ref, created=False, evidence_refs=evidence_refs)

        self._items[key] = payload
        evidence_rows = tuple(copy.deepcopy(payload["evidence"]))
        self._evidence[item_ref] = evidence_rows
        evidence_refs = tuple(f"{item_ref}:evidence:{index}" for index, _ in enumerate(evidence_rows))
        return StagedItem(item_ref=item_ref, created=True, evidence_refs=evidence_refs)

    def set_checkpoint(self, cursor: Mapping[str, Any], *, advanced: bool) -> None:
        self._require_open()
        next_cursor = copy.deepcopy(dict(cursor))
        if not advanced and next_cursor != self.expected_cursor:
            raise PersistenceError("non-advanced checkpoint must equal expected cursor")
        self._cursor = next_cursor

    def commit(self) -> None:
        self._require_open()
        self.adapter.items = self._items
        self.adapter.evidence = self._evidence
        self.adapter.cursors[self.source_id] = self._cursor
        self._finished = True

    def rollback(self) -> None:
        if self._finished:
            return
        self._finished = True
