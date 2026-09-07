"""Reusable synthetic fixtures for source-agnostic connector conformance tests.

All URLs use the reserved .invalid TLD. Nothing in this module represents a
real bull, venue, match, source, or Production fact.
"""

from __future__ import annotations

import copy

SOURCE_ID = "88888888-8888-4888-8888-888888888888"
SECOND_SOURCE_ID = "77777777-7777-4777-8777-777777777777"
CORRELATION_ID = "11111111-1111-4111-8111-111111111111"
RUN_ID = "33333333-3333-4333-8333-333333333333"
STARTED_AT = "2026-09-07T01:00:00Z"
COMPLETED_AT = "2026-09-07T01:01:00Z"
INITIAL_CURSOR = {"strategy": "EXTERNAL_ID", "value": "before"}
NEXT_CURSOR = {"strategy": "EXTERNAL_ID", "value": "after", "checkpoint_safe": True}


def source_fixture(
    *,
    source_id: str = SOURCE_ID,
    policy_status: str = "APPROVED",
    status: str = "ACTIVE",
    polling_enabled: bool = True,
) -> dict:
    return {
        "schema_version": "1.0.0",
        "source_id": source_id,
        "name": "Synthetic connector conformance source",
        "source_type": "OTHER",
        "base_url": "https://example.invalid/bullmatch-connector-test",
        "connector_key": "fixture",
        "access_method": "PUBLIC_PAGE",
        "reliability_tier": "UNKNOWN",
        "policy_status": policy_status,
        "policy_notes": "Synthetic test-only contract fixture; no network access.",
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
        "tags": ["synthetic", "test-only"],
    }


def item_fixture(*, correlation_id: str = CORRELATION_ID, source_id: str = SOURCE_ID) -> dict:
    return {
        "schema_version": "1.0.0",
        "correlation_id": correlation_id,
        "source_id": source_id,
        "external_id": "synthetic-item-1",
        "canonical_url": "https://example.invalid/bullmatch-connector-test/item-1",
        "dedupe_key": "fixture:synthetic-item-1",
        "published_at": None,
        "retrieved_at": "2026-09-07T01:00:30Z",
        "title": "Synthetic test-only item",
        "normalized_text": "Synthetic conformance evidence; not a Thai bullfighting historical fact.",
        "raw_metadata": {"fixture": True},
        "evidence": [
            {
                "evidence_type": "TEXT",
                "storage_ref": None,
                "source_ref": "https://example.invalid/bullmatch-connector-test/item-1",
                "content_sha256": None,
                "text_excerpt": "Synthetic connector conformance fixture",
                "timestamp_start_seconds": None,
                "timestamp_end_seconds": None,
                "access_class": "PUBLIC_REFERENCE",
                "metadata": {"fixture": True},
            }
        ],
        "connector": {"name": "fixture", "version": "1.0.0"},
    }


def result_fixture(
    *,
    health: str = "HEALTHY",
    run_id: str = RUN_ID,
    correlation_id: str = CORRELATION_ID,
    source_id: str = SOURCE_ID,
    checkpoint_safe: bool = True,
) -> dict:
    next_cursor = copy.deepcopy(NEXT_CURSOR)
    next_cursor["checkpoint_safe"] = checkpoint_safe
    return {
        "schema_version": "1.0.0",
        "correlation_id": correlation_id,
        "run_id": run_id,
        "source_id": source_id,
        "items": [item_fixture(correlation_id=correlation_id, source_id=source_id)],
        "next_cursor": next_cursor,
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
