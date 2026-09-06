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

Completed:
- 15 `bullmatch` tables
- 17 `bullmatch_private` tables
- canonical/match/review/source/AI/provenance model
- publication/winner/idempotency integrity
- RLS/private isolation
- migration/integration tests

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED YET

Rules:
- do not fabricate bull/match/source records
- add only stable reference/config data when a real implementation dependency exists

### BMI-P1-004 — Admin Authentication & Roles
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #19

Completed:
- `bullmatch.app_users` remains application role source of truth
- active role helper uses `auth.uid()` + `app_users`, not user-editable metadata
- helper is `SECURITY INVOKER`
- authenticated browser grants remain read-only
- ADMIN/REVIEWER canonical + review visibility
- VIEWER verified/published-only visibility
- non-member/suspended users receive no BullMatch role access
- `bullmatch_private` remains unavailable to browser roles
- no self-elevation / no browser role writes
- first-admin bootstrap runbook
- authorization assertions and advisor review
- performance policy WARN findings remediated

Key files:
- `supabase/migrations/20260906054956_add_bullmatch_role_authorization.sql`
- `supabase/migrations/20260906055150_consolidate_bullmatch_read_policies.sql`
- `supabase/tests/p1_004_authorization.sql`
- `supabase/P1-004-VERIFICATION.md`
- `docs/AUTHORIZATION-RUNBOOK.md`

Operational note:
- no real Auth user exists yet, therefore no production ADMIN membership was fabricated

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: READY AFTER P1-004 MERGE

Scope:
- controlled ADMIN domain operations
- create/update/archive owner/camp/bull/venue records
- alias management
- normalization and validation
- audit/provenance hooks where required
- no unrestricted browser table writes

### BMI-P1-006 — Manual Match Entry & Verification
Status: READY AFTER P1-004 MERGE

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: BLOCKED BY P1-005/P1-006

### BMI-P1-008 — Review Backend Foundation
Status: READY AFTER P1-004 MERGE

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
