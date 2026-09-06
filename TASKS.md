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

### BMI-P1-008 — Review Backend Foundation
Status: READY

Scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- merge/split preview foundation

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline & Open Contribution Readiness
Status: REVIEW
Owner: Primary Maintainer (ChatGPT)
Branch: `agent/bmi-p1-009-thai-bullfighting-domain-rebaseline`

Scope:
- research Thai bullfighting as a complete domain before broadening community contribution
- document real-world lifecycle from breeding/acquisition and preparation through comparison day, pairing, program, match, result, recovery and historical record
- document domain vocabulary, bull identity, physical traits, horn/fighting-style terminology, actors, venue/event structure, rule variation, evidence and legal/product boundaries
- identify where the existing generic sports model is too shallow for Thai bullfighting
- define the architecture implications for future open contribution, fact-level verification and provenance
- do not change production schema or API in this task

Deliverables:
- `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`
- `docs/THAI-BULLFIGHTING-FIELD-VALIDATION.md`

Dependencies / integration note:
- findings inform the PRD/schema/review redesign before community write access is implemented
- BMI-P1-008 remains READY but its community-review expansion should follow this domain rebaseline

---

## App / Frontend Track

### BMI-APP-001 — Frontend Foundation & First Screens
Status: DONE — Issue #25 / PR #26
Deployment: GitHub Pages ACTIVE
URL: `https://aodxx.github.io/BullMatch-Intelligence/`

### BMI-APP-002 — Supabase Auth Login UI
Status: DONE — Issue #30 / PR #31

### BMI-APP-003 — Controlled API + Production Data Wiring
Status: DONE — Issue #32 / PR #33
Deployment: GitHub Pages run #26 PASS

Completed:
- migration `20260906092707_add_bullmatch_controlled_api_bridge`
- service-role-only RPC bridge; browser roles have no EXECUTE
- `bullmatch-api` Edge Function v1 ACTIVE
- custom user-token validation for protected routes
- public verified-data routes for Dashboard/Bulls/Bull/Matches/Match/Venues
- `/me` server-owned BullMatch membership and role
- ADMIN dispatcher derives actor from validated Auth user
- database ADMIN checks/audit remain authoritative
- Dashboard/Bulls/Bull Profile/Matches/Match Detail read Production API
- Manual Entry gated by ACTIVE ADMIN
- Review shell gated by ACTIVE ADMIN/REVIEWER
- production API smoke test in GitHub Actions
- no fake production Bull/Match data

Key files:
- `supabase/migrations/20260906092707_add_bullmatch_controlled_api_bridge.sql`
- `supabase/functions/bullmatch-api/index.ts`
- `supabase/tests/app_003_api_bridge.sql`
- `supabase/APP-003-VERIFICATION.md`
- `apps/web/src/api.ts`

---

## Operations

### BMI-OPS-001 — Enable GitHub Pages
Status: DONE — Issue #27

### BMI-OPS-002 — Bootstrap First Production ADMIN
Status: DONE

Verified:
- intended real Supabase Auth user located in project `kaanguobjhlusjvgbowt`
- Auth email is confirmed
- exact Auth UUID linked to `bullmatch.app_users`
- role = `ADMIN`
- status = `ACTIVE`
- `bullmatch_api_member` returns member/ADMIN/ACTIVE
- authenticated role check returns authorized = true
- no password, token, email, or Auth UUID committed to the public repository

Runbook: `docs/FIRST-ADMIN-BOOTSTRAP.md`

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
