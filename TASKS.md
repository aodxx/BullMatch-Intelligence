# Task Registry

This file is the high-level project map. GitHub Issues/PRs track execution.

## Phase 0 — Foundation & Architecture — COMPLETE

### BMI-P0-001 — Repository & Collaboration Foundation
Owner: Primary Maintainer
Status: DONE

Completed:
- repository structure
- `AGENTS.md`
- multi-agent Task ID/branch/PR rules
- issue/PR templates
- shared status/handoff workflow
- Google Drive handoff structure

### BMI-P0-002 — Database Schema v0.1
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #1 / PR #5

Completed:
- canonical domain model
- source/evidence/candidate/review/provenance model
- historical match snapshots
- result integrity model
- source idempotency strategy
- indexes/constraints/RLS assumptions
- merge/split identity history
- migration plan

### BMI-P0-003 — AI Agent & Verification Contracts
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #2 / PR #6

Completed:
- normalized ingestion contract
- extraction/claim contract
- entity-match contract
- duplicate-detection contract
- verification contract
- review subject reference
- agent run/error contracts
- provider abstraction
- retry/idempotency/conflict rules
- contract CI

### BMI-P0-004 — PRD v0.2
Owner: Primary Maintainer
Status: DONE

Completed:
- product goals/users
- core workflows
- MVP boundary
- functional/non-functional requirements
- automation requirements
- shared Supabase requirements
- success measures
- phase plan

### BMI-P0-005 — Architecture v0.2
Owner: Primary Maintainer
Status: DONE

Completed:
- component/data-flow boundaries
- trust zones
- API/worker boundaries
- scheduler/storage strategy
- shared contract architecture
- shared Supabase tenancy and isolation model

### BMI-P0-006 — Source Registry & Connector Contract
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #7 / PR #8

Completed:
- source policy vs health state
- polling/cursor model
- transactional cursor commit rule
- rate-limit/backoff metadata
- secret boundary
- deterministic connector dedupe ownership
- operator-upload/search-discovery boundaries
- first-connector readiness checklist

### BMI-P0-007 — Entity Resolution Strategy
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #3 / PR #9

Completed:
- Thai-safe normalization
- candidate generation
- positive/negative/hard-conflict signals
- conservative auto-link/review/no-match policy
- source-native identity mapping
- alias lifecycle
- human-controlled reversible merge/split
- calibration/golden fixture plan

### BMI-P0-008 — Review Queue UX Specification
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #4 / PR #12

Completed:
- queue/detail information architecture
- evidence viewer
- new match/entity review
- entity-match/duplicate/conflict review
- data-quality review
- merge/split impact flows
- idempotent review commands
- optimistic concurrency
- audit/reopen behavior
- mobile/accessibility requirements

### BMI-P0-009 — Shared Supabase Tenancy Adaptation
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #10 / PR #11

Completed:
- selected existing `aodxx's Project` as BullMatch shared host
- kept `freshmart` outside BullMatch scope
- `bullmatch` / `bullmatch_private` namespace isolation
- shared `auth.users` + app-scoped BullMatch membership
- Data API/RLS/isolation rules
- namespace overlay for original database schema
- host inventory/advisor checks

### BMI-P0-010 — Phase 0 Sign-off
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #13

Deliverables:
- final PRD/status/task reconciliation
- Phase 0 exit confirmation
- Phase 1 handoff

---

## Phase 1 — Core Verified Database

### BMI-P1-001 — Shared Supabase Bootstrap
Status: READY AFTER P0-010 MERGE

Scope:
- re-check shared host inventory
- create `bullmatch` and `bullmatch_private` schemas through migration
- create minimal app membership foundation
- establish grants/RLS baseline
- add isolation tests
- run security/performance advisors

### BMI-P1-002 — Core Database Migrations
Status: BLOCKED BY P1-001

Scope:
- owners/camps/bulls/venues/events + aliases
- matches/participants/results
- review workflow
- source/evidence/agent/candidate/provenance/runtime tables
- indexes/integrity helpers

### BMI-P1-003 — Seed / Reference Data
Status: BLOCKED BY P1-002

### BMI-P1-004 — Admin Authentication & Roles
Status: BLOCKED BY P1-001/P1-002

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: BLOCKED BY P1-002/P1-004

### BMI-P1-006 — Manual Match Entry & Verification
Status: BLOCKED BY P1-002/P1-004

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: BLOCKED BY P1-005/P1-006

### BMI-P1-008 — Review Backend Foundation
Status: BLOCKED BY P1-002/P1-004

Scope:
- review case APIs/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- merge/split preview foundation

---

## Phase 2 — First Automated Collection Pipeline

Planned sequence:
- select first permitted source
- implement connector
- raw source item/evidence persistence
- AI structured extraction
- entity matching
- duplicate detection
- verification/review routing
- scheduled daily run
- operator report

## Phase 3 — Multi-Source Expansion

- additional approved connectors
- YouTube metadata/transcripts where permitted
- discovery engine
- multi-source confidence/corroboration
- conflict detection
- daily operations reporting

## Phase 4 — Analytics

- rankings
- head-to-head
- form history
- camp/venue analysis
- historical trends
- natural-language analysis over verified data

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the primary maintainer explicitly coordinates non-overlapping work.

When a task starts:
1. record owner
2. change status to IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside declared scope
5. run required checks/tests
6. submit PR/handoff
