from __future__ import annotations

import unittest

from agents.connectors.postgres_registry import PostgresSourceRegistryProvider
from agents.connectors.registry import ApprovedSourceRegistry
from agents.connectors.tests.fixtures import SOURCE_ID
from agents.connectors.runner import ContractError


class FakeCursor:
    def __init__(self, rows):
        self.rows = rows
        self.executed = []
        self.closed = False

    def execute(self, query, params=None):
        self.executed.append((query, params))

    def fetchall(self):
        return self.rows

    def fetchone(self):
        return None

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self, rows):
        self.fake_cursor = FakeCursor(rows)
        self.closed = False

    def cursor(self):
        return self.fake_cursor

    def commit(self):
        raise AssertionError("read-only provider must not commit")

    def rollback(self):
        raise AssertionError("read-only provider must not rollback")

    def close(self):
        self.closed = True


def complete_row():
    return (
        SOURCE_ID,
        "Synthetic approved source",
        "OTHER",
        "https://example.invalid/source",
        "fixture",
        "PUBLIC_PAGE",
        "UNKNOWN",
        "APPROVED",
        "Synthetic test-only policy row",
        "ACTIVE",
        True,
        60,
        "Asia/Bangkok",
        [{"start": "08:00", "end": "20:00"}],
        10,
        {
            "min_request_interval_ms": 1000,
            "max_requests_per_run": 2,
            "max_concurrency": 1,
            "cooldown_seconds": 60,
            "respect_retry_after": True,
        },
        {},
        [],
        ["synthetic", "test-only"],
    )


class PostgresSourceRegistryProviderTests(unittest.TestCase):
    def test_complete_approved_row_reconstructs_valid_shared_contract(self):
        connection = FakeConnection([complete_row()])
        provider = PostgresSourceRegistryProvider(lambda: connection)
        registry = ApprovedSourceRegistry.load(provider)

        self.assertEqual(registry.source_ids(), (SOURCE_ID,))
        source = registry.get_pollable(SOURCE_ID)
        self.assertEqual(source["polling"]["timezone"], "Asia/Bangkok")
        self.assertEqual(source["rate_limit"]["max_requests_per_run"], 2)
        self.assertTrue(connection.fake_cursor.closed)
        self.assertTrue(connection.closed)
        self.assertIn("policy_status = 'APPROVED'", connection.fake_cursor.executed[0][0])

    def test_incomplete_approved_policy_fails_closed_in_shared_validation(self):
        row = list(complete_row())
        row[14] = None
        connection = FakeConnection([tuple(row)])
        provider = PostgresSourceRegistryProvider(lambda: connection)

        with self.assertRaises(ContractError):
            ApprovedSourceRegistry.load(provider)

    def test_provider_does_not_invent_missing_rate_limit(self):
        row = list(complete_row())
        row[15] = None
        provider = PostgresSourceRegistryProvider(lambda: FakeConnection([tuple(row)]))
        raw = tuple(provider.list_sources())[0]
        self.assertIsNone(raw["rate_limit"])


if __name__ == "__main__":
    unittest.main()
