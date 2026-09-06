#!/usr/bin/env python3
"""Validate BullMatch Intelligence JSON Schemas and example payloads."""

from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_DIR = ROOT / "packages" / "contracts" / "schemas"
EXAMPLE_DIR = ROOT / "packages" / "contracts" / "examples"

EXAMPLE_SCHEMA_MAP = {
    "source-registry-entry.json": "source-registry-entry.schema.json",
    "normalized-ingestion-envelope.json": "normalized-ingestion-envelope.schema.json",
    "extraction-result.json": "extraction-result.schema.json",
    "verification-result.json": "verification-result.schema.json",
    "entity-resolution-policy.json": "entity-resolution-policy.schema.json",
    "review-command.json": "review-command.schema.json",
}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> None:
    schema_files = sorted(SCHEMA_DIR.glob("*.schema.json"))
    if not schema_files:
        raise SystemExit("No contract schemas found")

    schemas: dict[str, dict] = {}
    for path in schema_files:
        schema = load_json(path)
        Draft202012Validator.check_schema(schema)
        if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            raise SystemExit(f"{path.name}: unexpected $schema")
        if not schema.get("$id"):
            raise SystemExit(f"{path.name}: missing $id")
        schemas[path.name] = schema
        print(f"schema ok: {path.relative_to(ROOT)}")

    checker = FormatChecker()
    for example_name, schema_name in EXAMPLE_SCHEMA_MAP.items():
        example_path = EXAMPLE_DIR / example_name
        if not example_path.exists():
            raise SystemExit(f"Missing example: {example_name}")
        payload = load_json(example_path)
        validator = Draft202012Validator(schemas[schema_name], format_checker=checker)
        errors = sorted(validator.iter_errors(payload), key=lambda error: list(error.path))
        if errors:
            formatted = "\n".join(
                f"{example_name} at {list(error.path)}: {error.message}" for error in errors
            )
            raise SystemExit(formatted)
        print(f"example ok: {example_path.relative_to(ROOT)}")

    print(f"Validated {len(schema_files)} schemas and {len(EXAMPLE_SCHEMA_MAP)} examples")


if __name__ == "__main__":
    main()
