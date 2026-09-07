"""Source-agnostic connector runner.

The runner enforces contract validation and checkpoint safety. It performs no
network access and has no persistence/canonical-write capability itself.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Protocol

from jsonschema import Draft202012Validator, FormatChecker
from referencing import Registry, Resource

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_DIR = ROOT / "packages" / "contracts" / "schemas"

JsonObject = dict[str, Any]


class ContractError(ValueError):
    """Raised when connector input/output violates BullMatch contracts or invariants."""


class Connector(Protocol):
    """Every source-specific connector implements this minimal interface."""

    key: str
    name: str
    version: str

    def poll(self, request: Mapping[str, Any]) -> Mapping[str, Any]: ...


@dataclass(frozen=True)
class PollExecution:
    result: JsonObject
    committed_cursor: JsonObject
    checkpoint_advanced: bool


def _load_schemas() -> tuple[dict[str, JsonObject], Registry]:
    schemas: dict[str, JsonObject] = {}
    registry = Registry()
    for path in sorted(SCHEMA_DIR.glob("*.schema.json")):
        schema = json.loads(path.read_text(encoding="utf-8"))
        Draft202012Validator.check_schema(schema)
        schema_id = schema.get("$id")
        if not schema_id:
            raise ContractError(f"{path.name}: missing $id")
        schemas[path.name] = schema
        registry = registry.with_resource(schema_id, Resource.from_contents(schema))
    return schemas, registry


def _validate(payload: Mapping[str, Any], schema_name: str, schemas: dict[str, JsonObject], registry: Registry) -> None:
    validator = Draft202012Validator(
        schemas[schema_name],
        registry=registry,
        format_checker=FormatChecker(),
    )
    errors = sorted(validator.iter_errors(dict(payload)), key=lambda error: list(error.path))
    if errors:
        detail = "; ".join(f"{list(error.path)}: {error.message}" for error in errors[:5])
        raise ContractError(f"{schema_name} validation failed: {detail}")


def run_connector_poll(connector: Connector, request: Mapping[str, Any]) -> PollExecution:
    """Execute one connector poll and return a cursor only after full validation.

    A caller may persist ``committed_cursor`` only after this function succeeds.
    Invalid output, cross-source output, duplicate item keys, or unsafe checkpoints
    never advance the cursor.
    """

    schemas, registry = _load_schemas()
    request_obj = dict(request)
    _validate(request_obj, "connector-poll-request.schema.json", schemas, registry)

    source = request_obj["source"]
    if source["policy_status"] != "APPROVED":
        raise ContractError("source policy_status must be APPROVED before polling")
    if source["status"] != "ACTIVE" or not source["polling"]["enabled"]:
        raise ContractError("source must be ACTIVE with polling enabled")
    if source["connector_key"] != connector.key:
        raise ContractError("source connector_key does not match connector implementation")

    raw_result = connector.poll(request_obj)
    result = dict(raw_result)
    _validate(result, "connector-poll-result.schema.json", schemas, registry)

    if result["source_id"] != source["source_id"]:
        raise ContractError("connector result source_id does not match request source")
    if result["run_id"] != request_obj["run_id"] or result["correlation_id"] != request_obj["correlation_id"]:
        raise ContractError("connector result run/correlation identity does not match request")

    seen: set[str] = set()
    for item in result["items"]:
        if item["source_id"] != source["source_id"]:
            raise ContractError("ingestion item crossed source boundary")
        if item["correlation_id"] != request_obj["correlation_id"]:
            raise ContractError("ingestion item correlation_id does not match poll")
        if item["connector"]["name"] != connector.name or item["connector"]["version"] != connector.version:
            raise ContractError("ingestion item connector identity does not match implementation")
        dedupe_key = item["dedupe_key"]
        if dedupe_key in seen:
            raise ContractError(f"duplicate dedupe_key in one poll result: {dedupe_key}")
        seen.add(dedupe_key)

    next_cursor = dict(result["next_cursor"])
    checkpoint_safe = bool(next_cursor["checkpoint_safe"])
    committed_cursor = next_cursor if checkpoint_safe else dict(request_obj["cursor"])
    return PollExecution(result=result, committed_cursor=committed_cursor, checkpoint_advanced=checkpoint_safe)
