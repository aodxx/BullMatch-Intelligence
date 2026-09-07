"""Approved source-registry loading for connector orchestration.

This module validates registry entries against the shared 1.0.0 contract and
exposes only sources that passed source-policy approval. It contains no source
credentials, network access, or Production persistence.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable, Mapping, Protocol

from .runner import ContractError, JsonObject, _load_schemas, _validate


class SourceRegistryError(ContractError):
    """Raised when runtime source-registry state is invalid or not pollable."""


class SourceRegistryProvider(Protocol):
    """Persistence-neutral provider for source-registry contract objects."""

    def list_sources(self) -> Iterable[Mapping[str, Any]]: ...


@dataclass(frozen=True)
class InMemorySourceRegistryProvider:
    """Deterministic provider used by tests and future adapter conformance."""

    entries: tuple[Mapping[str, Any], ...]

    def list_sources(self) -> Iterable[Mapping[str, Any]]:
        return self.entries


@dataclass(frozen=True)
class ApprovedSourceRegistry:
    """Validated runtime view containing APPROVED source entries only.

    REVIEW_REQUIRED and BLOCKED entries are intentionally absent from this
    runtime view so orchestration cannot accidentally poll them. ACTIVE/polling
    state is checked separately by :meth:`get_pollable` because an approved
    source may be temporarily paused without losing its policy approval.
    """

    _sources: Mapping[str, JsonObject]

    @classmethod
    def load(cls, provider: SourceRegistryProvider) -> "ApprovedSourceRegistry":
        schemas, registry = _load_schemas()
        approved: dict[str, JsonObject] = {}
        seen_ids: set[str] = set()

        for raw in provider.list_sources():
            entry = dict(raw)
            _validate(entry, "source-registry-entry.schema.json", schemas, registry)
            source_id = entry["source_id"]
            if source_id in seen_ids:
                raise SourceRegistryError(f"duplicate source_id in registry provider: {source_id}")
            seen_ids.add(source_id)

            if entry["policy_status"] == "APPROVED":
                approved[source_id] = entry

        return cls(_sources=approved)

    def source_ids(self) -> tuple[str, ...]:
        return tuple(sorted(self._sources))

    def get(self, source_id: str) -> JsonObject:
        try:
            return dict(self._sources[source_id])
        except KeyError as exc:
            raise SourceRegistryError("source is not present in approved runtime registry") from exc

    def get_pollable(self, source_id: str) -> JsonObject:
        source = self.get(source_id)
        if source["status"] != "ACTIVE":
            raise SourceRegistryError("approved source must be ACTIVE before orchestration")
        if not source["polling"]["enabled"]:
            raise SourceRegistryError("approved source must have polling enabled before orchestration")
        return source

    def pollable_for_connector(self, connector_key: str) -> tuple[JsonObject, ...]:
        matches: list[JsonObject] = []
        for source_id in self.source_ids():
            source = self._sources[source_id]
            if (
                source["connector_key"] == connector_key
                and source["status"] == "ACTIVE"
                and source["polling"]["enabled"]
            ):
                matches.append(dict(source))
        return tuple(matches)
