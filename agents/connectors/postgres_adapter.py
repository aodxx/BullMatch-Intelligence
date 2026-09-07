"""PostgreSQL mapping for BullMatch source-agnostic collection contracts.

This module targets the already-deployed ``bullmatch_private`` ingestion,
runtime-state and AgentRun tables. A server-side/direct PostgreSQL connection
is supplied by the runtime; credentials are intentionally outside this module.

The adapter exposes no SQL for canonical Bulls, Matches, verification,
promotion or publication.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime
from typing import Any, Callable, Mapping, Protocol, Sequence

from .orchestration import CollectionRunState
from .persistence import IngestionPersistenceAdapter, PersistenceError, StagedItem
from .runner import JsonObject


class DbCursor(Protocol):
    def execute(self, query: str, params: Sequence[Any] | None = None) -> Any: ...
    def fetchone(self) -> Sequence[Any] | None: ...
    def fetchall(self) -> list[Sequence[Any]]: ...
    def close(self) -> None: ...


class DbConnection(Protocol):
    def cursor(self) -> DbCursor: ...
    def commit(self) -> None: ...
    def rollback(self) -> None: ...
    def close(self) -> None: ...


ConnectionFactory = Callable[[], DbConnection]

_NORMALIZED_FINGERPRINT_KEY = "normalized_envelope_fingerprint"
_RUN_REFS_KEY = "_bullmatch_run_refs"


def normalized_envelope_fingerprint(envelope: Mapping[str, Any]) -> str:
    """Stable SHA-256 fingerprint of the complete normalized envelope."""

    encoded = json.dumps(
        dict(envelope),
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _iso(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def _storage_raw_metadata(envelope: Mapping[str, Any], fingerprint: str) -> JsonObject:
    """Add a private idempotency fingerprint without overloading content_hash.

    ``source_items.content_hash`` remains available for a future source-content
    hash. The normalized-envelope fingerprint is implementation metadata only.
    """

    metadata = dict(envelope.get("raw_metadata") or {})
    internal = dict(metadata.get("_bullmatch") or {})
    internal[_NORMALIZED_FINGERPRINT_KEY] = fingerprint
    metadata["_bullmatch"] = internal
    return metadata


def _evidence_metadata(evidence: Mapping[str, Any]) -> JsonObject:
    metadata = dict(evidence.get("metadata") or {})
    source_ref = evidence.get("source_ref")
    if source_ref is not None:
        internal = dict(metadata.get("_bullmatch") or {})
        internal["source_ref"] = source_ref
        metadata["_bullmatch"] = internal
    return metadata


class PostgresCollectionRunStore:
    """Persist/restore ``CollectionRunState`` through ``agent_runs``.

    Contract-only fields that do not have dedicated database columns are kept
    inside ``metrics._bullmatch_run_refs``. This is additive and requires no
    migration. The store never mutates source items, evidence or canonical data.
    """

    def __init__(self, connection_factory: ConnectionFactory) -> None:
        self.connection_factory = connection_factory

    def save(self, state: CollectionRunState) -> None:
        payload = state.as_contract()
        metrics = dict(payload["metrics"])
        metrics[_RUN_REFS_KEY] = {
            "input_refs": list(payload["input_refs"]),
            "output_refs": list(payload["output_refs"]),
        }
        items_scanned = int(metrics.get("items_emitted", 0))
        items_created = int(metrics.get("items_persisted_created", 0))

        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                """
                insert into bullmatch_private.agent_runs(
                  id, agent_type, agent_version, source_id, correlation_id,
                  started_at, completed_at, status, items_scanned, items_created,
                  review_cases_created, error_count, metrics, errors
                ) values (
                  %s, 'SOURCE_MONITORING', %s, %s, %s,
                  %s, %s, %s, %s, %s,
                  0, %s, %s::jsonb, %s::jsonb
                )
                on conflict (id) do update set
                  agent_version = excluded.agent_version,
                  source_id = excluded.source_id,
                  correlation_id = excluded.correlation_id,
                  completed_at = excluded.completed_at,
                  status = excluded.status,
                  items_scanned = excluded.items_scanned,
                  items_created = excluded.items_created,
                  review_cases_created = excluded.review_cases_created,
                  error_count = excluded.error_count,
                  metrics = excluded.metrics,
                  errors = excluded.errors
                """,
                (
                    payload["run_id"],
                    payload["agent_version"],
                    payload["source_id"],
                    payload["correlation_id"],
                    payload["started_at"],
                    payload["completed_at"],
                    payload["status"],
                    items_scanned,
                    items_created,
                    len(payload["errors"]),
                    _json(metrics),
                    _json(payload["errors"]),
                ),
            )
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()
            connection.close()

    def load(self, run_id: str) -> CollectionRunState | None:
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                """
                select id, agent_type, agent_version, source_id, correlation_id,
                       started_at, completed_at, status, metrics, errors
                from bullmatch_private.agent_runs
                where id = %s
                """,
                (run_id,),
            )
            row = cursor.fetchone()
            if row is None:
                return None
            if row[1] != "SOURCE_MONITORING":
                raise PersistenceError("agent run is not a SOURCE_MONITORING run")
            if row[3] is None or row[4] is None:
                raise PersistenceError("SOURCE_MONITORING run is missing source/correlation identity")

            metrics = dict(row[8] or {})
            refs = dict(metrics.pop(_RUN_REFS_KEY, {}) or {})
            state = CollectionRunState(
                source_id=str(row[3]),
                agent_version=str(row[2]),
                started_at=_iso(row[5]) or "",
                run_id=str(row[0]),
                correlation_id=str(row[4]),
                status=str(row[7]),
                completed_at=_iso(row[6]),
                input_refs=list(refs.get("input_refs") or [f"source:{row[3]}"]),
                output_refs=list(refs.get("output_refs") or []),
                metrics=metrics,
                errors=[dict(error) for error in (row[9] or [])],
            )
            state.as_contract()
            return state
        finally:
            cursor.close()
            connection.close()


class PostgresIngestionPersistence(IngestionPersistenceAdapter):
    """DB-API-style adapter for ``bullmatch_private`` source ingestion tables."""

    def __init__(self, connection_factory: ConnectionFactory) -> None:
        self.connection_factory = connection_factory

    def begin(
        self,
        *,
        source_id: str,
        run_id: str,
        correlation_id: str,
        expected_cursor: Mapping[str, Any],
    ) -> "PostgresIngestionTransaction":
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            # Serialize source persistence. If runtime state does not exist yet,
            # this source-row lock also prevents competing first-poll inserts.
            cursor.execute(
                """
                select policy_status, status, polling_enabled
                from bullmatch_private.sources
                where id = %s
                for update
                """,
                (source_id,),
            )
            source_row = cursor.fetchone()
            if source_row is None:
                raise PersistenceError("source does not exist in BullMatch source registry")
            if tuple(source_row) != ("APPROVED", "ACTIVE", True):
                raise PersistenceError("source must remain APPROVED, ACTIVE and polling-enabled at persistence time")

            cursor.execute(
                """
                select cursor_strategy, cursor
                from bullmatch_private.source_runtime_state
                where source_id = %s
                for update
                """,
                (source_id,),
            )
            runtime_row = cursor.fetchone()
            stored_cursor = (
                {"strategy": runtime_row[0], "value": runtime_row[1]}
                if runtime_row is not None
                else dict(expected_cursor)
            )
            if stored_cursor != dict(expected_cursor):
                raise PersistenceError("stored checkpoint does not match expected cursor")

            return PostgresIngestionTransaction(
                connection=connection,
                cursor=cursor,
                source_id=source_id,
                run_id=run_id,
                correlation_id=correlation_id,
                expected_cursor=dict(expected_cursor),
            )
        except Exception:
            connection.rollback()
            cursor.close()
            connection.close()
            raise


class PostgresIngestionTransaction:
    def __init__(
        self,
        *,
        connection: DbConnection,
        cursor: DbCursor,
        source_id: str,
        run_id: str,
        correlation_id: str,
        expected_cursor: JsonObject,
    ) -> None:
        self.connection = connection
        self.cursor = cursor
        self.source_id = source_id
        self.run_id = run_id
        self.correlation_id = correlation_id
        self.expected_cursor = dict(expected_cursor)
        self._finished = False

    def _require_open(self) -> None:
        if self._finished:
            raise PersistenceError("PostgreSQL ingestion transaction is already closed")

    def stage_item(self, envelope: Mapping[str, Any]) -> StagedItem:
        self._require_open()
        payload = dict(envelope)
        if payload["source_id"] != self.source_id:
            raise PersistenceError("source item does not belong to PostgreSQL transaction source")
        if payload["correlation_id"] != self.correlation_id:
            raise PersistenceError("source item does not belong to PostgreSQL transaction correlation")

        fingerprint = normalized_envelope_fingerprint(payload)
        dedupe_key = payload["dedupe_key"]
        self.cursor.execute(
            """
            select id, raw_metadata #>> '{_bullmatch,normalized_envelope_fingerprint}'
            from bullmatch_private.source_items
            where source_id = %s and dedupe_key = %s
            for update
            """,
            (self.source_id, dedupe_key),
        )
        existing = self.cursor.fetchone()
        if existing is not None:
            item_id, stored_fingerprint = existing[0], existing[1]
            if stored_fingerprint is None:
                raise PersistenceError("existing source item lacks normalized-envelope fingerprint")
            if stored_fingerprint != fingerprint:
                raise PersistenceError("dedupe_key already exists with different normalized payload")
            self.cursor.execute(
                """
                select id
                from bullmatch_private.evidence
                where source_item_id = %s
                order by created_at, id
                """,
                (item_id,),
            )
            evidence_refs = tuple(f"evidence:{row[0]}" for row in self.cursor.fetchall())
            return StagedItem(item_ref=f"source-item:{item_id}", created=False, evidence_refs=evidence_refs)

        connector = payload["connector"]
        self.cursor.execute(
            """
            insert into bullmatch_private.source_items(
              source_id, external_id, canonical_url, dedupe_key, published_at,
              retrieved_at, content_hash, title, normalized_text, raw_metadata,
              connector_name, connector_version, ingestion_status
            ) values (
              %s, %s, %s, %s, %s,
              %s, %s, %s, %s, %s::jsonb,
              %s, %s, 'DISCOVERED'
            )
            returning id
            """,
            (
                self.source_id,
                payload.get("external_id"),
                payload.get("canonical_url"),
                dedupe_key,
                payload.get("published_at"),
                payload["retrieved_at"],
                None,
                payload.get("title"),
                payload.get("normalized_text"),
                _json(_storage_raw_metadata(payload, fingerprint)),
                connector["name"],
                connector["version"],
            ),
        )
        inserted = self.cursor.fetchone()
        if inserted is None:
            raise PersistenceError("source item insert returned no id")
        item_id = inserted[0]

        evidence_refs: list[str] = []
        for evidence in payload["evidence"]:
            self.cursor.execute(
                """
                insert into bullmatch_private.evidence(
                  source_item_id, evidence_type, storage_ref, content_sha256,
                  text_excerpt, timestamp_start_seconds, timestamp_end_seconds,
                  metadata, access_class, moderation_status
                ) values (
                  %s, %s, %s, %s,
                  %s, %s, %s,
                  %s::jsonb, %s, 'PENDING'
                )
                returning id
                """,
                (
                    item_id,
                    evidence["evidence_type"],
                    evidence.get("storage_ref"),
                    evidence.get("content_sha256"),
                    evidence.get("text_excerpt"),
                    evidence.get("timestamp_start_seconds"),
                    evidence.get("timestamp_end_seconds"),
                    _json(_evidence_metadata(evidence)),
                    evidence.get("access_class") or "INTERNAL",
                ),
            )
            row = self.cursor.fetchone()
            if row is None:
                raise PersistenceError("evidence insert returned no id")
            evidence_refs.append(f"evidence:{row[0]}")

        return StagedItem(
            item_ref=f"source-item:{item_id}",
            created=True,
            evidence_refs=tuple(evidence_refs),
        )

    def set_checkpoint(self, cursor: Mapping[str, Any], *, advanced: bool) -> None:
        self._require_open()
        next_cursor = dict(cursor)
        if not advanced and next_cursor != self.expected_cursor:
            raise PersistenceError("non-advanced PostgreSQL checkpoint must equal expected cursor")
        self.cursor.execute(
            """
            insert into bullmatch_private.source_runtime_state(
              source_id, cursor_strategy, cursor, last_attempt_at, updated_at
            ) values (%s, %s, %s::jsonb, now(), now())
            on conflict (source_id) do update set
              cursor_strategy = excluded.cursor_strategy,
              cursor = excluded.cursor,
              last_attempt_at = excluded.last_attempt_at,
              updated_at = excluded.updated_at
            """,
            (self.source_id, next_cursor["strategy"], _json(next_cursor.get("value"))),
        )

    def commit(self) -> None:
        self._require_open()
        self.connection.commit()
        self._finished = True
        self.cursor.close()
        self.connection.close()

    def rollback(self) -> None:
        if self._finished:
            return
        self.connection.rollback()
        self._finished = True
        self.cursor.close()
        self.connection.close()
