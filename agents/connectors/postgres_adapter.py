"""PostgreSQL mapping for the source-agnostic ingestion persistence contract.

This adapter targets the already-deployed BullMatch-private ingestion tables.
It expects a server-side/direct PostgreSQL connection supplied by the runtime;
connection credentials are intentionally outside this module. The adapter has
no canonical Bull/Match/history write SQL.
"""

from __future__ import annotations

import hashlib
import json
from typing import Any, Callable, Mapping, Protocol, Sequence

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


def _evidence_metadata(evidence: Mapping[str, Any]) -> JsonObject:
    metadata = dict(evidence.get("metadata") or {})
    source_ref = evidence.get("source_ref")
    if source_ref is not None:
        internal = dict(metadata.get("_bullmatch") or {})
        internal["source_ref"] = source_ref
        metadata["_bullmatch"] = internal
    return metadata


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
            cursor.execute(
                """
                select policy_status, status, polling_enabled
                from bullmatch_private.sources
                where id = %s
                for share
                """,
                (source_id,),
            )
            source_row = cursor.fetchone()
            if source_row is None:
                raise PersistenceError("source does not exist in BullMatch source registry")
            if tuple(source_row) != ("APPROVED", "ACTIVE", True):
                raise PersistenceError("source must remain APPROVED, ACTIVE and polling-enabled at persistence time")

            strategy = str(expected_cursor["strategy"])
            value = expected_cursor.get("value")
            cursor.execute(
                """
                insert into bullmatch_private.source_runtime_state(source_id, cursor_strategy, cursor)
                values (%s, %s, %s::jsonb)
                on conflict (source_id) do nothing
                """,
                (source_id, strategy, _json(value)),
            )
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
            if runtime_row is None:
                raise PersistenceError("source runtime state could not be initialized")
            stored_cursor = {"strategy": runtime_row[0], "value": runtime_row[1]}
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
            select id, content_hash
            from bullmatch_private.source_items
            where source_id = %s and dedupe_key = %s
            for update
            """,
            (self.source_id, dedupe_key),
        )
        existing = self.cursor.fetchone()
        if existing is not None:
            item_id, stored_fingerprint = existing[0], existing[1]
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
                fingerprint,
                payload.get("title"),
                payload.get("normalized_text"),
                _json(payload.get("raw_metadata") or {}),
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
            update bullmatch_private.source_runtime_state
            set cursor_strategy = %s,
                cursor = %s::jsonb,
                last_attempt_at = now(),
                updated_at = now()
            where source_id = %s
            """,
            (next_cursor["strategy"], _json(next_cursor.get("value")), self.source_id),
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
