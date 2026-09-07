from __future__ import annotations

import copy
import unittest

from agents.connectors.persistence import (
    InMemoryIngestionPersistence,
    PersistenceError,
    persist_poll_execution,
)
from agents.connectors.runner import run_connector_poll

SOURCE_ID = "88888888-8888-4888-8888-888888888888"
CORRELATION_ID = "11111111-1111-4111-8111-111111111111"
RUN_ID = "33333333-3333-4333-8333-333333333333"


def source() -> dict:
    return {
        "schema_version": "1.0.0",
        "source_id": SOURCE_ID,
        "name": "Deterministic persistence fixture",
        "source_type": "OTHER",
        "base_url": "https://example.invalid/bullmatch-persistence-test",
        "connector_key": "fixture",
        "access_method": "PUBLIC_PAGE",
        "reliability_tier": "UNKNOWN",
        "policy_status": "APPROVED",
        "policy_notes": "Test-only contract fixture; no network access.",
        "status": "ACTIVE",
        "polling": {
            "enabled": True,
            "interval_minutes": 60,
            "timezone": "Asia/Bangkok",
            "active_windows": [],
            "max_items_per_run": 10,
        },
        "rate_limit": {
            "min_request_interval_ms": 0,
            "max_requests_per_run": 2,
            "max_concurrency": 1,
            "cooldown_seconds": 0,
            "respect_retry_after": True,
        },
        "connector_config": {},
        "secret_requirements": [],
        "tags": ["test-only"],
    }


def request(*, cursor_value: str = "before") -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "run_id": RUN_ID,
        "source": source(),
        "cursor": {"strategy": "EXTERNAL_ID", "value": cursor_value},
        "window": {"from": None, "to": None},
        "limits": {"max_items": 10, "max_requests": 2, "deadline_at": None},
    }


def item(dedupe_key: str, *, text: str | None = None) -> dict:
    suffix = dedupe_key.split(":")[-1]
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "source_id": SOURCE_ID,
        "external_id": suffix,
        "canonical_url": f"https://example.invalid/bullmatch-persistence-test/{suffix}",
        "dedupe_key": dedupe_key,
        "published_at": None,
        "retrieved_at": "2026-09-07T01:00:30Z",
        "title": "Test-only item",
        "normalized_text": text or "Synthetic contract fixture, not a BullMatch historical fact.",
        "raw_metadata": {"fixture": True},
        "evidence": [
            {
                "evidence_type": "TEXT",
                "storage_ref": None,
                "source_ref": f"https://example.invalid/bullmatch-persistence-test/{suffix}",
                "content_sha256": None,
                "text_excerpt": "Synthetic fixture",
                "timestamp_start_seconds": None,
                "timestamp_end_seconds": None,
                "access_class": "PUBLIC_REFERENCE",
                "metadata": {"fixture": True},
            }
        ],
        "connector": {"name": "fixture", "version": "1.0.0"},
    }


def result(items: list[dict], *, checkpoint_safe: bool = True, cursor_value: str = "after") -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "run_id": RUN_ID,
        "source_id": SOURCE_ID,
        "items": items,
        "next_cursor": {
            "strategy": "EXTERNAL_ID",
            "value": cursor_value,
            "checkpoint_safe": checkpoint_safe,
        },
        "has_more": False,
        "health": {"status": "HEALTHY", "reason_codes": [], "operator_action": None},
        "rate_limit_state": {"requests_used": 1, "retry_after_seconds": None, "cooldown_until": None},
        "metrics": {"items": len(items)},
        "errors": [],
    }


class FixtureConnector:
    key = "fixture"
    name = "fixture"
    version = "1.0.0"

    def __init__(self, payload: dict):
        self.payload = payload

    def poll(self, _request: dict) -> dict:
        return copy.deepcopy(self.payload)


def execution(payload: dict, *, cursor_value: str = "before"):
    return run_connector_poll(FixtureConnector(payload), request(cursor_value=cursor_value))


class PersistenceContractTests(unittest.TestCase):
    def test_success_commits_item_evidence_and_safe_checkpoint_together(self):
        adapter = InMemoryIngestionPersistence()
        before = {"strategy": "EXTERNAL_ID", "value": "before"}
        poll = execution(result([item("fixture:item-1")]))

        persisted = persist_poll_execution(adapter, poll, expected_cursor=before)

        self.assertTrue(persisted.staged_items[0].created)
        self.assertEqual(adapter.cursors[SOURCE_ID]["value"], "after")
        self.assertIn((SOURCE_ID, "fixture:item-1"), adapter.items)
        self.assertEqual(len(adapter.evidence[persisted.staged_items[0].item_ref]), 1)

    def test_unsafe_checkpoint_commits_evidence_but_keeps_previous_cursor(self):
        adapter = InMemoryIngestionPersistence()
        before = {"strategy": "EXTERNAL_ID", "value": "before"}
        poll = execution(result([item("fixture:item-1")], checkpoint_safe=False))

        persisted = persist_poll_execution(adapter, poll, expected_cursor=before)

        self.assertFalse(persisted.checkpoint_advanced)
        self.assertEqual(adapter.cursors[SOURCE_ID], before)
        self.assertIn((SOURCE_ID, "fixture:item-1"), adapter.items)

    def test_exact_replay_is_idempotent_and_does_not_duplicate_evidence(self):
        adapter = InMemoryIngestionPersistence()
        before = {"strategy": "EXTERNAL_ID", "value": "before"}
        first = execution(result([item("fixture:item-1")]))
        persist_poll_execution(adapter, first, expected_cursor=before)

        replay = execution(result([item("fixture:item-1")]), cursor_value="after")
        persisted = persist_poll_execution(
            adapter,
            replay,
            expected_cursor={"strategy": "EXTERNAL_ID", "value": "after"},
        )

        self.assertFalse(persisted.staged_items[0].created)
        self.assertEqual(len(adapter.items), 1)
        self.assertEqual(len(adapter.evidence[persisted.staged_items[0].item_ref]), 1)

    def test_conflicting_payload_for_existing_dedupe_key_rolls_back_whole_batch(self):
        adapter = InMemoryIngestionPersistence()
        before = {"strategy": "EXTERNAL_ID", "value": "before"}
        conflict_key = (SOURCE_ID, "fixture:conflict")
        existing = item("fixture:conflict", text="Existing normalized payload")
        adapter.items[conflict_key] = copy.deepcopy(existing)
        adapter.evidence[f"source-item:{SOURCE_ID}:fixture:conflict"] = tuple(copy.deepcopy(existing["evidence"]))
        adapter.cursors[SOURCE_ID] = copy.deepcopy(before)

        poll = execution(
            result(
                [
                    item("fixture:new-item"),
                    item("fixture:conflict", text="Different normalized payload"),
                ]
            )
        )

        with self.assertRaisesRegex(PersistenceError, "different normalized payload"):
            persist_poll_execution(adapter, poll, expected_cursor=before)

        self.assertNotIn((SOURCE_ID, "fixture:new-item"), adapter.items)
        self.assertEqual(adapter.items[conflict_key], existing)
        self.assertEqual(adapter.cursors[SOURCE_ID], before)

    def test_failed_first_transaction_leaves_adapter_completely_untouched(self):
        adapter = InMemoryIngestionPersistence()
        before = {"strategy": "EXTERNAL_ID", "value": "before"}
        poll = execution(result([item("fixture:item-1")]))

        class FailingTransaction:
            source_id = SOURCE_ID
            run_id = RUN_ID
            correlation_id = CORRELATION_ID

            def stage_item(self, _envelope):
                raise PersistenceError("synthetic stage failure")

            def set_checkpoint(self, _cursor, *, advanced: bool):
                raise AssertionError(f"checkpoint must not be reached: {advanced}")

            def commit(self):
                raise AssertionError("commit must not be reached")

            def rollback(self):
                return None

        class FailingAdapter:
            def begin(self, **_kwargs):
                return FailingTransaction()

        with self.assertRaisesRegex(PersistenceError, "synthetic stage failure"):
            persist_poll_execution(FailingAdapter(), poll, expected_cursor=before)

        self.assertEqual(adapter.items, {})
        self.assertEqual(adapter.evidence, {})
        self.assertEqual(adapter.cursors, {})

    def test_stale_expected_checkpoint_is_rejected_before_staging(self):
        adapter = InMemoryIngestionPersistence()
        adapter.cursors[SOURCE_ID] = {"strategy": "EXTERNAL_ID", "value": "current"}
        poll = execution(result([item("fixture:item-1")]))

        with self.assertRaisesRegex(PersistenceError, "does not match expected cursor"):
            persist_poll_execution(
                adapter,
                poll,
                expected_cursor={"strategy": "EXTERNAL_ID", "value": "stale"},
            )

        self.assertEqual(adapter.items, {})
        self.assertEqual(adapter.evidence, {})
        self.assertEqual(adapter.cursors[SOURCE_ID]["value"], "current")


if __name__ == "__main__":
    unittest.main()
