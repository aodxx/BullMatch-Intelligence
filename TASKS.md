# Task Registry

This file defines the initial backlog. GitHub Issues are used for execution tracking; this file remains the high-level project map.

## Phase 0 — Foundation & Architecture

### BMI-P0-001 — Repository & Collaboration Foundation
Owner: Primary Maintainer
Status: DONE

Deliverables completed:
- repository structure
- multi-agent rules
- task/branch conventions
- issue and PR templates
- shared project status
- Drive handoff folder

### BMI-P0-002 — Database Schema v0.1
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #1 / PR #5

Deliverables completed:
- canonical entities and relationships
- public/private trust boundary
- source/evidence tables
- claim-level provenance
- review/audit tables
- historical match snapshots
- result model without cyclic winner FK
- source idempotency strategy
- indexes and uniqueness strategy
- RLS/Data API assumptions
- archive/retention policy
- merge/split identity history
- Supabase migration plan

No production migration has been applied yet.

### BMI-P0-003 — AI Agent & Verification Specification
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #2 / PR #6

Deliverables completed:
- Source Discovery Agent contract
- normalized Source Monitoring / ingestion envelope
- atomic Extraction Result contract
- Entity Match Result contract
- Duplicate Detection Result contract
- Verification Result contract
- Review Subject reference contract
- Agent Run + Error contracts
- retry/idempotency/conflict rules
- provider abstraction and prompt-injection boundary
- JSON Schema package with example payloads
- automated contract validation workflow

### BMI-P0-004 — PRD v0.1
Owner: Primary Maintainer
Status: REVIEW

Deliverables drafted:
- product goals
- users and roles
- MVP scope
- core workflows
- functional requirements
- non-functional requirements
- success measures

### BMI-P0-005 — Architecture v0.1
Owner: Primary Maintainer
Status: REVIEW

Deliverables drafted:
- component boundaries
- data flow
- trust boundaries
- scheduler strategy
- storage strategy
- API boundaries
- deployment approach

### BMI-P0-006 — Source Registry & Connector Contract
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #7 / PR #8

Deliverables completed:
- source registry schema and policy/health separation
- connector interface and shared poll request/result contracts
- source policy/access metadata
- polling schedule and cursor model
- transactional cursor commit rule
- rate-limit/backoff metadata
- source health states
- secret requirement boundary
- deterministic connector-owned dedupe strategy
- operator-upload and search-discovery boundaries
- source runtime-state database addition plan
- first connector selection/readiness checklist
- source registry example fixture and contract validation coverage

### BMI-P0-007 — Entity Resolution Strategy
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #3 / PR #9

Deliverables completed:
- Thai-safe normalization rules
- candidate generation and bounded top-N strategy
- positive/negative/hard-conflict signal model
- entity-specific context rules
- conservative auto-link/review/no-match policy
- candidate margin and independent-signal requirements
- stable source-native mapping strategy
- alias lifecycle guidance
- human-controlled reversible merge/split strategy
- reviewer UX requirements
- calibration/evaluation metrics and golden fixture plan
- machine-readable entity-resolution policy schema + fixture
- contract validation coverage

### BMI-P0-008 — Review Queue UX Specification
Owner: Primary Maintainer
Status: IN PROGRESS
Tracking: Issue #4

Deliverables:
- review information architecture and queue filters
- new match/entity review
- entity-match review
- possible duplicate review
- conflict review
- evidence viewer requirements
- approve/reject/edit/link/create actions
- merge/split destructive workflows
- optimistic concurrency/idempotent command rules
- audit/history requirements
- accessibility and mobile-review requirements

## Phase 1 — Core Verified Database

Planned after Phase 0:

- BMI-P1-001 Supabase project/bootstrap
- BMI-P1-002 Database migrations
- BMI-P1-003 Seed/reference data
- BMI-P1-004 Admin authentication and roles
- BMI-P1-005 Bull/camp/venue CRUD
- BMI-P1-006 Match entry and result workflow
- BMI-P1-007 Bull profile and basic statistics

## Phase 2 — First Automated Collection Pipeline

Planned after verified manual workflow works:

- first permitted web/RSS connector
- raw source-item ingestion
- AI structured extraction
- candidate entity matching
- duplicate detection
- review queue integration
- scheduled daily runs

## Phase 3 — Multi-Source Expansion

- YouTube metadata/transcript connector where permitted
- additional official/public source connectors
- discovery engine
- multi-source confidence model
- conflict detection
- daily operator report

## Phase 4 — Analytics

- rankings
- head-to-head
- form history
- camp/venue analysis
- historical trends
- natural-language analytics over verified data

## Assignment Rule

A contributor may claim only one READY task at a time unless the primary maintainer explicitly coordinates multiple non-overlapping tasks.

When a task starts:
1. assign/record owner
2. change status to IN PROGRESS
3. create `agent/<task-id>-...` branch
4. keep changes inside declared scope
5. submit handoff/PR
