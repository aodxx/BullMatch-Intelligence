from __future__ import annotations

import unittest

from agents.connectors.postgres_readers import PostgresCheckpointReader
from agents.connectors.tests.fixtures import SOURCE_ID


class FakeCursor:
    def __init__(self, row):
        self.row = row
        self.executed: list[tuple[str, tuple]] = []
        self.closed = False

    def execute(self, query, params=None):
        self.executed.append((query, tuple(params or ())))

    def fetchone(self):
        return self.row

    def fetchall(self):
        return []

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self, row):
        self.fake_cursor = FakeCursor(row)
        self.closed = False
        self.commits = 0
        self.rollbacks = 0

    def cursor(self):
        return self.fake_cursor

    def commit(self):
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def close(self):
        self.closed = True


class PostgresCheckpointReaderTests(unittest.TestCase):
    def test_reads_strategy_and_json_cursor_without_writes(self):
        connection = FakeConnection(("EXTERNAL_ID", "after-item-9"))
        reader = PostgresCheckpointReader(lambda: connection)

        checkpoint = reader.read_checkpoint(SOURCE_ID)

        self.assertEqual(checkpoint, {"strategy": "EXTERNAL_ID", "value": "after-item-9"})
        self.assertEqual(connection.commits, 0)
        self.assertEqual(connection.rollbacks, 0)
        self.assertTrue(connection.fake_cursor.closed)
        self.assertTrue(connection.closed)
        query, params = connection.fake_cursor.executed[0]
        self.assertIn("source_runtime_state", query)
        self.assertEqual(params, (SOURCE_ID,))

    def test_missing_runtime_state_returns_none(self):
        connection = FakeConnection(None)
        reader = PostgresCheckpointReader(lambda: connection)
        self.assertIsNone(reader.read_checkpoint(SOURCE_ID))
        self.assertEqual(connection.commits, 0)
        self.assertEqual(connection.rollbacks, 0)

    def test_json_cursor_value_is_preserved(self):
        value = {"page": 3, "token": "synthetic"}
        connection = FakeConnection(("CUSTOM", value))
        reader = PostgresCheckpointReader(lambda: connection)
        self.assertEqual(reader.read_checkpoint(SOURCE_ID), {"strategy": "CUSTOM", "value": value})


if __name__ == "__main__":
    unittest.main()
