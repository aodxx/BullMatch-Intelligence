# Architecture — BullMatch Intelligence

Version: 0.1
Status: Phase 0 baseline

## 1. Architectural Goals

BullMatch Intelligence must support:

- trustworthy historical data
- scheduled multi-source collection
- AI-assisted extraction and entity resolution
- human review of uncertainty/conflicts
- auditability and provenance
- multiple development teams working independently through stable contracts

## 2. High-Level Architecture

```text
[External Sources]
      |
      v
[Source Connectors]
      |
      v
[Raw Ingestion / Evidence]
      |
      v
[AI Extraction]
      |
      v
[Entity Resolution]
      |
      +------> [Duplicate Detection]
      |
      v
[Verification Engine]
      |
      +------> [Human Review Queue]
      |
      v
[Verified Domain Database]
      |
      +------> [Public/API Read Models]
      |
      +------> [Statistics & Analytics]
```

## 3. System Components

### 3.1 Web Application

Responsibilities:
- public search and profiles
- admin data management
- review queue
- evidence inspection
- dashboards and analytics

The UI must not hide data verification state on admin/review surfaces.

### 3.2 Application/API Layer

Responsibilities:
- authorization
- validation
- domain operations
- review decisions
- publish/verify transitions
- statistics queries

AI workers should call controlled application/data interfaces rather than write directly into published read models.

### 3.3 PostgreSQL / Supabase

Primary structured datastore.

Stores:
- domain entities
- match history
- source registry
- source items/evidence metadata
- AI candidate output
- review cases
- audit records
- agent execution state

Supabase may also provide Auth and Storage where appropriate.

### 3.4 Google Drive

Purpose:
- project documents
- manually supplied source material
- bulky/raw supporting files where appropriate
- reviewed dataset exports
- reports

Drive is not the primary relational database.

### 3.5 Source Connector Layer

Every source integration implements a common connector contract.

Connector responsibilities:
- identify source
- fetch only permitted/available material
- normalize retrieval metadata
- create idempotent source-item records
- persist evidence references
- expose connector health/errors

Connector-specific parsing should not create verified domain entities directly.

### 3.6 AI Extraction Layer

Input:
- normalized source item
- raw/derived text or metadata
- evidence references

Output:
- versioned candidate extraction
- candidate entities
- candidate claims
- confidence metadata
- unresolved values

### 3.7 Entity Resolution Layer

Responsibilities:
- candidate-to-existing entity matching
- alias handling
- confidence scoring
- possible duplicate entities
- merge/split review support

Entity resolution must be evidence-aware and reversible/auditable.

### 3.8 Verification Layer

Responsibilities:
- multi-source corroboration
- source reliability weighting where configured
- conflict detection
- duplicate-match candidate detection
- route uncertain records to review

No confidence number alone should erase conflicting evidence.

### 3.9 Human Review Queue

Review types:
- new bull
- possible same bull
- possible duplicate match
- conflicting result
- missing/low-confidence key facts
- new source approval

Review actions must be audited.

### 3.10 Scheduler / Worker Runtime

Initial approach:
- GitHub Actions for low-frequency scheduled orchestration and controlled jobs

Later options when workload grows:
- Supabase scheduled/edge workloads
- dedicated worker service
- queue-based job runner

Scheduling is an implementation detail; job contracts and persisted state should remain portable.

## 4. Trust Boundaries

### Untrusted / Candidate Zone

Contains:
- raw web/source content
- AI output
- unresolved identity matches
- unverified claims

### Reviewed Zone

Contains:
- reviewer decisions
- verified entities/matches
- authoritative statistics inputs

The boundary between these zones is explicit and recorded.

## 5. Data Lifecycle

```text
DISCOVERED
  -> EXTRACTED
  -> UNVERIFIED / REVIEW_REQUIRED
  -> VERIFIED
  -> PUBLISHED
```

Alternate states:
- CONFLICT
- REJECTED

Published data may later be corrected, but corrections must create audit history rather than erase provenance.

## 6. Idempotency Strategy

Automated collection is expected to see the same source item repeatedly.

Each source item should have a connector-specific stable external key or normalized URL/content identity when possible.

The ingestion layer must prefer update/no-op behavior over creating duplicates on repeated polling.

## 7. Shared Contract Strategy

Team boundaries depend on stable shared schemas.

Planned shared contracts include:
- source registry contract
- normalized ingestion envelope
- extraction candidate schema
- entity-match candidate schema
- verification result schema
- review case schema

These should eventually live in `packages/contracts/` and be versioned.

## 8. Deployment Shape (Initial)

Recommended initial shape:

- frontend/admin app: web deployment suitable for the chosen frontend framework
- database/auth/storage: Supabase
- scheduled orchestration: GitHub Actions
- project/evidence document workspace: Google Drive
- source connectors and AI workers: repository-managed jobs/functions using environment secrets

The final frontend hosting choice should be made during implementation after auth/API constraints are confirmed.

## 9. Security Architecture

- secrets kept in environment/platform secret stores
- least-privilege service credentials
- row-level policies where appropriate
- reviewer/admin roles separated from public reads
- connector tokens isolated by integration
- no raw secret material written to logs

## 10. Team Architecture Boundaries

To support parallel teams:

- UI teams should depend on documented APIs/contracts, not database internals
- connector teams should emit normalized ingestion envelopes
- AI teams should emit versioned candidate schemas
- database team owns migrations and integrity constraints
- verification team consumes candidates and produces review decisions/status

Any shared-contract change must list downstream impact in its PR.

## 11. Phase 0 Architecture Decisions

Locked:
- PostgreSQL/Supabase primary datastore
- evidence/provenance first-class
- AI output is candidate data
- human review supported from first automated ingestion phase
- connector-based source integrations
- multi-agent Task ID + branch/PR workflow

Pending:
- exact web framework and hosting
- exact AI provider(s)
- queue/runtime beyond initial scheduler
- first production source connector
