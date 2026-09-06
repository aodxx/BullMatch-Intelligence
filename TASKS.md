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
Owner: Unassigned
Status: READY
Tracking: Issue #1

Deliverables:
- entities and relationships
- source/evidence tables
- review/audit tables
- historical match snapshots
- indexes and uniqueness strategy
- initial Supabase migration plan

Must not implement production migrations before schema review.

### BMI-P0-003 — AI Agent & Verification Specification
Owner: Unassigned
Status: READY
Tracking: Issue #2

Deliverables:
- Source Discovery Agent contract
- Source Monitoring Agent contract
- Extraction Agent contract
- Entity Resolution Agent contract
- Duplicate Detection Agent contract
- Verification Agent contract
- Report Agent contract
- retry/idempotency/error handling model

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
Owner: Unassigned
Status: BLOCKED
Depends on: BMI-P0-002, BMI-P0-003

Deliverables:
- source registry schema
- connector interface
- source policy/access metadata
- polling schedule model
- rate-limit metadata

### BMI-P0-007 — Entity Resolution Strategy
Owner: Unassigned
Status: READY
Tracking: Issue #3

Deliverables:
- bull identity candidate scoring
- aliases
- camp/owner/venue disambiguation
- auto-match thresholds
- human review thresholds
- merge/split audit strategy

### BMI-P0-008 — Review Queue UX Specification
Owner: Unassigned
Status: READY
Tracking: Issue #4

Deliverables:
- new match review
- possible duplicate review
- possible same-bull review
- conflict review
- evidence viewer requirements
- approve/reject/edit/merge flows

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
