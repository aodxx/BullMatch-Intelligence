# BullMatch Intelligence Shared Contracts

Foundation tasks: `BMI-P0-003`, `BMI-P0-006`
Current contract family: `1.0.0`

This directory is the machine-readable boundary between connector, AI, verification, database, and review-UI teams.

## Why JSON Schema first

Phase 0 uses JSON Schema Draft 2020-12 because it is language-neutral. Later implementation may generate TypeScript/Python types and runtime validators from the schemas, but generated/provider-specific types must not replace these shared semantics without an approved contract change.

## Schemas

### Source / connector
- `schemas/source-registry-entry.schema.json`
- `schemas/connector-poll-request.schema.json`
- `schemas/connector-poll-result.schema.json`
- `schemas/normalized-ingestion-envelope.schema.json`

### AI / verification
- `schemas/extraction-result.schema.json`
- `schemas/entity-match-result.schema.json`
- `schemas/duplicate-detection-result.schema.json`
- `schemas/verification-result.schema.json`
- `schemas/review-subject-ref.schema.json`

### Operations
- `schemas/agent-run.schema.json`
- `schemas/agent-error.schema.json`

## Versioning

Every payload includes `schema_version` where it is a top-level message.

- patch: clarification/validation correction that does not change compatible payload meaning
- minor: optional additive fields or additive enum behavior that existing consumers can safely ignore
- major: required-field removal/rename, meaning change, incompatible enum/state change, or shape change

Consumers must reject unsupported major versions. They must not silently coerce an unknown contract into a known one.

## Compatibility rules

1. Source/platform-specific fields belong under metadata/config objects.
2. Secrets never belong in contracts; only secret requirement names may be declared.
3. Unknown historical facts are represented as unknown/null, never fabricated defaults.
4. Evidence references are retained through rejection/conflict decisions.
5. Confidence is `0..1` advisory metadata, not an authorization or truth boundary.
6. External source text is untrusted data and cannot alter agent policy.
7. A contract-valid AI result is still candidate data until verification/publish policy succeeds.
8. Connector output must validate before cursor state is committed.
9. Source-specific retrieval logic must not write canonical sports data directly.

## Examples

Examples under `examples/` are fixtures for documentation and contract validation. Connector teams should add fixtures for new connector-specific configurations without putting credentials into them.

## Implementation follow-up

Phase 1/2 may add:
- generated TypeScript types
- Zod/AJV runtime validators
- Python/Pydantic equivalents
- more fixture payloads
- connector conformance tests

Any generated representation must be testable against the JSON Schema source contract.
