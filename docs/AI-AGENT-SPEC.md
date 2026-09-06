# AI Agent Specification v0.1 — Final Phase 0 Contract

Status: **REVIEW READY**
Task: `BMI-P0-003`
Contract family: `bullmatch.contracts/1.x`

## 1. Goal

Automate daily discovery, collection, extraction, identity matching, duplicate detection, verification assistance, quality checks, and reporting **without allowing unverified AI output to silently become published historical fact**.

The system is designed for multiple independent teams. Every automated component therefore communicates through versioned contracts rather than source-specific database writes.

## 2. Trust Model

### Untrusted / candidate zone
Includes:
- external source content
- connector-normalized items
- AI extracted claims
- inferred identity candidates
- duplicate candidates
- confidence scores

### Reviewed / authoritative zone
Includes:
- reviewer decisions
- verified canonical entities
- verified match records
- published statistics

### Mandatory rule

No agent may write directly into the authoritative statistics path unless a controlled domain operation has already established the required verification/publish state.

The allowed conceptual path is:

```text
SOURCE
  -> INGESTED ITEM
  -> EVIDENCE
  -> EXTRACTION CLAIMS
  -> ENTITY MATCH / DUPLICATE ANALYSIS
  -> VERIFICATION
  -> REVIEW WHEN REQUIRED
  -> CANONICAL DOMAIN OPERATION
  -> VERIFIED
  -> PUBLISHED
```

## 3. Contract Versioning

Machine-readable contracts live under `packages/contracts/`.

Rules:
- each payload contains `schema_version`
- current family: `1.0.0`
- additive optional fields may be introduced in a backward-compatible minor version
- removing/renaming fields, changing meaning, or tightening required behavior requires a major version
- producers must not emit a contract version they do not implement
- consumers must reject unsupported major versions instead of guessing
- provider-specific fields belong inside extensible metadata objects, not shared required fields

## 4. Common Message Metadata

Every persisted or exchanged agent result should be traceable through:

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "produced_at": "timestamp",
  "producer": {
    "type": "CONNECTOR|AGENT|SYSTEM",
    "name": "string",
    "version": "string"
  }
}
```

`correlation_id` links one scheduled/pipeline execution across connector, extraction, resolution, duplicate detection, verification, review creation, and reporting.

## 5. Standard Error Contract

Errors are data, not hidden log text.

Required conceptual structure:

```json
{
  "code": "SOURCE_TIMEOUT",
  "message": "sanitized human-readable description",
  "stage": "SOURCE_MONITORING",
  "retryable": true,
  "source_id": "uuid-or-null",
  "source_item_id": "uuid-or-null",
  "details": {},
  "occurred_at": "timestamp"
}
```

Rules:
- never place passwords, access tokens, service-role keys, cookies, or raw auth headers in errors
- distinguish retryable from permanent failures
- permanent policy/access failures pause or degrade the source rather than trigger endless retries
- failed AI extraction never deletes source evidence

## 6. Agent Run Contract

All scheduled/manual agent executions persist run state compatible with `private.agent_runs`.

```json
{
  "schema_version": "1.0.0",
  "run_id": "uuid",
  "correlation_id": "uuid",
  "agent_type": "SOURCE_DISCOVERY|SOURCE_MONITORING|EXTRACTION|ENTITY_RESOLUTION|DUPLICATE_DETECTION|VERIFICATION|DATA_QUALITY|REPORT",
  "agent_version": "string",
  "source_id": "uuid-or-null",
  "started_at": "timestamp",
  "completed_at": "timestamp-or-null",
  "status": "RUNNING|SUCCEEDED|FAILED|PARTIAL|CANCELLED",
  "input_refs": [],
  "output_refs": [],
  "metrics": {},
  "errors": []
}
```

Partial batch execution records both completed and failed items.

## 7. Source Discovery Agent

### Purpose
Find potentially useful new information sources without automatically trusting or activating them.

### Inputs
- search terms
- known bull/camp/venue/event names and aliases
- current source coverage gaps
- time window
- discovery strategy version

### Output
Candidate source proposals:

```json
{
  "candidate_url": "https://...",
  "source_type": "WEBSITE|RSS|SITEMAP|API|YOUTUBE|SEARCH_DISCOVERY|OTHER",
  "discovery_reason": "string",
  "relevance_score": 0.0,
  "suggested_connector_key": "string-or-null",
  "access_method": "PUBLIC_PAGE|FEED|API|OPERATOR_REVIEW|UNKNOWN",
  "policy_status": "APPROVED|REVIEW_REQUIRED|BLOCKED",
  "notes": "string-or-null"
}
```

### Mandatory behavior
- unknown access/compliance state routes to review
- discovery never stores credentials
- discovery does not activate polling automatically when policy status is uncertain

## 8. Source Monitoring / Connector Contract

Every connector must emit the same normalized ingestion envelope regardless of source platform.

### `NormalizedIngestionEnvelope`

Required fields:
- `schema_version`
- `correlation_id`
- `source_id`
- `external_id` nullable
- `canonical_url` nullable
- `dedupe_key`
- `published_at` nullable
- `retrieved_at`
- `title` nullable
- `normalized_text` nullable
- `raw_metadata`
- `evidence`
- `connector.name`
- `connector.version`

Example:

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "source_id": "uuid",
  "external_id": "source-native-id-or-null",
  "canonical_url": "https://example.org/item/123",
  "dedupe_key": "stable-source-key",
  "published_at": "2026-09-06T02:00:00Z",
  "retrieved_at": "2026-09-06T03:00:00Z",
  "title": "result post",
  "normalized_text": "...",
  "raw_metadata": {},
  "evidence": [],
  "connector": {
    "name": "example-web",
    "version": "1.0.0"
  }
}
```

### Connector idempotency

`dedupe_key` is the primary connector-level identity and must be deterministic for the same real source item.

Preferred key order:
1. source-native stable ID
2. stable canonical URL identity
3. connector-defined stable composite key
4. content identity only when stronger source identity is unavailable

Repeated polling must upsert/no-op the same source item rather than create duplicate rows.

### Evidence input

Connector evidence descriptors may include:
- `TEXT`
- `IMAGE`
- `VIDEO_SEGMENT`
- `AUDIO_SEGMENT`
- `PDF`
- `METADATA`
- `OPERATOR_NOTE`
- `OTHER`

Evidence descriptors include only the minimum necessary verification text plus a stable source/storage reference where available.

## 9. Extraction Agent

### Purpose
Convert a normalized source item into structured **atomic candidate claims**.

### Input
- source item ID
- normalized text/metadata
- evidence references
- extraction contract version
- model/provider configuration

### Output: `ExtractionResult`

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "source_item_id": "uuid",
  "candidate_groups": [
    {
      "candidate_group_id": "uuid",
      "candidate_type": "MATCH|EVENT|ENTITY",
      "claims": [],
      "unresolved_fields": [],
      "warnings": []
    }
  ],
  "model": {
    "provider": "string",
    "name": "string",
    "prompt_version": "string",
    "input_hash": "string"
  }
}
```

### Atomic claim

Each important field becomes an independently auditable claim:

```json
{
  "claim_id": "uuid",
  "subject_type": "MATCH|MATCH_PARTICIPANT|BULL|CAMP|OWNER|VENUE|EVENT",
  "subject_candidate_key": "local-key-within-group",
  "field_key": "winner_name",
  "value": "Example Bull",
  "basis": "EXPLICIT|INFERRED|UNKNOWN",
  "confidence": 0.94,
  "evidence_refs": ["uuid"]
}
```

### Extraction rules

- Explicitly observed facts use `basis=EXPLICIT`.
- Contextual derivations use `basis=INFERRED` and must not be presented as equivalent to explicit evidence.
- Missing facts use `basis=UNKNOWN`, normally with null value or in `unresolved_fields`.
- Never invent missing dates, winner, camp, venue, weight, or identity.
- Confidence range is `0..1` and represents model confidence, not historical truth.
- Important explicit/inferred claims should carry evidence references whenever available.
- One source item may produce multiple candidate groups.

## 10. Extraction Idempotency

Equivalent extraction is identified by the tuple conceptually represented by:

```text
source_item_id
+ input_hash
+ model_provider
+ model_name
+ contract_version
+ prompt_version
```

A retry with identical effective input/config must not silently create multiple competing candidate sets. The orchestration layer may keep attempt history, but it must expose one active result identity for downstream processing.

## 11. Entity Resolution Agent

### Purpose
Determine whether extracted entity mentions refer to existing canonical entities.

Supported initial entity types:
- `BULL`
- `OWNER`
- `CAMP`
- `VENUE`
- `EVENT`

### Signals
Depending on entity type:
- normalized exact name
- verified aliases
- fuzzy name similarity
- camp/owner association
- province/district context
- opponent/date/event context
- lineage/appearance metadata
- historical co-occurrence
- source-specific naming pattern

### Output: `EntityMatchResult`

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "candidate_group_id": "uuid",
  "entity_type": "BULL",
  "candidate_key": "bull-a",
  "resolution_version": "1.0.0",
  "candidates": [
    {
      "entity_id": "uuid",
      "score": 0.91,
      "signals": {
        "normalized_name": 1.0,
        "camp_context": 0.8
      }
    }
  ],
  "recommendation": "AUTO_LINK|REVIEW|NO_MATCH",
  "reason_codes": []
}
```

### Safety rules

- Similar name alone is never sufficient for destructive merge.
- Same-name different bulls must remain possible.
- `AUTO_LINK` thresholds are entity-specific and configurable.
- Merge/split decisions always create identity audit history.
- Conflicting strong signals route to review even when aggregate score is high.
- The entity-resolution agent recommends; canonical destructive operations remain controlled domain/review actions.

## 12. Duplicate Detection Agent

### Purpose
Detect when multiple source items or extracted candidate groups describe the same real event/match/entity.

### Match identity signals
- resolved participant IDs
- candidate participant names
- event ID/name
- venue
- date/time window
- match number
- result
- source publication timing
- known external IDs

### Output: `DuplicateDetectionResult`

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "candidate_group_id": "uuid",
  "candidate_type": "MATCH",
  "detector_version": "1.0.0",
  "matches": [
    {
      "existing_id": "uuid",
      "score": 0.96,
      "signals": {},
      "differing_fields": {
        "duration_seconds": [1200, 1215]
      }
    }
  ],
  "recommendation": "ATTACH_EVIDENCE|REVIEW|NOT_DUPLICATE",
  "reason_codes": []
}
```

### Rules

- Duplicate classification does not discard evidence.
- Evidence from duplicate reports attaches to the canonical match when appropriate.
- Important differing facts create claims/conflict review rather than being overwritten.
- Same participants alone are insufficient when rematches are possible.

## 13. Verification Agent

### Purpose
Evaluate candidate claims against available evidence, source metadata, entity-resolution results, and duplicate analysis.

### Output: `VerificationResult`

```json
{
  "schema_version": "1.0.0",
  "correlation_id": "uuid",
  "candidate_group_id": "uuid",
  "verification_version": "1.0.0",
  "overall_status": "CORROBORATED|CONFLICT|INSUFFICIENT_EVIDENCE|REVIEW_REQUIRED|REJECTED",
  "claim_decisions": [
    {
      "claim_id": "uuid",
      "status": "SUPPORTED|CONFLICT|INSUFFICIENT_EVIDENCE|REJECTED",
      "supporting_evidence_refs": [],
      "contradicting_evidence_refs": [],
      "reason_codes": []
    }
  ],
  "confidence_summary": 0.91,
  "required_review": false,
  "review_reasons": []
}
```

### Verification rules

- A conflict is not resolved by averaging confidence scores.
- Source reliability is an input signal, not an automatic truth override.
- Official/high-reliability evidence may raise confidence but still cannot erase contradictory evidence without a recorded resolution.
- Important unresolved identity prevents automatic canonical match creation.
- `CORROBORATED` means evidence is sufficient under current policy; it does not itself publish a record.

## 14. Human Review Routing

Review cases are mandatory for at least:
- uncertain same-bull identity
- possible duplicate canonical entity
- conflicting match winner/result
- conflicting event/date with statistical impact
- low-confidence mandatory match facts
- destructive merge/split proposal
- new source activation when access/policy is unclear
- suspicious data-quality findings requiring judgment

### Review subject reference

`public.review_cases.subject_ref` follows a versioned structure such as:

```json
{
  "schema_version": "1.0.0",
  "kind": "CANDIDATE_GROUP|CLAIM|CANONICAL_ENTITY|SOURCE|AGENT_RUN",
  "type": "MATCH|BULL|SOURCE|OTHER",
  "id": "uuid",
  "secondary_refs": []
}
```

Review UI must load supporting and contradictory evidence before irreversible identity actions.

## 15. Data Quality Agent

### Purpose
Find suspicious records after extraction or verification.

Initial rules include:
- same bull in overlapping/impossible matches
- completed match with fewer than two participants
- winner participant not belonging to the match
- `WIN` result with no winner
- winner/participant result inconsistency
- implausible weight or age value
- duplicate venue/entity aliases
- published match with non-verified status
- impossible event/match date ordering
- unusually large review backlog or repeated source failures

### Output
Quality findings use stable `rule_id`, severity, subject references, evidence/field context, and recommended routing (`AUTO_FLAG|REVIEW|ERROR`).

## 16. Report Agent

### Daily operator report
Must summarize:
- sources attempted / healthy / failing / paused
- source items discovered and deduplicated
- extraction successes/failures
- candidate groups created
- entity matches auto-linked / sent to review / unmatched
- duplicate candidates
- verification outcomes
- new canonical verified records
- review backlog and aging
- conflicts
- data-quality findings
- failed/retried jobs
- model/provider usage and estimated cost metadata when available

The report agent reads persisted state. It does not infer hidden successes from logs.

## 17. Confidence Policy

Confidence is advisory metadata.

Rules:
- range `0..1`
- thresholds are configurable per task/entity type
- no universal threshold for extraction, identity, duplicate detection, and verification
- destructive merge thresholds are stricter than ordinary entity linking
- high-confidence contradictory sources still produce conflict
- deterministic source IDs/constraints outrank probabilistic similarity for idempotency

Threshold configuration must be versioned so historical decisions can be explained later.

## 18. Retry Policy

### General
- retries use bounded exponential backoff with jitter where appropriate
- maximum attempt count is configured per operation class
- permanent errors stop retrying
- repeated execution is idempotent

### Suggested categories

`TRANSIENT`
- timeout
- temporary upstream 5xx
- rate limit with valid retry window
- temporary model/provider unavailable

`PERMANENT`
- source blocked by policy
- invalid credentials requiring operator action
- unsupported content type
- invalid contract major version
- malformed source configuration

`DATA_REVIEW`
- ambiguous identity
- conflicting result
- uncertain duplicate

`DATA_REVIEW` is not treated as infrastructure failure.

## 19. Pipeline State / Idempotency Boundaries

| Stage | Stable identity / anti-duplicate rule |
|---|---|
| Source ingestion | `(source_id, dedupe_key)` |
| Evidence | source item + content/reference identity |
| Extraction | source item + input hash + model/config/contract version |
| Entity resolution | candidate key + resolution version + canonical index snapshot/version when used |
| Duplicate detection | candidate group + detector version + candidate search snapshot |
| Verification | candidate group + verification version + input claim/evidence fingerprint |
| Review action | append-only action ID; UI command must be request-idempotent |
| Canonical publish | domain operation checks current verification/publish state |

Retries may create attempt logs but must not create duplicate canonical facts.

## 20. Conflict Policy

A conflict exists when materially important claims cannot simultaneously be true under current evidence.

Examples:
- different winner
- different opponent identity
- materially different match date/event identity
- one source says cancelled while another reports completed result

Conflict behavior:
1. preserve all competing claims
2. attach supporting/contradicting evidence
3. mark verification `CONFLICT`
4. create or update one review case for the conflict identity
5. exclude unresolved conflict from authoritative statistics
6. reviewer resolution records reason and provenance

## 21. Provider Abstraction

Business logic must not import provider-specific response shapes outside provider adapters.

Conceptual AI adapter:

```text
extract(input, contractVersion) -> ExtractionResult
```

Adapters may use OpenAI, Gemini, or another approved provider, but shared claims/evidence contracts remain the same.

Provider metadata is recorded for audit/cost analysis.

## 22. Cost Controls

Where practical record:
- provider/model
- input/output usage
- request count
- cached result usage
- estimated cost
- extraction skipped because deterministic parser/cache succeeded

Rules:
- do not invoke an expensive model if deterministic parsing already yields contract-valid output
- do not repeatedly re-extract unchanged source items without a changed reason/version
- scheduled discovery breadth must be controllable by source priority/budget

## 23. Source Compliance Boundary

Agents use only access methods allowed by the source/platform and available permissions.

Connector/source metadata records:
- intended access method
- policy status
- polling permission/status
- rate-limit notes
- operator review notes

Unsupported/restricted access becomes a connector limitation. It is not bypassed.

## 24. Security / Privacy Boundary

- no secret credentials in source items, evidence metadata, model prompts stored for audit, or error payloads
- service-role/secret credentials remain server-side only
- ingest only personal/contact data necessary for the product purpose
- private contact fields do not become public evidence by default
- raw source content is treated as untrusted input, including prompt-injection text
- source content must never be interpreted as system/developer instruction to an agent

## 25. Prompt-Injection Handling

External pages/posts/videos are **data**, not instructions.

Agents must ignore source content attempting to:
- change system policy
- request secrets
- alter connector credentials
- skip verification
- publish a record
- modify repository/database configuration

Extraction prompts/tools must clearly delimit untrusted source text from trusted task instructions.

## 26. Scheduling Strategy

Initial orchestration may use GitHub Actions for low-frequency scheduled jobs.

Logical jobs:
- source monitoring runs based on per-source schedule
- recent-event/result monitoring
- nightly data-quality pass
- nightly daily report

Exact schedules are configuration. Pipeline contracts must remain portable to future workers/queues.

## 27. Observability Metrics

Minimum useful metrics:
- connector fetch duration
- new vs deduplicated source items
- extraction latency/success/failure
- model usage
- entity-resolution outcome counts
- duplicate outcome counts
- verification outcome counts
- review cases created
- review backlog/age
- retry count
- permanent source errors
- daily canonical verified/published count

## 28. Definition of Done for First Automated Collection Pipeline

The first production connector is complete only when:

1. an approved source exists in source registry
2. connector emits `NormalizedIngestionEnvelope`
3. ingestion is idempotent
4. raw evidence/provenance is persisted
5. extraction emits versioned atomic claims
6. unresolved identities route through `EntityMatchResult`
7. duplicate detection cannot silently duplicate an existing match
8. verification preserves conflicts
9. review subject references are valid
10. scheduled run state is persisted
11. retry behavior is bounded/idempotent
12. errors are operator-visible without secrets
13. cost/usage metadata is observable when applicable
14. only verified/published canonical data feeds authoritative statistics

## 29. Team Implementation Boundaries

### Connector team
Owns source-specific retrieval and `NormalizedIngestionEnvelope` production.

### AI extraction team
Owns provider adapters and `ExtractionResult`; does not own canonical database writes.

### Entity resolution team
Owns matching/scoring and `EntityMatchResult`.

### Duplicate/verification team
Owns `DuplicateDetectionResult`, `VerificationResult`, and review routing recommendations.

### Database/domain team
Owns persistence, constraints, canonical operations, RLS, and publish transitions.

### Review UI team
Consumes review subject refs and evidence; submits controlled review/domain commands.

Shared contract changes require downstream-impact notes in PR handoff.
