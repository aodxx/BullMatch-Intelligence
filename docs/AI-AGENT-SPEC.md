# AI Agent Specification v0.1

Status: Phase 0 design baseline

## 1. Goal

Automate daily discovery, collection, extraction, matching, verification assistance, and reporting without allowing unverified AI output to silently become published historical fact.

## 2. Agent Types

### Source Discovery Agent

Purpose: identify candidate new information sources.

Input:
- search terms
- known bull/camp/venue/event entities
- recent source gaps

Output:
- candidate source URL/identifier
- source type
- discovery reason
- preliminary relevance score
- access/compliance notes when known

Must not automatically activate a source if access rules are unclear.

### Source Monitoring Agent

Purpose: poll approved source registry entries.

Input:
- source definition
- connector config
- last successful cursor/timestamp

Output:
- normalized source items
- retrieval metadata
- evidence references
- health/error metrics

Must be idempotent for repeated source items.

### Extraction Agent

Purpose: convert unstructured source items into structured candidate claims.

Potential fields:
- event/venue/date
- participant names
- camps/owners
- match number
- result/winner
- duration
- match-time weight/age
- evidence references

Must return unknown values explicitly instead of inventing missing values.

### Entity Resolution Agent

Purpose: determine whether extracted names refer to existing entities.

Signals may include:
- normalized names
- verified aliases
- camp/owner context
- geography
- event/date/opponent context
- lineage/physical metadata

Output:
- proposed entity ID(s)
- score
- signal breakdown
- auto-link/review/no-match recommendation

Low-confidence identity matches must go to review.

### Duplicate Detection Agent

Purpose: detect when multiple source items describe the same real match/event/entity.

Signals may include:
- participants
- date/time
- venue
- event
- match number
- result
- source publication timing

Output:
- duplicate candidate group
- score
- differing fields
- linked evidence

### Verification Agent

Purpose: evaluate candidate claims against available evidence and source reliability metadata.

Output:
- corroborated claims
- conflicting claims
- confidence summary
- review requirements

A conflict is not resolved merely by averaging confidence scores.

### Data Quality Agent

Purpose: find suspicious verified/candidate data.

Examples:
- same bull appearing in impossible overlapping matches
- result with no participants
- winner not in participant set
- duplicate venue aliases
- extreme weight values
- invalid date ordering

### Report Agent

Purpose: summarize scheduled run results for operators.

Daily report should include:
- source health
- items discovered
- new candidates
- verified records
- pending review
- conflicts
- possible duplicates
- failed jobs
- unusual data-quality findings

## 3. Standard Agent Contract

Every agent run should have:

```json
{
  "run_id": "uuid",
  "agent_type": "...",
  "agent_version": "...",
  "input_refs": [],
  "started_at": "timestamp",
  "status": "RUNNING|SUCCEEDED|FAILED|PARTIAL",
  "output_refs": [],
  "metrics": {},
  "errors": []
}
```

Actual typed contracts will be defined in `packages/contracts/` during implementation.

## 4. Normalized Ingestion Envelope

All source connectors should emit a common conceptual envelope:

```json
{
  "source_id": "uuid",
  "external_id": "source-native-id-or-null",
  "canonical_url": "url-or-null",
  "published_at": "timestamp-or-null",
  "retrieved_at": "timestamp",
  "title": "text-or-null",
  "normalized_text": "text-or-null",
  "raw_metadata": {},
  "evidence_refs": [],
  "connector": {
    "name": "...",
    "version": "..."
  }
}
```

## 5. Extraction Output Rules

Extraction output must distinguish:

- value explicitly observed in evidence
- value inferred from context
- unresolved/unknown value

Every important extracted claim should carry an evidence pointer whenever possible.

Example concept:

```json
{
  "field": "winner_name",
  "value": "Example Bull",
  "confidence": 0.94,
  "basis": "explicit",
  "evidence_refs": ["..."]
}
```

## 6. Confidence Policy

Confidence is advisory, not truth.

Policy thresholds must be configurable and task-specific.

Examples:
- high confidence may allow automatic candidate linking
- identity merges require stricter rules than ordinary text extraction
- conflicting high-confidence sources still create a conflict case

Do not use a single universal confidence threshold for every agent decision.

## 7. Human Review Routing

Review cases are mandatory for at least:

- uncertain same-bull identity
- possible duplicate canonical entity
- conflicting match winner/result
- conflicting event/date with statistical impact
- low-confidence mandatory match fields
- destructive merge/split proposals
- new source activation when policy/access is uncertain

## 8. Retry & Failure Handling

Agents must be retry-safe.

Requirements:
- source retrieval retries use bounded backoff
- repeated retries do not create duplicate source items
- AI extraction failure does not delete raw evidence
- partial batch failure records completed items and failed items separately
- permanent source failure affects source health and operator report

## 9. Scheduling Strategy

Initial orchestration can run from GitHub Actions on scheduled intervals.

Recommended logical jobs:
- morning source monitoring
- midday/recent-event monitoring
- evening result monitoring
- nightly quality/report aggregation

Exact frequencies are configured per source and can evolve later.

## 10. Cost Controls

AI usage must be observable.

Where practical, store:
- provider/model
- request count
- token/usage metadata
- estimated cost metadata
- cache/dedup savings

Do not invoke an expensive model when deterministic parsing or cached extraction already provides the required result.

## 11. Provider Abstraction

The system should not hard-code business logic to one AI provider.

Use an adapter interface so extraction/resolution tasks can use suitable providers/models while shared output contracts remain stable.

## 12. Source Compliance Boundary

Agents only use access methods allowed by each source/platform and available credentials/permissions.

Connector metadata should state the intended access method (API/feed/public page/operator upload/etc.).

Unsupported or restricted access must be represented as a connector limitation, not bypassed.

## 13. Definition of Done for First Automated Agent

The first production collection pipeline is complete only when:

1. an approved source exists in the source registry
2. connector ingestion is idempotent
3. raw evidence/provenance is persisted
4. extraction output follows a versioned schema
5. unresolved entity matches route to review
6. possible duplicates are not silently duplicated
7. conflicts survive as conflicts
8. scheduled run history is recorded
9. failures are visible to operators
10. verified data is the only authoritative statistics input
