# Source-Agnostic Collection Pipeline Foundation

Task: `BMI-P2-001`
Status: **IMPLEMENTATION BASELINE**
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

A later orchestration/persistence layer may store only the returned `committed_cursor`.

Rules:

- schema or invariant failure -> exception; no cursor returned for commit
- `next_cursor.checkpoint_safe = true` -> cursor may advance
- `checkpoint_safe = false` -> runner returns the original request cursor

This implements the existing contract rule that invalid/unconfirmed connector output must not commit progress and skip evidence.

## Canonical truth boundary

The connector runner cannot write:

- canonical Bulls
- canonical Match history/results
- verification state
- publication state

Its output remains a `NormalizedIngestionEnvelope`: untrusted source evidence that must proceed through ingestion/evidence, extraction/atomic claims, entity resolution, review/verification and controlled promotion.

The conceptual path remains:

`SOURCE -> NORMALIZED ENVELOPE -> EVIDENCE -> ATOMIC CLAIMS -> RESOLUTION -> REVIEW/VERIFICATION -> CONTROLLED PROMOTION -> PUBLISHED DATA`

## Deterministic tests

`agents/connectors/tests/test_runner.py` uses `.invalid` test URLs and synthetic identifiers only inside test process memory.

Coverage includes:

- valid result advances a safe checkpoint
- unsafe checkpoint preserves previous cursor
- non-approved source is blocked
- cross-source item is rejected
- duplicate dedupe key in one batch is rejected
- mismatched connector identity is rejected

Fixtures are contract examples only and are never inserted into Production.

## CI

`.github/workflows/contracts.yml` validates shared schemas/examples and runs connector conformance tests whenever connector runtime or contract files change.

## Contract repair

The Phase 0 connector request/result schemas used relative `$ref` strings that did not resolve to the sibling schemas' canonical `$id` values when loaded as a registry.

BMI-P2-001 changes those references to the already-existing absolute contract `$id` values. It does not change payload meaning or the 1.0.0 data shape; it makes the declared cross-schema contract executable by standards-compliant validators.

## Next implementation slices

Within BMI-P2-001, safe next work can add:

1. a source registry loader that accepts only approved registry entries
2. an orchestration object that records run state without source-specific assumptions
3. deterministic persistence adapter interfaces for source items/evidence, without Production writes in unit tests
4. explicit dedupe/checkpoint persistence transaction contract
5. conformance fixture helpers for future connectors

A real source-specific connector must wait for a separate source/compliance decision. That future task should identify the source, permitted access method, rate limits, rights/retention constraints and connector-specific tests before enabling Production polling.
