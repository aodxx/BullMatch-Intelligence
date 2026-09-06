# Architecture — BullMatch Intelligence

Version: 0.2
Status: Phase 0 baseline — shared Supabase tenancy locked

## 1. Architectural Goals

BullMatch Intelligence must support:

- trustworthy historical data
- scheduled multi-source collection
- AI-assisted extraction and entity resolution
- human review of uncertainty/conflicts
- auditability and provenance
- multiple development teams working independently through stable contracts
- safe coexistence with other applications inside one Supabase free-plan project
- future migration to a dedicated Supabase project without redesigning the domain model

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
[Verified BullMatch Database]
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
- BullMatch-specific authorization
- validation
- domain operations
- review decisions
- publish/verify transitions
- statistics queries

AI workers should call controlled application/data interfaces rather than write directly into published read models.

### 3.3 Shared PostgreSQL / Supabase

Primary structured datastore.

Current host strategy:
- reuse the existing Supabase project `aodxx's Project`
- do not create a third Supabase project for BullMatch
- keep the existing `freshmart` project untouched unless a later capacity/isolation decision explicitly changes this

BullMatch owns two dedicated schemas:

- `bullmatch` — canonical application data and review workflow
- `bullmatch_private` — source registry, raw evidence metadata, AI candidates, provenance, audit and worker runtime state

Supabase system infrastructure remains shared:
- `auth`
- `storage`
- platform-managed schemas/extensions

BullMatch migrations must never modify another application's tables or generic shared application tables.

### 3.4 Shared Auth, App-Scoped Authorization

`auth.users` belongs to the shared Supabase project.

BullMatch access is granted only through:

`bullmatch.app_users`

A user existing in `auth.users` is not automatically a BullMatch member.

Roles:
- `ADMIN`
- `REVIEWER`
- `VIEWER`

Authorization rules must use BullMatch-owned membership/role records and must not depend on user-editable auth metadata.

### 3.5 Google Drive

Purpose:
- project documents
- manually supplied source material
- bulky/raw supporting files where appropriate
- reviewed dataset exports
- reports
- team handoffs

Drive is not the primary relational database.

### 3.6 Source Connector Layer

Every source integration implements a common connector contract.

Connector responsibilities:
- identify source
- fetch only permitted/available material
- normalize retrieval metadata
- create idempotent source-item records
- persist evidence references
- expose connector health/errors

Connector-specific parsing must not create verified domain entities directly.

### 3.7 AI Extraction Layer

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

### 3.8 Entity Resolution Layer

Responsibilities:
- candidate-to-existing entity matching
- Thai-safe name/alias handling
- confidence scoring
- possible duplicate entities
- merge/split review support

Entity resolution must be evidence-aware, conservative and reversible/auditable.

### 3.9 Verification Layer

Responsibilities:
- multi-source corroboration
- source reliability weighting where configured
- conflict detection
- duplicate-match candidate detection
- route uncertain records to review

No confidence number alone should erase conflicting evidence.

### 3.10 Human Review Queue

Review types include:
- new bull/entity
- possible same bull
- possible duplicate match
- conflicting result/date
- missing/low-confidence key facts
- new source approval
- merge/split identity operations

Review actions must be audited and idempotent.

### 3.11 Scheduler / Worker Runtime

Initial approach:
- GitHub Actions for low-frequency scheduled orchestration and controlled jobs

Later options when workload grows:
- Supabase Edge Functions / scheduled workloads where appropriate
- dedicated worker service
- queue-based job runner

Scheduling is an implementation detail; job contracts and persisted state remain portable.

## 4. Trust Boundaries

### Untrusted / Candidate Zone — `bullmatch_private`

Contains:
- raw web/source content metadata
- evidence references
- AI output
- unresolved identity matches
- unverified claims
- connector runtime state

This schema is not browser-facing.

### Reviewed / Application Zone — `bullmatch`

Contains:
- BullMatch app membership
- reviewer workflow
- canonical entities/matches
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

Each source item has a connector-specific stable `dedupe_key` or normalized source identity.

The ingestion layer must prefer update/no-op behavior over duplicate creation.

Review commands also use idempotency/version checks so repeated requests or concurrent reviewers do not create duplicate decisions.

## 7. Shared Contract Strategy

Team boundaries depend on stable schemas under `packages/contracts/`.

Shared contracts include:
- source registry
- connector poll request/result
- normalized ingestion envelope
- extraction result
- entity-match result
- duplicate-detection result
- verification result
- review commands/references
- agent runs/errors

Provider- or source-specific code must adapt to these contracts rather than redefine them.

## 8. Data API Strategy

BullMatch uses custom schemas and does not assume tables are automatically exposed to the Supabase Data API.

Rules:
- `bullmatch_private` is never exposed to browser clients
- `bullmatch` is exposed only if a Phase 1 API decision requires direct Supabase Data API access
- every browser-reachable table has RLS and explicit grants
- `TO authenticated` alone is not authorization; policies also verify active `bullmatch.app_users` membership and role
- server-mediated operations are preferred for privileged review/publish/identity changes

## 9. Storage Isolation

If Supabase Storage is used, BullMatch uses app-scoped buckets/paths such as:
- `bullmatch-evidence-private`
- `bullmatch-public-media`

Storage policies must be BullMatch-specific.

Large raw evidence should not be stored directly as PostgreSQL blobs; store hashes/references and use object storage or approved Drive locations where appropriate.

## 10. Edge Functions / Scheduled Resource Naming

Any BullMatch function/job inside the shared project uses a BullMatch prefix, for example:
- `bullmatch-ingest`
- `bullmatch-review-action`
- `bullmatch-daily-report`

A scheduled job must not assume it is the only workload in the shared project.

## 11. Security Architecture

- secrets stay in environment/platform secret stores
- service-role/secret keys never reach public clients
- least-privilege service credentials
- RLS on every exposed BullMatch table
- app-scoped membership checks
- reviewer/admin roles separated from public reads
- connector tokens isolated by integration
- no raw secrets written to logs
- no BullMatch migration modifies unrelated schemas
- `bullmatch_private` remains outside browser Data API exposure

## 12. Shared-Project Isolation Tests

Before Phase 1 is considered operational, tests must prove:

- anonymous clients cannot write BullMatch canonical data
- a shared-project authenticated user without an active `bullmatch.app_users` row has no privileged BullMatch access
- reviewers cannot access another application's data through BullMatch APIs/policies
- browser clients cannot access `bullmatch_private`
- BullMatch migrations leave unrelated schemas/tables unchanged
- raw AI candidates cannot enter public statistics without verification/publish policy

## 13. Team Architecture Boundaries

- UI teams depend on documented APIs/contracts, not private database internals
- connector teams emit normalized ingestion envelopes
- AI teams emit versioned candidate schemas
- database team owns BullMatch-scoped migrations and integrity constraints
- verification team consumes candidates and produces review decisions/status
- shared-Supabase changes must not be hidden inside unrelated feature tasks

Any shared-contract or shared-infrastructure change must list downstream impact in its PR.

## 14. Phase 0 Architecture Decisions

Locked:
- PostgreSQL/Supabase primary datastore
- reuse existing Supabase project rather than create a third project
- `bullmatch` + `bullmatch_private` namespace isolation
- shared `auth.users` with BullMatch app-scoped membership
- evidence/provenance first-class
- AI output is candidate data
- human review supported from first automated ingestion phase
- connector-based source integrations
- multi-agent Task ID + branch/PR workflow
- architecture remains portable to a future dedicated Supabase project

Pending:
- exact web framework and hosting
- exact AI provider(s)
- queue/runtime beyond initial scheduler
- first production source connector
- whether any `bullmatch` tables need direct Data API exposure versus server-mediated access
