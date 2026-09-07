# Source-Agnostic Collection Pipeline Foundation

Task: `BMI-P2-001`
Status: **IMPLEMENTATION BASELINE — REGISTRY + RUN STATE + ATOMIC PERSISTENCE + POSTGRES ADAPTER**
Contract family: `bullmatch.contracts/1.x`

## Purpose

Turn the Phase 0 connector contracts into an executable, testable and persistence-ready boundary before any real Production source is selected.

This task does **not** authorize scraping or polling any real source. It establishes the rules every later permitted connector must obey.

## Existing contracts reused

The implementation reuses the existing JSON Schema 1.0.0 contracts under `packages/contracts/schemas/`:

- `source-registry-entry.schema.json`
- `connector-poll-request.schema.json`
- `connector-poll-result.schema.json`
- `normalized-ingestion-envelope.schema.json`
- `agent-run.schema.json`
- `agent-error.schema.json`

No competing source contract or parallel datastore is introduced.

## Runtime boundary

`agents/connectors/runner.py` exposes the source-agnostic `Connector` protocol and `run_connector_poll()`.

A connector implementation supplies only:

- `key`
- `name`
- `version`
- `poll(request)`

The runner owns shared contract validation, source/run identity checks, duplicate-key rejection and checkpoint safety.

`agents/connectors/registry.py` validates runtime source-registry objects and exposes only policy-APPROVED sources.

`agents/connectors/orchestration.py` provides persistence-neutral `CollectionRunState`, using the existing `AgentRun` contract with `agent_type=SOURCE_MONITORING`.

`agents/connectors/persistence.py` defines the database-independent transaction boundary for normalized source items/evidence plus safe connector checkpoint state.

`agents/connectors/postgres_adapter.py` maps those contracts to the existing BullMatch-private PostgreSQL tables without adding a migration or exposing any canonical write capability.

## Approved runtime source registry

The runtime registry is intentionally narrower than the administrative source registry.

Rules:

- every provider object must validate against `source-registry-entry/1.0.0`
- duplicate `source_id` values are rejected
- `REVIEW_REQUIRED` and `BLOCKED` entries are not exposed to runtime orchestration
- policy-approved but `PAUSED`, `ERROR`, `RETIRED`, or polling-disabled entries cannot be returned as pollable
- connector filtering returns only policy-approved + ACTIVE + poll-enabled sources
- secret requirements describe expected secret names/purpose only; secret values are not part of the registry contract or loader

A future persisted registry provider must return the same contract shape and must not weaken these policy gates.

## Run-state / orchestration contract

`CollectionRunState` provides deterministic orchestration independent of persistence.

At start it records:

- stable `run_id`
- stable `correlation_id`
- `source_id`
- `agent_type = SOURCE_MONITORING`
- agent version
- started time
- RUNNING state
- source input reference
- zeroed collection metrics

Poll request construction:

- requires the run to remain RUNNING
- requires the same source ID as the run
- re-checks APPROVED + ACTIVE + polling-enabled policy
- binds the same run/correlation IDs into the request
- caps requested `max_items` by source policy
- caps requested `max_requests` by source policy
- schema-validates the resulting request before returning it

After a validated `PollExecution`, run state records:

- polls completed
- items emitted
- requests used
- checkpoints advanced
- latest connector health
- `has_more`
- deterministic source-item output references
- connector-reported contract-valid errors

Terminal mapping:

- healthy, error-free run -> `SUCCEEDED`
- degraded/rate-limited/paused or error-bearing run -> `PARTIAL`
- error/auth-required/policy-blocked health -> `FAILED`
- explicit orchestration failure -> `FAILED` plus a SOURCE_MONITORING AgentError

No run state can promote source output into canonical history.

## Persisted AgentRun mapping

`PostgresCollectionRunStore` persists and restores `CollectionRunState` through the already-deployed `bullmatch_private.agent_runs` table.

Mapping rules:

- `run_id` -> `agent_runs.id`
- `agent_type` is fixed to `SOURCE_MONITORING`
- source and correlation identities are required when restoring a collection run
- run status/timestamps/errors/metrics map to existing columns
- `items_emitted` maps to the persisted `items_scanned` operational counter
- an optional `items_persisted_created` metric may map to `items_created`
- contract `input_refs` and `output_refs`, which have no dedicated database columns, are retained inside the private `metrics._bullmatch_run_refs` namespace
- loading a non-SOURCE_MONITORING AgentRun through this adapter fails closed

No schema migration is required for this mapping.

## Preconditions before polling or persistence

The source must remain:

- `policy_status = APPROVED`
- `status = ACTIVE`
- `polling.enabled = true`
- bound to the expected connector key at execution time

The PostgreSQL persistence adapter re-checks APPROVED + ACTIVE + polling-enabled state before accepting a transaction. A source paused or blocked after connector execution therefore cannot silently commit new evidence/checkpoint state.

## Output validation

The complete connector result is schema-validated before a cursor can advance.

The runner additionally enforces:

- result source matches requested source
- result run/correlation IDs match request
- every normalized item belongs to the same source/correlation
- every normalized item declares the actual connector name/version
- `dedupe_key` is unique within one poll result

These checks prevent connector defects from silently crossing source/run boundaries.

## Cursor safety

A persistence layer may store only `PollExecution.committed_cursor` returned by a successful runner execution.

Rules:

- schema/invariant failure -> exception; no cursor may be committed
- `next_cursor.checkpoint_safe = true` -> cursor may advance
- `checkpoint_safe = false` -> runner returns the original request cursor
- persisted/request cursor shape is only `strategy + value`; `checkpoint_safe` remains transient decision metadata

The PostgreSQL adapter locks the source row and existing runtime-state row before staging. A stale expected checkpoint is rejected before source-item/evidence staging. First-poll runtime state is created only when the transaction reaches checkpoint staging; `begin()` itself creates no persisted runtime row.

## Atomic ingestion persistence contract

The persistence boundary can stage only normalized source items/evidence and connector checkpoint state.

`IngestionPersistenceAdapter.begin()` receives:

- `source_id`
- `run_id`
- `correlation_id`
- the caller's expected current cursor

It returns one `IngestionTransaction` that stages all normalized envelopes/evidence first, sets the safe checkpoint, then commits once.

Required transaction invariants:

1. transaction begin itself must not mutate persisted state
2. every envelope must match transaction source/correlation identity
3. `(source_id, dedupe_key)` is the source-item idempotency key
4. exact replay of the same normalized payload is idempotent and does not duplicate evidence
5. reuse of the same dedupe key with a different normalized payload is a conflict/error, never a silent overwrite
6. when `checkpoint_advanced=false`, committed cursor must equal expected cursor
7. stale expected checkpoint is rejected before staging
8. any staging/checkpoint exception rolls back the full transaction
9. source items/evidence and checkpoint become visible together only after commit
10. this interface has no canonical Bull/Match/history write operation

`InMemoryIngestionPersistence` proves these semantics without a database. `PostgresIngestionPersistence` now maps the same interface to the existing `bullmatch_private` tables.

## PostgreSQL/Supabase mapping

The adapter uses only existing BullMatch-private objects:

- `bullmatch_private.sources` — source existence and persistence-time policy gate
- `bullmatch_private.source_runtime_state` — connector cursor/checkpoint
- `bullmatch_private.source_items` — normalized discovered source item
- `bullmatch_private.evidence` — unverified source evidence
- `bullmatch_private.agent_runs` — SOURCE_MONITORING run state

Important mapping decisions:

- evidence is inserted with `moderation_status='PENDING'`; ingestion never marks it verified
- normalized-envelope idempotency fingerprint is stored under `source_items.raw_metadata._bullmatch.normalized_envelope_fingerprint`
- `source_items.content_hash` is **not** overloaded with the envelope fingerprint; it remains available for a future real source-content hash
- `source_ref` is preserved inside private evidence metadata when supplied by the connector contract
- an existing `(source_id, dedupe_key)` row without the normalized-envelope fingerprint is not guessed to be an exact replay; the adapter fails closed for review/repair
- source/runtime locking and item/evidence/checkpoint writes occur in the same PostgreSQL transaction

The adapter accepts a DB-API-style connection factory. Credentials, connection strings and service-role secrets remain outside the module and outside Git.

## Canonical truth boundary

The connector runner, runtime registry, run state and persistence adapters cannot write:

- canonical Bulls
- canonical Match history/results
- verification state
- publication state
- reviewer decisions or controlled promotion

Their output remains untrusted normalized source/evidence input that must proceed through extraction/atomic claims, entity resolution, review/verification and controlled promotion.

The conceptual path remains:

`SOURCE -> NORMALIZED ENVELOPE -> EVIDENCE -> ATOMIC CLAIMS -> RESOLUTION -> REVIEW/VERIFICATION -> CONTROLLED PROMOTION -> PUBLISHED DATA`

## Deterministic tests

Connector tests use `.invalid` URLs and synthetic identifiers only inside test process memory.

Coverage now includes:

- valid result advances a safe checkpoint
- unsafe checkpoint preserves previous cursor
- non-approved source is blocked
- cross-source item is rejected
- duplicate dedupe key in one batch is rejected
- mismatched connector identity is rejected
- runtime registry exposes only APPROVED sources
- duplicate source IDs are rejected
- approved-but-paused source cannot be polled
- SOURCE_MONITORING AgentRun validates against the shared schema
- poll limits cannot exceed source policy caps
- validated execution updates run metrics/output refs
- connector health maps to deterministic terminal run state
- explicit failure emits a contract-valid AgentError
- item + evidence + safe checkpoint commit atomically
- unsafe checkpoint preserves evidence while keeping previous cursor
- exact replay does not duplicate item/evidence
- conflicting same-key payload rolls back full batch
- stale expected cursor is rejected before staging
- PostgreSQL mapping leaves `content_hash` reserved and stores private envelope fingerprint separately
- PostgreSQL policy is rechecked at persistence time
- PostgreSQL conflicting replay rolls back before checkpoint commit
- persisted CollectionRunState round-trips through AgentRun mapping
- non-SOURCE_MONITORING rows are rejected by the collection run store

The PostgreSQL adapter tests use deterministic fake DB-API objects. They execute the real adapter SQL/mapping logic but do not connect to Supabase or retain synthetic Production rows.

## CI

`.github/workflows/contracts.yml` validates shared schemas/examples and runs all connector conformance tests whenever connector runtime or contract files change.

PR #68 validation passed:

- shared schema/example validation — PASS
- connector runner/registry/orchestration/persistence tests — PASS
- PostgreSQL/run-store conformance tests — PASS

## Contract repairs

Earlier Phase 0 cross-schema `$ref` strings were repaired to canonical absolute contract `$id` values without changing payload meaning:

- connector poll request/result references — PR #64
- `agent-run` -> `agent-error` reference — PR #65

## Next implementation slices

After the PostgreSQL/run-state adapter slice, the next safe work inside BMI-P2-001 is:

1. rollback-only SQL/database conformance harness against the actual BullMatch-private schema, with no retained synthetic rows
2. reusable connector fixture helpers so source-specific connectors inherit the same conformance suite
3. operational orchestration wrapper combining approved registry -> persisted run state -> connector -> atomic persistence without selecting a real source
4. persisted source-registry provider if/when orchestration needs database-backed registry loading

A real source-specific connector must wait for a separate source/compliance decision identifying the source, permitted access method, rate limits, rights/retention constraints and connector-specific tests before Production polling is enabled.
