"""Source-agnostic connector runtime for BullMatch Intelligence."""

from .operational import (
    CheckpointReader,
    CollectionRunStore,
    OperationalRunResult,
    run_collection_once,
)
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
from .postgres_readers import PostgresCheckpointReader
from .postgres_registry import PostgresSourceRegistryProvider
from .registry import ApprovedSourceRegistry, InMemorySourceRegistryProvider, SourceRegistryError
from .runner import Connector, ContractError, PollExecution, run_connector_poll

__all__ = [
    "ApprovedSourceRegistry",
    "CheckpointReader",
    "CollectionRunState",
    "CollectionRunStore",
    "Connector",
    "ContractError",
    "InMemoryIngestionPersistence",
    "InMemorySourceRegistryProvider",
    "IngestionPersistenceAdapter",
    "IngestionTransaction",
    "OperationalRunResult",
    "PersistenceError",
    "PersistenceResult",
    "PollExecution",
    "PostgresCheckpointReader",
    "PostgresCollectionRunStore",
    "PostgresIngestionPersistence",
    "PostgresSourceRegistryProvider",
    "RunStateError",
    "SourceRegistryError",
    "StagedItem",
    "persist_poll_execution",
    "run_collection_once",
    "run_connector_poll",
]
