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

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: DONE
Tracking: Issue #21 / PR #22

Completed:
- ADMIN-only Owner/Camp/Bull/Venue controlled CRUD
- soft archive and explicit verification
- alias management
- Thai-safe normalization
- audit trail
- zero direct browser table writes
- remote rollback-only security tests

### BMI-P1-006 — Manual Match Entry & Verification
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #23

Completed:
- Event create/update/verify/archive
- Match create/update/archive
- event/venue consistency
- participant add/update/remove
- match-time historical snapshots
- result entry and deterministic participant result synchronization
- explicit match verification
- explicit publish/unpublish
- publication hardening: verified known result + >=2 participants + verified result + synchronized participant states
- published facts cannot be edited until unpublish
- factual participant edits invalidate prior verification
- same-match winner guard preserved
- rollback-only ADMIN/REVIEWER/VIEWER/non-member tests
- no leaked test data

Key files:
- `supabase/migrations/20260906061040_add_bullmatch_admin_event_match_crud.sql`
- `supabase/migrations/20260906062919_add_bullmatch_manual_participant_result_workflow.sql`
- `supabase/tests/p1_006_manual_match.sql`
- `supabase/P1-006-VERIFICATION.md`

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: READY AFTER P1-006 MERGE

Scope:
- published/verified match history by Bull
- matches / wins / losses / draws / no-result counts
- win rate with explicit denominator rule
- recent form
- head-to-head-ready query foundation
- no unverified/private facts in public statistics

### BMI-P1-008 — Review Backend Foundation
Status: READY

Scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- merge/split preview foundation

---

## App / Frontend Track

### BMI-APP-001 — Frontend Foundation & First Screens
Status: READY AFTER P1-006 MERGE

Scope:
- mobile-first application shell
- Dashboard
- Bulls list/profile shell
- Matches list/detail shell
- Admin manual-entry shell
- Review Queue shell
- responsive navigation
- empty/loading/error states
- no fake production data
- secure API boundary; do not expose BullMatch mutation functions directly

### BMI-APP-002 — Supabase Auth Login UI
Status: BLOCKED BY APP-001

### BMI-APP-003 — Wire Domain Data & Admin Actions
Status: BLOCKED BY APP-001 + API BOUNDARY DECISION

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
