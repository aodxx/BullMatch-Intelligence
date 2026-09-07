"""Source-agnostic connector runtime for BullMatch Intelligence."""

from .orchestration import CollectionRunState, RunStateError
from .persistence import (
    InMemoryIngestionPersistence,
    IngestionPersistenceAdapter,
    IngestionTransaction,
    PersistenceError,
    PersistenceResult,
    StagedItem,
    persist_poll_execution,
)
from .postgres_adapter import PostgresCollectionRunStore, PostgresIngestionPersistence
from .registry import ApprovedSourceRegistry, InMemorySourceRegistryProvider, SourceRegistryError
from .runner import Connector, ContractError, PollExecution, run_connector_poll

__all__ = [
    "ApprovedSourceRegistry",
    "CollectionRunState",
    "Connector",
    "ContractError",
    "InMemoryIngestionPersistence",
    "InMemorySourceRegistryProvider",
    "IngestionPersistenceAdapter",
    "IngestionTransaction",
    "PersistenceError",
    "PersistenceResult",
    "PollExecution",
    "PostgresCollectionRunStore",
    "PostgresIngestionPersistence",
    "RunStateError",
    "SourceRegistryError",
    "StagedItem",
    "persist_poll_execution",
    "run_connector_poll",
]
