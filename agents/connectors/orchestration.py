"""Source-agnostic collection run state and poll-request construction.

The orchestration state is deliberately persistence-neutral. It produces the
existing AgentRun and ConnectorPollRequest contracts, but does not contact a
source, persist evidence, or write canonical BullMatch history.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping
from uuid import uuid4

from .runner import ContractError, JsonObject, PollExecution, _load_schemas, _validate


class RunStateError(ContractError):
    """Raised for invalid run transitions or source/run identity mismatches."""


@dataclass
class CollectionRunState:
    source_id: str
    agent_version: str
    started_at: str
    run_id: str = field(default_factory=lambda: str(uuid4()))
    correlation_id: str = field(default_factory=lambda: str(uuid4()))
    status: str = "RUNNING"
    completed_at: str | None = None
    input_refs: list[str] = field(default_factory=list)
    output_refs: list[str] = field(default_factory=list)
    metrics: JsonObject = field(default_factory=dict)
    errors: list[JsonObject] = field(default_factory=list)

    @classmethod
    def start(
        cls,
        source: Mapping[str, Any],
        *,
        agent_version: str,
        started_at: str,
        run_id: str | None = None,
        correlation_id: str | None = None,
    ) -> "CollectionRunState":
        if source.get("policy_status") != "APPROVED":
            raise RunStateError("collection run requires an APPROVED source")
        if source.get("status") != "ACTIVE" or not source.get("polling", {}).get("enabled"):
            raise RunStateError("collection run requires an ACTIVE source with polling enabled")

        state = cls(
            source_id=str(source["source_id"]),
            agent_version=agent_version,
            started_at=started_at,
            run_id=run_id or str(uuid4()),
            correlation_id=correlation_id or str(uuid4()),
            input_refs=[f"source:{source['source_id']}"],
            metrics={
                "polls_completed": 0,
                "items_emitted": 0,
                "requests_used": 0,
                "checkpoints_advanced": 0,
            },
        )
        state.as_contract()
        return state

    def _require_running(self) -> None:
        if self.status != "RUNNING":
            raise RunStateError(f"run is already terminal: {self.status}")

    def build_poll_request(
        self,
        source: Mapping[str, Any],
        *,
        cursor: Mapping[str, Any],
        window_from: str | None = None,
        window_to: str | None = None,
        deadline_at: str | None = None,
        max_items: int | None = None,
        max_requests: int | None = None,
    ) -> JsonObject:
        self._require_running()
        if source.get("source_id") != self.source_id:
            raise RunStateError("poll request source_id does not match run source")
        if source.get("policy_status") != "APPROVED":
            raise RunStateError("poll request source must remain APPROVED")
        if source.get("status") != "ACTIVE" or not source.get("polling", {}).get("enabled"):
            raise RunStateError("poll request source must remain ACTIVE with polling enabled")

        source_item_limit = int(source["polling"]["max_items_per_run"])
        source_request_limit = int(source["rate_limit"]["max_requests_per_run"])
        effective_items = source_item_limit if max_items is None else min(max_items, source_item_limit)
        effective_requests = source_request_limit if max_requests is None else min(max_requests, source_request_limit)
        if effective_items < 1 or effective_requests < 1:
            raise RunStateError("poll limits must remain positive after source-policy caps")

        request: JsonObject = {
            "schema_version": "1.0.0",
            "correlation_id": self.correlation_id,
            "run_id": self.run_id,
            "source": dict(source),
            "cursor": dict(cursor),
            "window": {"from": window_from, "to": window_to},
            "limits": {
                "max_items": effective_items,
                "max_requests": effective_requests,
                "deadline_at": deadline_at,
            },
        }
        schemas, registry = _load_schemas()
        _validate(request, "connector-poll-request.schema.json", schemas, registry)
        return request

    def record_execution(self, execution: PollExecution) -> None:
        self._require_running()
        result = execution.result
        if result["source_id"] != self.source_id:
            raise RunStateError("poll execution source_id does not match run source")
        if result["run_id"] != self.run_id or result["correlation_id"] != self.correlation_id:
            raise RunStateError("poll execution identity does not match run")

        self.metrics["polls_completed"] = int(self.metrics.get("polls_completed", 0)) + 1
        self.metrics["items_emitted"] = int(self.metrics.get("items_emitted", 0)) + len(result["items"])
        self.metrics["requests_used"] = int(self.metrics.get("requests_used", 0)) + int(
            result["rate_limit_state"]["requests_used"]
        )
        if execution.checkpoint_advanced:
            self.metrics["checkpoints_advanced"] = int(self.metrics.get("checkpoints_advanced", 0)) + 1
        self.metrics["last_health_status"] = result["health"]["status"]
        self.metrics["has_more"] = bool(result["has_more"])

        for item in result["items"]:
            ref = f"source-item:{item['source_id']}:{item['dedupe_key']}"
            if ref not in self.output_refs:
                self.output_refs.append(ref)
        self.errors.extend(dict(error) for error in result["errors"])

    def finish(self, *, completed_at: str) -> JsonObject:
        self._require_running()
        health = str(self.metrics.get("last_health_status", "HEALTHY"))
        if health in {"ERROR", "AUTH_REQUIRED", "POLICY_BLOCKED"}:
            self.status = "FAILED"
        elif self.errors or health in {"DEGRADED", "RATE_LIMITED", "PAUSED"}:
            self.status = "PARTIAL"
        else:
            self.status = "SUCCEEDED"
        self.completed_at = completed_at
        return self.as_contract()

    def fail(
        self,
        *,
        code: str,
        message: str,
        occurred_at: str,
        retryable: bool,
        details: Mapping[str, Any] | None = None,
    ) -> JsonObject:
        self._require_running()
        self.errors.append(
            {
                "code": code,
                "message": message,
                "stage": "SOURCE_MONITORING",
                "retryable": retryable,
                "source_id": self.source_id,
                "occurred_at": occurred_at,
                "details": dict(details or {}),
            }
        )
        self.status = "FAILED"
        self.completed_at = occurred_at
        return self.as_contract()

    def as_contract(self) -> JsonObject:
        payload: JsonObject = {
            "schema_version": "1.0.0",
            "run_id": self.run_id,
            "correlation_id": self.correlation_id,
            "agent_type": "SOURCE_MONITORING",
            "agent_version": self.agent_version,
            "source_id": self.source_id,
            "started_at": self.started_at,
            "completed_at": self.completed_at,
            "status": self.status,
            "input_refs": list(self.input_refs),
            "output_refs": list(self.output_refs),
            "metrics": dict(self.metrics),
            "errors": [dict(error) for error in self.errors],
        }
        schemas, registry = _load_schemas()
        _validate(payload, "agent-run.schema.json", schemas, registry)
        return payload
