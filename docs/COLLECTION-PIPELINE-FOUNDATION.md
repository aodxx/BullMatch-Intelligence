# Source-Agnostic Collection Pipeline Foundation

Task: `BMI-P2-001`
Status: **IMPLEMENTATION BASELINE — REGISTRY + RUN STATE + ATOMIC PERSISTENCE CONTRACT**
Contract family: `bullmatch.contracts/1.x`

## Purpose

Turn the Phase 0 connector contracts into an executable, testable boundary before any real Production source is selected.

This task does **not** authorize scraping or polling any real source. It establishes the rules every later permitted connector must obey.

## Existing contracts reused

The implementation reuses the existing JSON Schema 1.0.0 contracts under `packages/contracts/schemas/`:

- `source-registry-entry.schema.json`
- `connector-poll-request.schema.json`
- `connector-poll-result.schema.json`
- `normalized-ingestion-envelope.schema.json`
- `agent-run.schema.json`
- `agent-error.schema.json`

No competing source contract is introduced.

## Runtime boundary

`agents/connectors/runner.py` exposes a minimal source-agnostic `Connector` protocol and `run_connector_poll()`.

A connector implementation supplies only:

- `key`
- `name`
- `version`
- `poll(request)`

The runner owns the shared safety checks around that connector.

`agents/connectors/registry.py` adds a persistence-neutral runtime registry boundary. It validates every provider entry against the shared source-registry contract and exposes only sources whose `policy_status` is `APPROVED`.

`agents/connectors/orchestration.py` adds a persistence-neutral `CollectionRunState`. It uses the existing `AgentRun` contract with `agent_type=SOURCE_MONITORING`, creates bounded `ConnectorPollRequest` objects, records validated connector execution metrics, and produces terminal run state without writing Production data.

`agents/connectors/persistence.py` adds the database-independent transaction contract that future adapters must implement for normalized source items/evidence and safe connector checkpoint state.

## Approved runtime source registry

The runtime registry is intentionally narrower than the administrative source registry.

Rules:

- every provider object must validate against `source-registry-entry/1.0.0`
- duplicate `source_id` values are rejected
- `REVIEW_REQUIRED` and `BLOCKED` entries are not exposed to runtime orchestration
- policy-approved but `PAUSED`, `ERROR`, `RETIRED`, or polling-disabled entries cannot be returned as pollable
- connector filtering returns only policy-approved + ACTIVE + poll-enabled sources
- secret requirements describe expected secret names/purpose only; secret values are not part of the registry contract or loader

A future Production adapter may read the persisted source registry, but it must provide the same contract objects to this boundary and must not weaken the policy gate.

## Run-state / orchestration contract

`CollectionRunState` provides a deterministic orchestration object without a database dependency.

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
- caps requested `max_items` by `polling.max_items_per_run`
- caps requested `max_requests` by `rate_limit.max_requests_per_run`
- schema-validates the resulting request before returning it

After a validated `PollExecution`, run state records:

- polls completed
- items emitted
- requests used
- checkpoints advanced
- latest connector health
- `has_more`
- deterministic source-item output references based on source ID + dedupe key
- connector-reported contract-valid errors

Terminal mapping:

- healthy, error-free run -> `SUCCEEDED`
- degraded/rate-limited/paused or error-bearing run -> `PARTIAL`
- error/auth-required/policy-blocked health -> `FAILED`
- explicit orchestration failure -> `FAILED` plus a contract-valid SOURCE_MONITORING AgentError

No terminal state promotes source output into canonical BullMatch history.

## Preconditions before polling

The request must pass JSON Schema validation and the source must be:

- `policy_status = APPROVED`
- `status = ACTIVE`
- `polling.enabled = true`
- bound to the same `connector_key` as the implementation

A source marked `REVIEW_REQUIRED`, `BLOCKED`, paused or disabled cannot be polled through this runner.

## Output validation

The complete connector result is schema-validated before a cursor can advance.

The runner additionally enforces:

- result `source_id` matches the requested source
- result `run_id` and `correlation_id` match the request
- every normalized item belongs to the same source
- every normalized item carries the same correlation ID
- every normalized item declares the actual connector name/version
- `dedupe_key` is unique within one poll result

These checks prevent a connector bug from silently crossing source/run boundaries.

## Cursor safety

A persistence layer may store only the returned `committed_cursor` from a valid `PollExecution`.

Rules:

- schema or invariant failure -> exception; no cursor returned for commit
- `next_cursor.checkpoint_safe = true` -> cursor may advance
- `checkpoint_safe = false` -> runner returns the original request cursor

The run-state object counts a checkpoint as advanced only after `run_connector_poll()` has returned a valid `PollExecution` with `checkpoint_advanced=true`.

## Atomic ingestion persistence contract

The persistence boundary is intentionally narrower than a general database repository. It can stage only normalized source items/evidence and connector checkpoint state.

`IngestionPersistenceAdapter.begin()` receives:

- `source_id`
- `run_id`
- `correlation_id`
- the caller's expected current cursor

It returns one `IngestionTransaction` that must stage all normalized envelopes/evidence first, then set the safe checkpoint, then commit once.

Required transaction invariants:

1. transaction begin itself must not mutate persisted state
2. every envelope must match the transaction source/correlation identity
3. `(source_id, dedupe_key)` is the idempotency key for a normalized source item
4. exact replay of the same normalized payload is idempotent and must not duplicate evidence
5. reuse of the same dedupe key with a different normalized payload is a conflict/error; it must never overwrite the stored evidence silently
6. when `checkpoint_advanced=false`, the committed cursor must equal the expected cursor
7. stale expected checkpoint is rejected before staging
8. any staging/checkpoint exception rolls back the full transaction
9. source items/evidence and checkpoint become visible together only after commit
10. this interface has no canonical Bull/Match/history write operation

The deterministic `InMemoryIngestionPersistence` adapter exists only to prove these semantics in conformance tests. It is not a Production persistence implementation.

Future PostgreSQL/Supabase mapping should target the already-deployed private ingestion layer rather than inventing a parallel datastore. The database adapter must map the contract onto BullMatch-owned private objects such as source items, evidence, runtime cursor state and agent-run records while preserving the same atomicity and policy boundaries.

## Canonical truth boundary

The connector runner, runtime registry, run state and ingestion persistence contract cannot write:

- canonical Bulls
- canonical Match history/results
- verification state
- publication state

Their output remains an untrusted normalized source/evidence input that must proceed through ingestion/evidence, extraction/atomic claims, entity resolution, review/verification and controlled promotion.

The conceptual path remains:

`SOURCE -> NORMALIZED ENVELOPE -> EVIDENCE -> ATOMIC CLAIMS -> RESOLUTION -> REVIEW/VERIFICATION -> CONTROLLED PROMOTION -> PUBLISHED DATA`

## Deterministic tests

Connector tests use `.invalid` test URLs and synthetic identifiers only inside test process memory.

Coverage includes:

- valid result advances a safe checkpoint
- unsafe checkpoint preserves previous cursor
- non-approved source is blocked
- cross-source item is rejected
- duplicate dedupe key in one batch is rejected
- mismatched connector identity is rejected
- runtime registry exposes only APPROVED sources
- duplicate source IDs are rejected
- approved-but-paused source cannot be polled
- SOURCE_MONITORING AgentRun state validates against the shared schema
- poll limits cannot exceed source policy caps
- validated PollExecution updates run metrics/output refs
- connector health maps to deterministic terminal run state
- explicit failure emits a contract-valid AgentError
- cross-source run/request composition is rejected
- item + evidence + safe checkpoint commit atomically
- unsafe checkpoint can preserve evidence while keeping the previous cursor
- exact replay does not duplicate item/evidence
- conflicting same-key payload rolls back the full batch
- stale expected cursor is rejected before staging

Fixtures are contract examples only and are never inserted into Production.

## CI

`.github/workflows/contracts.yml` validates shared schemas/examples and runs connector conformance tests whenever connector runtime or contract files change.

## Contract repairs

Phase 0 contained cross-schema `$ref` strings that were meaningful to humans but not resolvable against sibling canonical `$id` values through a standards-compliant registry.

BMI-P2-001 repairs these references to the already-existing absolute contract `$id` values:

- connector poll request/result references repaired in PR #64
- `agent-run` -> `agent-error` reference repaired in PR #65

These repairs do not change payload meaning or the 1.0.0 data shapes.

## Next implementation slices

Within BMI-P2-001, safe next work can add:

1. persisted AgentRun/run-state adapter compatible with `CollectionRunState`
2. PostgreSQL/Supabase adapter mapping to the existing private ingestion tables
3. rollback-only/database conformance tests proving dedupe + evidence + checkpoint atomicity
4. reusable connector fixture helpers
5. operational orchestration wrapper combining approved registry -> run state -> connector -> persistence adapter without selecting a real source

A real source-specific connector must wait for a separate source/compliance decision. That future task should identify the source, permitted access method, rate limits, rights/retention constraints and connector-specific tests before enabling Production polling.
