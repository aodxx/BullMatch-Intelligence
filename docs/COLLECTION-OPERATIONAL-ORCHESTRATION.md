# Collection Operational Orchestration

Task: `BMI-P2-001`  
Status: **SYNTHETIC OPERATIONAL SLICE**

## Purpose

Compose the source-agnostic BullMatch collection contracts into one deterministic operational run without selecting or contacting a real external source.

Flow:

`ApprovedSourceRegistry -> persisted checkpoint -> CollectionRunState -> Connector -> contract validation -> atomic SourceItem + Evidence + checkpoint persistence -> terminal SOURCE_MONITORING run`

The orchestration remains upstream of extraction, atomic claims, entity resolution, review, verification and controlled promotion.

## Runtime API

`agents/connectors/operational.py` exposes `run_collection_once()`.

Dependencies are injected through narrow protocols:

- `CheckpointReader` — reads the last persisted connector checkpoint for one source
- `CollectionRunStore` — persists RUNNING and terminal `CollectionRunState`
- `IngestionPersistenceAdapter` — atomically stages normalized source items/evidence plus safe checkpoint
- `Connector` — source-specific poll implementation governed by the shared connector contracts

The wrapper does not own credentials, scheduling, source discovery, network configuration or canonical BullMatch tables.

## Run sequence

1. Resolve the source from `ApprovedSourceRegistry.get_pollable()`.
2. Read persisted checkpoint state.
3. If no checkpoint exists, use the caller-supplied source/connector initial cursor. BullMatch orchestration does not invent source-specific cursor semantics.
4. Create and persist a RUNNING `SOURCE_MONITORING` AgentRun.
5. Build a schema-valid poll request capped by approved source policy.
6. Run `run_connector_poll()` so result/source/run/correlation/connector/dedupe/checkpoint invariants are enforced.
7. Persist normalized source items, PENDING evidence and safe checkpoint through one atomic ingestion transaction.
8. Record persistence counts and connector metrics on the run.
9. Persist the terminal run state.

If any step after run creation fails, the wrapper records a FAILED run when possible and re-raises the original error. Persisted failure details include only the exception type; arbitrary source response bodies, credentials or exception text are not copied into AgentRun details.

## Trust and canonical-data boundary

This orchestration can create only collection-layer artifacts through the supplied adapter. It cannot:

- create or overwrite canonical Bulls
- create or overwrite canonical Matches/results/history
- verify evidence
- promote atomic claims
- publish history
- resolve uncertain bull identities automatically

Normalized connector output remains untrusted source material. Evidence produced by the PostgreSQL adapter remains `PENDING`.

## Synthetic conformance fixtures

`agents/connectors/tests/fixtures.py` provides reusable source/item/result/connector fixtures for connector conformance.

Rules:

- fixed synthetic UUIDs only
- `.invalid` URLs only
- explicit test-only metadata
- no names or facts representing real bulls, venues, camps, owners or matches
- no network access

`test_operational.py` verifies:

- end-to-end approved registry -> poll -> atomic persistence -> terminal run
- persisted checkpoint wins over the initial cursor
- unsafe connector checkpoint does not advance stored cursor
- invalid cross-source output stages no evidence/checkpoint and leaves a FAILED operational run

## Production enablement boundary

This slice does **not** authorize a Production source. Before a real source connector can run, a separate source/compliance decision must define at minimum:

- source identity and owner/operator
- permitted access method/API or public-page basis
- terms/robots/API policy compatibility where applicable
- rate limits and active polling windows
- evidence/storage/retention rights
- authentication/secret handling if required
- source-specific initial cursor semantics
- source-specific conformance and failure tests

Until that decision exists, orchestration must remain synthetic or explicitly test-only.

## Next safe foundation step

After this slice passes CI, determine whether `BMI-P2-001` needs a database-backed `SourceRegistryProvider`/`CheckpointReader` composition helper for final foundation sign-off. If the existing PostgreSQL source/runtime tables can satisfy that need without a migration, implement it read-only and add deterministic adapter tests. Do not select or poll a real source merely to complete the foundation task.
