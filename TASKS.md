# Task Registry

This file is the high-level project map. GitHub Issues/PRs track execution.

## Phase 0 — Foundation & Architecture — COMPLETE

BMI-P0-001 through BMI-P0-010: **DONE**.

Key tracking:
- Database Schema — Issue #1 / PR #5
- AI Contracts — Issue #2 / PR #6
- Source Registry — Issue #7 / PR #8
- Entity Resolution — Issue #3 / PR #9
- Review Queue UX — Issue #4 / PR #12
- Shared Supabase Tenancy — Issue #10 / PR #11
- Phase 0 Sign-off — Issue #13 / PR #14

---

## Phase 1 — Core Verified Database

### BMI-P1-001 — Shared Supabase Bootstrap
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #15 / PR #16

Completed:
- shared host bootstrap
- `bullmatch` / `bullmatch_private`
- `bullmatch.app_users`
- initial RLS/grant boundary
- isolation tests/advisors

### BMI-P1-002 — Core Database Migrations
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #17

Completed:
- canonical owners/camps/bulls/venues/events + aliases
- match participants/results with historical snapshots
- same-match winner integrity trigger
- verified-only publication guard
- review cases/actions with `case_version` and unique `command_id`
- source registry/runtime/items/evidence
- agent/extraction/candidate/claim/verification layer
- source-native entity mapping
- provenance/identity/audit layer
- private owner details
- RLS enabled on all BullMatch tables
- browser grants withheld from domain/private tables
- source `(source_id,dedupe_key)` idempotency
- missing foreign-key indexes fixed
- integration assertions passed
- production data remains empty

Key files:
- migrations `20260906053239` through `20260906053620`
- `supabase/tests/p1_002_core_integrity.sql`
- `supabase/P1-002-VERIFICATION.md`

### BMI-P1-003 — Seed / Reference Data
Status: READY AFTER P1-002 MERGE

Scope:
- only stable reference/config data needed by MVP
- no fabricated bull/match records
- no production source activation without review

### BMI-P1-004 — Admin Authentication & Roles
Status: READY AFTER P1-002 MERGE

Scope:
- admin/reviewer membership operations
- intentional BullMatch RLS/API policies
- no self-elevation
- server-mediated privileged operations

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: BLOCKED BY P1-004

### BMI-P1-006 — Manual Match Entry & Verification
Status: BLOCKED BY P1-004

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: BLOCKED BY P1-005/P1-006

### BMI-P1-008 — Review Backend Foundation
Status: BLOCKED BY P1-004

Scope:
- review case API/domain operations
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
- multi-source corroboration/conflicts
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
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run checks/tests
6. submit PR/handoff
