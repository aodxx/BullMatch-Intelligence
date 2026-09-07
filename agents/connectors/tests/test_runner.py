from __future__ import annotations

import copy
import unittest

from agents.connectors.runner import ContractError, run_connector_poll

SOURCE_ID = "88888888-8888-4888-8888-888888888888"
CORRELATION_ID = "11111111-1111-4111-8111-111111111111"
RUN_ID = "33333333-3333-4333-8333-333333333333"


def source() -> dict:
    return {
        "schema_version": "1.0.0",
        "source_id": SOURCE_ID,
        "name": "Deterministic test source",
        "source_type": "OTHER",
        "base_url": "https://example.invalid/bullmatch-test",
        "connector_key": "fixture",
        "access_method": "PUBLIC_PAGE",
        "reliability_tier": "UNKNOWN",
        "policy_status": "APPROVED",
        "policy_notes": "Test-only contract fixture; never polled over network.",
        "status": "ACTIVE",
        "polling": {"enabled": True, "interval_minutes": 60, "timezone": "Asia/Bangkok", "active_windows": [], "max_items_per_run": 10},
        "rate_limit": {"min_request_interval_ms": 0, "max_requests_per_run": 1, "max_concurrency": 1, "cooldown_seconds": 0, "respect_retry_after": True},
        "connector_config": {},
        "secret_requirements": [],
        "tags": ["test-only"],
    }


def request() -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "run_id": RUN_ID,
        "source": source(),
        "cursor": {"strategy": "EXTERNAL_ID", "value": "before"},
        "window": {"from": None, "to": None},
        "limits": {"max_items": 10, "max_requests": 1, "deadline_at": None},
    }


def item(dedupe_key: str = "fixture:item-1") -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "source_id": SOURCE_ID,
        "external_id": "item-1",
        "canonical_url": "https://example.invalid/bullmatch-test/item-1",
        "dedupe_key": dedupe_key,
        "published_at": None,
        "retrieved_at": "2026-09-07T00:00:00Z",
        "title": "Test-only source item",
        "normalized_text": "Deterministic fixture, not a historical bullfighting fact.",
        "raw_metadata": {"fixture": True},
        "evidence": [{
            "evidence_type": "TEXT",
            "storage_ref": None,
            "source_ref": "https://example.invalid/bullmatch-test/item-1",
            "content_sha256": None,
            "text_excerpt": "Deterministic fixture",
            "timestamp_start_seconds": None,
            "timestamp_end_seconds": None,
            "access_class": "PUBLIC_REFERENCE",
            "metadata": {"fixture": True},
        }],
        "connector": {"name": "fixture", "version": "1.0.0"},
    }


def result(*, checkpoint_safe: bool = True) -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "run_id": RUN_ID,
        "source_id": SOURCE_ID,
        "items": [item()],
        "next_cursor": {"strategy": "EXTERNAL_ID", "value": "after", "checkpoint_safe": checkpoint_safe},
        "has_more": False,
        "health": {"status": "HEALTHY", "reason_codes": [], "operator_action": None},
        "rate_limit_state": {"requests_used": 1, "retry_after_seconds": None, "cooldown_until": None},
        "metrics": {"items": 1},
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


class ConnectorRunnerTests(unittest.TestCase):
    def test_valid_result_advances_safe_checkpoint(self):
        execution = run_connector_poll(FixtureConnector(result()), request())
        self.assertTrue(execution.checkpoint_advanced)
        self.assertEqual(execution.committed_cursor, {"strategy": "EXTERNAL_ID", "value": "after"})
        self.assertNotIn("checkpoint_safe", execution.committed_cursor)

    def test_unsafe_checkpoint_keeps_previous_cursor(self):
        execution = run_connector_poll(FixtureConnector(result(checkpoint_safe=False)), request())
        self.assertFalse(execution.checkpoint_advanced)
        self.assertEqual(execution.committed_cursor, request()["cursor"])

    def test_policy_must_be_approved(self):
        req = request(); req["source"]["policy_status"] = "REVIEW_REQUIRED"
        with self.assertRaisesRegex(ContractError, "APPROVED"):
            run_connector_poll(FixtureConnector(result()), req)

    def test_cross_source_output_is_rejected(self):
        payload = result(); payload["items"][0]["source_id"] = "99999999-9999-4999-8999-999999999999"
        with self.assertRaisesRegex(ContractError, "crossed source boundary"):
            run_connector_poll(FixtureConnector(payload), request())

    def test_duplicate_dedupe_key_is_rejected(self):
        payload = result(); payload["items"].append(item())
        with self.assertRaisesRegex(ContractError, "duplicate dedupe_key"):
            run_connector_poll(FixtureConnector(payload), request())

    def test_connector_identity_mismatch_is_rejected(self):
        payload = result(); payload["items"][0]["connector"]["name"] = "other"
        with self.assertRaisesRegex(ContractError, "connector identity"):
            run_connector_poll(FixtureConnector(payload), request())


if __name__ == "__main__":
    unittest.main()
