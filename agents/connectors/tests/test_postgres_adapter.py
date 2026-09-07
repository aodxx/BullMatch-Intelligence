from __future__ import annotations

import json
import unittest
from collections import deque
from typing import Any

from agents.connectors.orchestration import CollectionRunState
from agents.connectors.persistence import PersistenceError, persist_poll_execution
from agents.connectors.postgres_adapter import (
    PostgresCollectionRunStore,
    PostgresIngestionPersistence,
    normalized_envelope_fingerprint,
)
from agents.connectors.runner import PollExecution


SOURCE_ID = "11111111-1111-4111-8111-111111111111"
RUN_ID = "22222222-2222-4222-8222-222222222222"
CORRELATION_ID = "33333333-3333-4333-8333-333333333333"


class FakeCursor:
    def __init__(self, *, one: list[Any] | None = None, all_rows: list[Any] | None = None) -> None:
        self.one = deque(one or [])
        self.all_rows = deque(all_rows or [])
        self.executions: list[tuple[str, tuple[Any, ...] | None]] = []
        self.closed = False

    def execute(self, query: str, params=None):
        self.executions.append((" ".join(query.split()), tuple(params) if params is not None else None))

    def fetchone(self):
        return self.one.popleft() if self.one else None

    def fetchall(self):
        return self.all_rows.popleft() if self.all_rows else []

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self, cursor: FakeCursor) -> None:
        self._cursor = cursor
        self.commits = 0
        self.rollbacks = 0
        self.closed = False

    def cursor(self):
        return self._cursor

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def close(self):
        self.closed = True


def envelope(*, text: str = "source text") -> dict[str, Any]:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "source_id": SOURCE_ID,
        "external_id": "external-1",
        "canonical_url": "https://example.invalid/item/1",
        "dedupe_key": "item-1",
        "published_at": None,
        "retrieved_at": "2026-09-07T01:00:00Z",
        "title": "Fixture",
        "normalized_text": text,
        "raw_metadata": {"source_field": "kept"},
        "evidence": [
            {
                "evidence_type": "TEXT",
                "storage_ref": None,
                "source_ref": "https://example.invalid/item/1#text",
                "content_sha256": None,
                "text_excerpt": "fixture excerpt",
                "timestamp_start_seconds": None,
                "timestamp_end_seconds": None,
                "access_class": "INTERNAL",
                "metadata": {"fixture": True},
            }
        ],
        "connector": {"name": "fixture-connector", "version": "1.0.0"},
    }


class PostgresIngestionAdapterTests(unittest.TestCase):
    def test_new_item_uses_private_fingerprint_not_content_hash_and_commits_checkpoint(self):
        cursor = FakeCursor(
            one=[
                ("APPROVED", "ACTIVE", True),
                None,
                None,
                ("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",),
                ("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",),
            ]
        )
        connection = FakeConnection(cursor)
        adapter = PostgresIngestionPersistence(lambda: connection)
        expected = {"strategy": "NONE", "value": None}
        tx = adapter.begin(
            source_id=SOURCE_ID,
            run_id=RUN_ID,
            correlation_id=CORRELATION_ID,
            expected_cursor=expected,
        )
        payload = envelope()
        staged = tx.stage_item(payload)
        tx.set_checkpoint({"strategy": "TIMESTAMP", "value": "2026-09-07T01:00:00Z"}, advanced=True)
        tx.commit()

        self.assertTrue(staged.created)
        self.assertEqual(connection.commits, 1)
        self.assertEqual(connection.rollbacks, 0)
        self.assertTrue(connection.closed)

        item_insert = next(entry for entry in cursor.executions if "insert into bullmatch_private.source_items" in entry[0])
        params = item_insert[1]
        assert params is not None
        self.assertIsNone(params[6], "content_hash is reserved for actual source-content hashing")
        stored_metadata = json.loads(params[9])
        self.assertEqual(stored_metadata["source_field"], "kept")
        self.assertEqual(
            stored_metadata["_bullmatch"]["normalized_envelope_fingerprint"],
            normalized_envelope_fingerprint(payload),
        )
        self.assertTrue(any("insert into bullmatch_private.source_runtime_state" in sql for sql, _ in cursor.executions))

    def test_conflicting_replay_rolls_back_entire_poll(self):
        cursor = FakeCursor(
            one=[
                ("APPROVED", "ACTIVE", True),
                ("NONE", None),
                ("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", "different-fingerprint"),
            ]
        )
        connection = FakeConnection(cursor)
        adapter = PostgresIngestionPersistence(lambda: connection)
        execution = PollExecution(
            result={
                "source_id": SOURCE_ID,
                "run_id": RUN_ID,
                "correlation_id": CORRELATION_ID,
                "items": [envelope(text="changed")],
            },
            committed_cursor={"strategy": "TIMESTAMP", "value": "2026-09-07T01:00:00Z"},
            checkpoint_advanced=True,
        )

        with self.assertRaises(PersistenceError):
            persist_poll_execution(adapter, execution, expected_cursor={"strategy": "NONE", "value": None})

        self.assertEqual(connection.commits, 0)
        self.assertEqual(connection.rollbacks, 1)
        self.assertFalse(any("source_runtime_state(" in sql for sql, _ in cursor.executions))

    def test_stale_checkpoint_is_rejected_before_item_staging(self):
        cursor = FakeCursor(one=[("APPROVED", "ACTIVE", True), ("TIMESTAMP", "newer")])
        connection = FakeConnection(cursor)
        adapter = PostgresIngestionPersistence(lambda: connection)

        with self.assertRaises(PersistenceError):
            adapter.begin(
                source_id=SOURCE_ID,
                run_id=RUN_ID,
                correlation_id=CORRELATION_ID,
                expected_cursor={"strategy": "NONE", "value": None},
            )

        self.assertEqual(connection.rollbacks, 1)
        self.assertEqual(connection.commits, 0)
        self.assertEqual(len(cursor.executions), 2)

    def test_persistence_rechecks_source_policy(self):
        cursor = FakeCursor(one=[("APPROVED", "PAUSED", True)])
        connection = FakeConnection(cursor)
        adapter = PostgresIngestionPersistence(lambda: connection)

        with self.assertRaises(PersistenceError):
            adapter.begin(
                source_id=SOURCE_ID,
                run_id=RUN_ID,
                correlation_id=CORRELATION_ID,
                expected_cursor={"strategy": "NONE", "value": None},
            )

        self.assertEqual(connection.rollbacks, 1)
        self.assertEqual(len(cursor.executions), 1)


class PostgresRunStoreTests(unittest.TestCase):
    def test_collection_run_state_round_trips_through_agent_runs_mapping(self):
        save_cursor = FakeCursor()
        save_connection = FakeConnection(save_cursor)
        state = CollectionRunState(
            source_id=SOURCE_ID,
            agent_version="collection-foundation/1.0.0",
            started_at="2026-09-07T01:00:00Z",
            run_id=RUN_ID,
            correlation_id=CORRELATION_ID,
            input_refs=[f"source:{SOURCE_ID}"],
            output_refs=[f"source-item:{SOURCE_ID}:item-1"],
            metrics={"polls_completed": 1, "items_emitted": 1, "requests_used": 1, "checkpoints_advanced": 1},
        )
        PostgresCollectionRunStore(lambda: save_connection).save(state)

        self.assertEqual(save_connection.commits, 1)
        self.assertEqual(save_connection.rollbacks, 0)
        sql, params = save_cursor.executions[0]
        self.assertIn("insert into bullmatch_private.agent_runs", sql)
        assert params is not None
        stored_metrics = json.loads(params[-2])
        self.assertEqual(stored_metrics["_bullmatch_run_refs"]["output_refs"], state.output_refs)

        load_cursor = FakeCursor(
            one=[
                (
                    RUN_ID,
                    "SOURCE_MONITORING",
                    state.agent_version,
                    SOURCE_ID,
                    CORRELATION_ID,
                    state.started_at,
                    None,
                    "RUNNING",
                    stored_metrics,
                    [],
                )
            ]
        )
        load_connection = FakeConnection(load_cursor)
        loaded = PostgresCollectionRunStore(lambda: load_connection).load(RUN_ID)
        assert loaded is not None
        self.assertEqual(loaded.run_id, state.run_id)
        self.assertEqual(loaded.output_refs, state.output_refs)
        self.assertEqual(loaded.metrics["items_emitted"], 1)
        self.assertNotIn("_bullmatch_run_refs", loaded.metrics)
        self.assertEqual(load_connection.commits, 0)
        self.assertEqual(load_connection.rollbacks, 0)

    def test_non_source_monitoring_agent_run_is_rejected(self):
        cursor = FakeCursor(
            one=[
                (
                    RUN_ID,
                    "EXTRACTION",
                    "1.0.0",
                    SOURCE_ID,
                    CORRELATION_ID,
                    "2026-09-07T01:00:00Z",
                    None,
                    "RUNNING",
                    {},
                    [],
                )
            ]
        )
        connection = FakeConnection(cursor)
        with self.assertRaises(PersistenceError):
            PostgresCollectionRunStore(lambda: connection).load(RUN_ID)
        self.assertTrue(connection.closed)


if __name__ == "__main__":
    unittest.main()
