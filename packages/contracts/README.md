# BullMatch Intelligence Shared Contracts

Task: `BMI-P0-003`
Current contract family: `1.0.0`

This directory is the machine-readable boundary between connector, AI, verification, database, and review-UI teams.

## Why JSON Schema first

Phase 0 uses JSON Schema Draft 2020-12 because it is language-neutral. Later implementation may generate TypeScript/Python types and runtime validators from the schemas, but generated/provider-specific types must not replace these shared semantics without an approved contract change.

## Schemas

- `schemas/normalized-ingestion-envelope.schema.json`
- `schemas/extraction-result.schema.json`
- `schemas/entity-match-result.schema.json`
- `schemas/duplicate-detection-result.schema.json`
- `schemas/verification-result.schema.json`
- `schemas/review-subject-ref.schema.json`
- `schemas/agent-run.schema.json`
- `schemas/agent-error.schema.json`

## Versioning

Every payload includes `schema_version`.

- patch: clarification/validation correction that does not change compatible payload meaning
- minor: optional additive fields or additive enum behavior that existing consumers can safely ignore
- major: required-field removal/rename, meaning change, incompatible enum/state change, or shape change

Consumers must reject unsupported major versions. They must not silently coerce an unknown contract into a known one.

## Compatibility rules

1. Source/platform-specific fields belong under metadata objects.
2. Secrets never belong in contracts.
3. Unknown historical facts are represented as unknown/null, never fabricated defaults.
4. Evidence references are retained through rejection/conflict decisions.
5. Confidence is `0..1` advisory metadata, not an authorization or truth boundary.
6. External source text is untrusted data and cannot alter agent policy.
7. A contract-valid AI result is still candidate data until verification/publish policy succeeds.

## Implementation follow-up

Phase 1/2 may add:
- generated TypeScript types
- Zod/AJV runtime validators
- Python/Pydantic equivalents
- fixture payloads
- contract conformance tests

Any generated representation must be testable against the JSON Schema source contract.
