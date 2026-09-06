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
Status: DONE
Tracking: Issue #15 / PR #16

### BMI-P1-002 — Core Database Migrations
Status: DONE
Tracking: Issue #17 / PR #18

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED YET

Rules:
- do not fabricate bull/match/source records
- add only stable reference/config data when a real implementation dependency exists

### BMI-P1-004 — Admin Authentication & Roles
Status: DONE
Tracking: Issue #19 / PR #20

Completed:
- app-scoped ADMIN / REVIEWER / VIEWER authorization
- database-backed active role lookup
- SELECT-only browser grants + RLS
- no self-elevation
- first-admin trusted bootstrap runbook
- authorization tests/advisors

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #21

Completed:
- ADMIN-only Owner create/update
- ADMIN-only Camp create/update
- ADMIN-only Bull create/update
- ADMIN-only Venue create/update
- soft archive for Owner/Camp/Bull/Venue
- explicit entity verification-state command
- alias upsert + alias verification command
- Thai-safe whitespace/case normalization
- allowlisted JSON patch validation
- reference checks for active Owner/Camp links
- every mutation audited in `bullmatch_private.audit_log`
- no direct browser table writes
- rollback-only ADMIN/REVIEWER/VIEWER/non-member integration tests
- no leaked test users/data

Key files:
- `supabase/migrations/20260906055912_add_bullmatch_admin_owner_camp_crud.sql`
- `supabase/migrations/20260906060030_add_bullmatch_admin_bull_venue_alias_crud.sql`
- `supabase/tests/p1_005_domain_crud.sql`
- `supabase/P1-005-VERIFICATION.md`

### BMI-P1-006 — Manual Match Entry & Verification
Status: READY AFTER P1-005 MERGE

Scope:
- controlled ADMIN match/event creation and updates
- participant snapshots
- result entry
- explicit verification and publication transition
- audit every state change
- preserve same-match winner/publication guards
- no unrestricted browser writes

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: BLOCKED BY P1-006

### BMI-P1-008 — Review Backend Foundation
Status: READY

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
