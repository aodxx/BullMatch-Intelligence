from __future__ import annotations

import copy
import unittest

from agents.connectors.orchestration import CollectionRunState, RunStateError
from agents.connectors.registry import (
    ApprovedSourceRegistry,
    InMemorySourceRegistryProvider,
    SourceRegistryError,
)
from agents.connectors.runner import run_connector_poll

SOURCE_ID = "88888888-8888-4888-8888-888888888888"
SECOND_SOURCE_ID = "77777777-7777-4777-8777-777777777777"
CORRELATION_ID = "11111111-1111-4111-8111-111111111111"
RUN_ID = "33333333-3333-4333-8333-333333333333"
STARTED_AT = "2026-09-07T01:00:00Z"
COMPLETED_AT = "2026-09-07T01:01:00Z"


def source(*, source_id: str = SOURCE_ID, policy_status: str = "APPROVED", status: str = "ACTIVE", polling_enabled: bool = True) -> dict:
    return {
        "schema_version": "1.0.0",
        "source_id": source_id,
        "name": "Deterministic registry fixture",
        "source_type": "OTHER",
        "base_url": "https://example.invalid/bullmatch-registry-test",
        "connector_key": "fixture",
        "access_method": "PUBLIC_PAGE",
        "reliability_tier": "UNKNOWN",
        "policy_status": policy_status,
        "policy_notes": "Test-only contract fixture; no network access.",
        "status": status,
        "polling": {
            "enabled": polling_enabled,
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


def item() -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "source_id": SOURCE_ID,
        "external_id": "item-1",
        "canonical_url": "https://example.invalid/bullmatch-registry-test/item-1",
        "dedupe_key": "fixture:item-1",
        "published_at": None,
        "retrieved_at": "2026-09-07T01:00:30Z",
        "title": "Test-only item",
        "normalized_text": "Synthetic contract fixture, not a BullMatch historical fact.",
        "raw_metadata": {"fixture": True},
        "evidence": [
            {
                "evidence_type": "TEXT",
                "storage_ref": None,
                "source_ref": "https://example.invalid/bullmatch-registry-test/item-1",
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


def result(*, health: str = "HEALTHY") -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": CORRELATION_ID,
        "run_id": RUN_ID,
        "source_id": SOURCE_ID,
        "items": [item()],
        "next_cursor": {"strategy": "EXTERNAL_ID", "value": "after", "checkpoint_safe": True},
        "has_more": False,
        "health": {"status": health, "reason_codes": [], "operator_action": None},
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


class ApprovedSourceRegistryTests(unittest.TestCase):
    def test_loader_exposes_only_policy_approved_entries(self):
        registry = ApprovedSourceRegistry.load(
            InMemorySourceRegistryProvider(
                entries=(source(), source(source_id=SECOND_SOURCE_ID, policy_status="REVIEW_REQUIRED"))
            )
        )
        self.assertEqual(registry.source_ids(), (SOURCE_ID,))
        with self.assertRaisesRegex(SourceRegistryError, "approved runtime registry"):
            registry.get(SECOND_SOURCE_ID)

    def test_duplicate_source_id_is_rejected_even_if_policy_differs(self):
        with self.assertRaisesRegex(SourceRegistryError, "duplicate source_id"):
            ApprovedSourceRegistry.load(
                InMemorySourceRegistryProvider(entries=(source(), source(policy_status="BLOCKED")))
            )

    def test_approved_but_paused_source_is_not_pollable(self):
        registry = ApprovedSourceRegistry.load(
            InMemorySourceRegistryProvider(entries=(source(status="PAUSED"),))
        )
        self.assertEqual(registry.source_ids(), (SOURCE_ID,))
        with self.assertRaisesRegex(SourceRegistryError, "ACTIVE"):
            registry.get_pollable(SOURCE_ID)


class CollectionRunStateTests(unittest.TestCase):
    def _state_and_source(self) -> tuple[CollectionRunState, dict]:
        registry = ApprovedSourceRegistry.load(InMemorySourceRegistryProvider(entries=(source(),)))
        approved_source = registry.get_pollable(SOURCE_ID)
        state = CollectionRunState.start(
            approved_source,
            agent_version="collection-foundation-test/1.0.0",
            started_at=STARTED_AT,
            run_id=RUN_ID,
            correlation_id=CORRELATION_ID,
        )
        return state, approved_source

    def test_start_emits_valid_running_agent_run(self):
        state, _ = self._state_and_source()
        contract = state.as_contract()
        self.assertEqual(contract["agent_type"], "SOURCE_MONITORING")
        self.assertEqual(contract["status"], "RUNNING")
        self.assertEqual(contract["source_id"], SOURCE_ID)

    def test_poll_request_is_capped_by_source_policy(self):
        state, approved_source = self._state_and_source()
        request = state.build_poll_request(
            approved_source,
            cursor={"strategy": "EXTERNAL_ID", "value": "before"},
            max_items=999,
            max_requests=999,
        )
        self.assertEqual(request["limits"]["max_items"], 10)
        self.assertEqual(request["limits"]["max_requests"], 2)
        self.assertEqual(request["run_id"], RUN_ID)
        self.assertEqual(request["correlation_id"], CORRELATION_ID)

    def test_execution_updates_run_metrics_and_finishes_successfully(self):
        state, approved_source = self._state_and_source()
        request = state.build_poll_request(
            approved_source,
            cursor={"strategy": "EXTERNAL_ID", "value": "before"},
        )
        execution = run_connector_poll(FixtureConnector(result()), request)
        state.record_execution(execution)
        contract = state.finish(completed_at=COMPLETED_AT)

        self.assertEqual(contract["status"], "SUCCEEDED")
        self.assertEqual(contract["metrics"]["items_emitted"], 1)
        self.assertEqual(contract["metrics"]["requests_used"], 1)
        self.assertEqual(contract["metrics"]["checkpoints_advanced"], 1)
        self.assertEqual(contract["output_refs"], [f"source-item:{SOURCE_ID}:fixture:item-1"])

    def test_error_health_finishes_failed_without_canonical_side_effects(self):
        state, approved_source = self._state_and_source()
        request = state.build_poll_request(
            approved_source,
            cursor={"strategy": "EXTERNAL_ID", "value": "before"},
        )
        execution = run_connector_poll(FixtureConnector(result(health="ERROR")), request)
        state.record_execution(execution)
        contract = state.finish(completed_at=COMPLETED_AT)
        self.assertEqual(contract["status"], "FAILED")

    def test_fail_records_contract_valid_source_monitoring_error(self):
        state, _ = self._state_and_source()
        contract = state.fail(
            code="FIXTURE_FAILURE",
            message="Synthetic failure for deterministic orchestration test",
            occurred_at=COMPLETED_AT,
            retryable=True,
            details={"fixture": True},
        )
        self.assertEqual(contract["status"], "FAILED")
        self.assertEqual(contract["errors"][0]["stage"], "SOURCE_MONITORING")

    def test_run_rejects_cross_source_request(self):
        state, _ = self._state_and_source()
        other = source(source_id=SECOND_SOURCE_ID)
        with self.assertRaisesRegex(RunStateError, "source_id"):
            state.build_poll_request(
                other,
                cursor={"strategy": "EXTERNAL_ID", "value": "before"},
            )


if __name__ == "__main__":
    unittest.main()
