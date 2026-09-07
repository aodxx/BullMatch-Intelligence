"""Read-only PostgreSQL runtime readers for collection orchestration.

These readers never mutate source registry/runtime state and expose no canonical
BullMatch tables. They exist only to satisfy persistence-neutral orchestration
protocols against the already-deployed private ingestion schema.
"""

from __future__ import annotations

from .postgres_adapter import ConnectionFactory
from .runner import JsonObject


class PostgresCheckpointReader:
    """Read the current connector checkpoint from source_runtime_state."""

    def __init__(self, connection_factory: ConnectionFactory) -> None:
        self.connection_factory = connection_factory

    def read_checkpoint(self, source_id: str) -> JsonObject | None:
        connection = self.connection_factory()
        cursor = connection.cursor()
        try:
            cursor.execute(
                """
                select cursor_strategy, cursor
                from bullmatch_private.source_runtime_state
                where source_id = %s
                """,
                (source_id,),
            )
            row = cursor.fetchone()
            if row is None:
                return None
            return {"strategy": str(row[0]), "value": row[1]}
        finally:
            cursor.close()
            connection.close()
