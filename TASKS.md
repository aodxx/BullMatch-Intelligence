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

### BMI-P1-006 — Manual Match Entry & Verification
Status: DONE
Tracking: Issue #23 / PR #24

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: DONE
Tracking: Issue #28 / PR #29

Completed:
- verified/published Bull match-history read model
- normalized opponent history for future H2H
- published/statistical match counts
- W/L/D/NO_RESULT/CANCELLED counts
- win rate excludes NO_RESULT/CANCELLED
- recent form latest five W/L/D only
- historical participant snapshots preserved
- unverified Bulls excluded
- service-role-only read access for current API boundary
- rollback-only regression test on shared Supabase
- no leaked fixture data

Key files:
- `supabase/migrations/20260906084340_add_bullmatch_verified_profile_statistics.sql`
- `supabase/tests/p1_007_bull_stats.sql`
- `supabase/P1-007-VERIFICATION.md`

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
Status: DONE
Tracking: Issue #25 / PR #26
Deployment: GitHub Pages ACTIVE
URL: `https://aodxx.github.io/BullMatch-Intelligence/`

### BMI-APP-002 — Supabase Auth Login UI
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #30

Completed:
- Supabase email/password login for existing accounts
- publishable-key-only browser Auth client
- session persistence, validation and refresh
- local logout
- public Dashboard/Bulls/Matches remain accessible signed out
- Manual Entry/Review Queue require authentication
- intended protected route resumes after sign-in
- no public sign-up UI
- authenticated user is never assumed to be ADMIN
- BullMatch role resolution deferred to APP-003 controlled API
- no service-role/secret key in frontend
- production TypeScript/Vite build passes

### BMI-APP-003 — Wire Domain Data & Admin Actions
Status: BLOCKED BY APP-002 MERGE + API BOUNDARY IMPLEMENTATION

### BMI-OPS-001 — Enable GitHub Pages
Status: DONE
Tracking: Issue #27

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
