from __future__ import annotations

import json
import unittest
from pathlib import Path

from agents.connectors.runner import _load_schemas, _validate

ROOT = Path(__file__).resolve().parents[3]
DOSSIER_DIR = ROOT / "docs" / "source-evaluations"


class CandidateSourceDossierTests(unittest.TestCase):
    def test_all_candidate_dossiers_validate_and_remain_non_approved(self):
        schemas, registry = _load_schemas()
        files = sorted(DOSSIER_DIR.glob("*.json"))
        self.assertGreaterEqual(len(files), 3)

        for path in files:
            payload = json.loads(path.read_text(encoding="utf-8"))
            _validate(payload, "source-compliance-evaluation.schema.json", schemas, registry)
            self.assertEqual(payload["decision"]["status"], "REVIEW_REQUIRED", path.name)
            self.assertFalse(payload["runtime_policy_proposal"]["polling_enabled"], path.name)
            self.assertEqual(payload["decision"]["authority"], "UNASSIGNED", path.name)
            self.assertTrue(payload["decision"]["blocking_reasons"], path.name)


if __name__ == "__main__":
    unittest.main()
