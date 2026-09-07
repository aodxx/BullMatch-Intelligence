from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from agents.connectors.runner import ContractError, _load_schemas, _validate

ROOT = Path(__file__).resolve().parents[3]
EXAMPLE = ROOT / "packages" / "contracts" / "examples" / "source-compliance-evaluation.json"


class SourceComplianceContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.schemas, self.registry = _load_schemas()
        self.payload = json.loads(EXAMPLE.read_text(encoding="utf-8"))

    def validate(self, payload: dict) -> None:
        _validate(payload, "source-compliance-evaluation.schema.json", self.schemas, self.registry)

    def test_review_required_synthetic_example_is_valid(self):
        self.validate(self.payload)
        self.assertEqual(self.payload["decision"]["status"], "REVIEW_REQUIRED")
        self.assertFalse(self.payload["runtime_policy_proposal"]["polling_enabled"])

    def test_approved_requires_owner_or_compliance_authority(self):
        payload = copy.deepcopy(self.payload)
        payload["decision"].update(
            {
                "status": "APPROVED",
                "decided_at": "2026-09-07T03:10:00Z",
                "decided_by": "reviewer-reference",
                "authority": "UNASSIGNED",
                "decision_basis_refs": ["https://example.invalid/decision-basis"],
                "blocking_reasons": [],
            }
        )
        with self.assertRaises(ContractError):
            self.validate(payload)

    def test_approved_requires_decision_basis_reference(self):
        payload = copy.deepcopy(self.payload)
        payload["decision"].update(
            {
                "status": "APPROVED",
                "decided_at": "2026-09-07T03:10:00Z",
                "decided_by": "reviewer-reference",
                "authority": "OWNER_OR_COMPLIANCE",
                "decision_basis_refs": [],
                "blocking_reasons": [],
            }
        )
        with self.assertRaises(ContractError):
            self.validate(payload)

    def test_blocked_requires_reason(self):
        payload = copy.deepcopy(self.payload)
        payload["decision"].update(
            {
                "status": "BLOCKED",
                "decided_at": "2026-09-07T03:10:00Z",
                "decided_by": "reviewer-reference",
                "authority": "OWNER_OR_COMPLIANCE",
                "blocking_reasons": [],
            }
        )
        with self.assertRaises(ContractError):
            self.validate(payload)


if __name__ == "__main__":
    unittest.main()
