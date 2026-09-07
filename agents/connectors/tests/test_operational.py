from __future__ import annotations

import copy
import unittest

from agents.connectors.operational import run_collection_once
from agents.connectors.persistence import InMemoryIngestionPersistence
from agents.connectors.registry import ApprovedSourceRegistry, InMemorySourceRegistryProvider
from agents.connectors.tests.fixtures import (
    COMPLETED_AT,
    CORRELATION_ID,
    INITIAL_CURSOR,
    RUN_ID,
    SOURCE_ID,
    STARTED_AT,
    FixtureConnector,
    result_fixture,
    source_fixture,
)


class InMemoryRunStore:
    def __init__(self) -> None:
        self.snapshots: list[dict] = []

    def save(self, state) -> None:
        self.snapshots.append(copy.deepcopy(state.as_contract()))


class PersistenceCheckpointReader:
    def __init__(self, persistence: InMemoryIngestionPersistence) -> None:
        self.persistence = persistence

    def read_checkpoint(self, source_id: str) -> dict | None:
        cursor = self.persistence.cursors.get(source_id)
        return copy.deepcopy(cursor) if cursor is not None else None


class OperationalOrchestrationTests(unittest.TestCase):
    def _registry(self) -> ApprovedSourceRegistry:
        return ApprovedSourceRegistry.load(InMemorySourceRegistryProvider(entries=(source_fixture(),)))

    def _run(self, *, payload: dict, persistence: InMemoryIngestionPersistence | None = None):
        store = persistence or InMemoryIngestionPersistence()
        runs = InMemoryRunStore()
        outcome = run_collection_once(
            registry=self._registry(),
            source_id=SOURCE_ID,
            connector=FixtureConnector(payload),
            checkpoint_reader=PersistenceCheckpointReader(store),
            persistence=store,
            run_store=runs,
            agent_version="collection-operational-test/1.0.0",
            started_at=STARTED_AT,
            completed_at=COMPLETED_AT,
            initial_cursor=INITIAL_CURSOR,
            run_id=RUN_ID,
            correlation_id=CORRELATION_ID,
        )
        return outcome, store, runs

    def test_end_to_end_poll_persists_evidence_checkpoint_and_terminal_run(self):
        outcome, persistence, runs = self._run(payload=result_fixture())

        self.assertEqual(outcome.run["status"], "SUCCEEDED")
        self.assertEqual(outcome.run["metrics"]["items_persisted_created"], 1)
        self.assertEqual(outcome.run["metrics"]["evidence_refs_persisted"], 1)
        self.assertEqual(persistence.cursors[SOURCE_ID], {"strategy": "EXTERNAL_ID", "value": "after"})
        self.assertEqual(len(persistence.items), 1)
        self.assertEqual(len(persistence.evidence), 1)
        self.assertEqual([snapshot["status"] for snapshot in runs.snapshots], ["RUNNING", "SUCCEEDED"])

    def test_persisted_checkpoint_is_used_instead_of_initial_cursor(self):
        persistence = InMemoryIngestionPersistence()
        persistence.cursors[SOURCE_ID] = {"strategy": "EXTERNAL_ID", "value": "persisted-before"}
        outcome, _, _ = self._run(payload=result_fixture(), persistence=persistence)
        self.assertEqual(outcome.poll_request["cursor"]["value"], "persisted-before")

    def test_unsafe_connector_checkpoint_does_not_advance_persisted_cursor(self):
        outcome, persistence, _ = self._run(payload=result_fixture(checkpoint_safe=False))
        self.assertFalse(outcome.persistence.checkpoint_advanced)
        self.assertEqual(persistence.cursors[SOURCE_ID], INITIAL_CURSOR)
        self.assertEqual(outcome.run["status"], "SUCCEEDED")

    def test_invalid_connector_output_records_failed_run_without_staging_data(self):
        malformed = result_fixture()
        malformed["source_id"] = "77777777-7777-4777-8777-777777777777"
        persistence = InMemoryIngestionPersistence()
        runs = InMemoryRunStore()

        with self.assertRaises(Exception):
            run_collection_once(
                registry=self._registry(),
                source_id=SOURCE_ID,
                connector=FixtureConnector(malformed),
                checkpoint_reader=PersistenceCheckpointReader(persistence),
                persistence=persistence,
                run_store=runs,
                agent_version="collection-operational-test/1.0.0",
                started_at=STARTED_AT,
                completed_at=COMPLETED_AT,
                initial_cursor=INITIAL_CURSOR,
                run_id=RUN_ID,
                correlation_id=CORRELATION_ID,
            )

        self.assertEqual(len(persistence.items), 0)
        self.assertEqual(len(persistence.evidence), 0)
        self.assertNotIn(SOURCE_ID, persistence.cursors)
        self.assertEqual(runs.snapshots[-1]["status"], "FAILED")
        self.assertEqual(runs.snapshots[-1]["errors"][0]["code"], "COLLECTION_RUN_FAILED")
        self.assertNotIn("malformed", str(runs.snapshots[-1]["errors"][0]))


if __name__ == "__main__":
    unittest.main()
