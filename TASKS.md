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
Status: DONE — Issue #15 / PR #16

### BMI-P1-002 — Core Database Migrations
Status: DONE — Issue #17 / PR #18

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED YET

Rules:
- do not fabricate Bull/Match/source records
- add only stable reference/config data when a real dependency exists

### BMI-P1-004 — Admin Authentication & Roles
Status: DONE — Issue #19 / PR #20

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: DONE — Issue #21 / PR #22

### BMI-P1-006 — Manual Match Entry & Verification
Status: DONE — Issue #23 / PR #24

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: DONE — Issue #28 / PR #29

Completed:
- verified/published Bull match history
- opponent/H2H-ready history
- W/L/D/NO_RESULT/CANCELLED
- win rate excludes NO_RESULT/CANCELLED
- recent form latest five W/L/D
- historical snapshots preserved
- unverified Bulls excluded

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
Status: DONE — Issue #25 / PR #26
Deployment: GitHub Pages ACTIVE
URL: `https://aodxx.github.io/BullMatch-Intelligence/`

### BMI-APP-002 — Supabase Auth Login UI
Status: DONE — Issue #30 / PR #31

Completed:
- Supabase email/password login for existing accounts
- publishable-key-only Auth client
- session restore/refresh/logout
- public pages remain available signed out
- protected shells require login
- authenticated never implies ADMIN
- no public Sign Up

### BMI-APP-003 — Controlled API + Production Data Wiring
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #32

Completed implementation:
- migration `20260906092707_add_bullmatch_controlled_api_bridge`
- service-role-only RPC bridge; browser roles have no EXECUTE
- `bullmatch-api` Edge Function v1 ACTIVE
- custom user token validation for protected routes
- public verified-data routes for Dashboard/Bulls/Bull/Matches/Match/Venues
- `/me` server-owned BullMatch membership and role
- ADMIN dispatcher derives actor from validated JWT
- database ADMIN checks/audit remain authoritative
- Dashboard/Bulls/Bull Profile/Matches/Match Detail wired to Production API
- Manual Entry gated by ACTIVE ADMIN
- Review shell gated by ACTIVE ADMIN/REVIEWER
- GitHub Actions production API smoke test
- no fake production data

Key files:
- `supabase/migrations/20260906092707_add_bullmatch_controlled_api_bridge.sql`
- `supabase/functions/bullmatch-api/index.ts`
- `supabase/tests/app_003_api_bridge.sql`
- `supabase/APP-003-VERIFICATION.md`
- `apps/web/src/api.ts`

### BMI-OPS-001 — Enable GitHub Pages
Status: DONE — Issue #27

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
