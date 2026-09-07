"""Read-only PostgreSQL provider for approved source-registry contracts."""

from __future__ import annotations

import json
from typing import Any, Iterable, Mapping

from .postgres_adapter import ConnectionFactory
from .runner import JsonObject


def _decoded(value: Any, fallback: Any) -> Any:
    if value is None:
        return fallback
    if isinstance(value, str):
        return json.loads(value)
    return value


class PostgresSourceRegistryProvider:
    """Load policy-APPROVED private source rows as shared registry entries.

    The provider is read-only and intentionally does not invent missing policy
    values. Rows with incomplete/invalid policy data are returned with those
    missing values and then fail shared schema validation in
    ``ApprovedSourceRegistry.load`` before they can be polled.
    """

    def __init__(self, connection_factory: ConnectionFactory) -> None:
        self.connection_factory = connection_factory

    def list_sources(self) -> Iterable[Mapping[str, Any]]:
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                """
                select id, name, source_type, base_url, connector_key,
                       access_method, reliability_tier, policy_status, policy_notes,
                       status, polling_enabled, poll_interval_minutes,
                       polling_timezone, polling_active_windows, max_items_per_run,
                       rate_limit, connector_config, secret_requirements, tags
                from bullmatch_private.sources
                where policy_status = 'APPROVED'
                order by id
                """
            )
            entries: list[JsonObject] = []
            for row in cursor.fetchall():
                entries.append(
                    {
                        "schema_version": "1.0.0",
                        "source_id": str(row[0]),
                        "name": row[1],
                        "source_type": row[2],
                        "base_url": row[3],
                        "connector_key": row[4],
                        "access_method": row[5],
                        "reliability_tier": row[6],
                        "policy_status": row[7],
                        "policy_notes": row[8],
                        "status": row[9],
                        "polling": {
                            "enabled": bool(row[10]),
                            "interval_minutes": row[11],
                            "timezone": row[12],
                            "active_windows": _decoded(row[13], None),
                            "max_items_per_run": row[14],
                        },
                        "rate_limit": _decoded(row[15], None),
                        "connector_config": _decoded(row[16], {}),
                        "secret_requirements": _decoded(row[17], []),
                        "tags": list(row[18] or []),
                    }
                )
            return tuple(entries)
        finally:
            cursor.close()
            connection.close()
