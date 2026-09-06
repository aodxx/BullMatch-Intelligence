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

## Phase 1 — Core Verified Database / Community Rebaseline

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
Status: BLOCKED / RE-SCOPED

Reason:
- the original operator-centric review assumptions are now too narrow
- implementation must follow the Community Data Network + atomic-claim + contributor-trust redesign

Resume after:
- BMI-P1-010 Product Rebaseline v0.3
- BMI-P1-011 Database Schema v0.2
- BMI-P1-012 Contribution & Trust Architecture

Target scope when resumed:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- claim-level accept/reject/conflict handling
- contributor/community review context
- merge/split preview foundation

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline & Open Contribution Readiness
Status: DONE — PR #36
Owner: Primary Maintainer (ChatGPT)
Branch: `agent/bmi-p1-009-thai-bullfighting-domain-rebaseline`

Deliverables:
- `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`
- `docs/THAI-BULLFIGHTING-FIELD-VALIDATION.md`

Result:
- BullMatch is no longer modeled as only bull + match + winner
- bull identity, temporal affiliations, comparison day, pairing, program versions, result reasons, local terminology and evidence uncertainty are first-class product concerns

### BMI-P1-010 — Product Rebaseline v0.3: Community Big Data + Intelligence
Status: DONE — PR #38
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p1-010-product-rebaseline-v0-3`

Result:
- PRD v0.3 defines the three-layer product model: Community Data Network / Verified BullMatch Big Data / Intelligence Products
- incorporates Thai bullfighting temporal/domain lifecycle and evidence-first atomic claims
- defines contributor value exchange, multidimensional trust and `Contribute to Unlock` readiness
- defines monetization lanes: Pro, reports, API, venue/camp/media tools and compatible sponsorship
- preserves legal/product boundary: analytics/data platform, not bet-taking/wallet/settlement/payout service
- defines Matchup Intelligence as explainable, evidence-aware analytics rather than guaranteed picks
- makes real-bull / real-venue sports-intelligence imagery and purposeful motion a product requirement
- defines BMI-P1-011 as the next additive schema contract

Files:
- `PRD.md`
- `PROJECT_STATUS.md`
- `TASKS.md`

Validation:
- documentation/product-contract only; no migration/API/runtime code changed
- no production data fabricated
- no secrets/personal credentials introduced
- checked against `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md` and autonomous runbook

### BMI-P1-011 — Database Schema v0.2: Community Claims + Temporal Domain
Status: IN PROGRESS
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p1-011-database-schema-v0-2`

Dependencies satisfied:
- BMI-P1-009 DONE
- BMI-P1-010 DONE

Scope:
- additive schema plan for community submissions
- atomic claims and claim evidence
- temporal bull affiliations
- physical/style observations
- lineage claims
- comparison sessions / pairing agreements / program versions
- contributor reputation dimensions
- anti-duplication / identity resolution compatibility
- migration and backward-compatibility plan for current production schema

Files/areas:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-NAMESPACE-OVERLAY.md`
- `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md` (reference only unless a correction is required)
- `supabase/migrations/` (inspection only in this contract-design task; no production migration unless separately justified)
- `TASKS.md`
- `PROJECT_STATUS.md`

No destructive rewrite of working production data without explicit migration/rollback design.

### BMI-P1-012 — Contribution & Trust Architecture
Status: BLOCKED — depends on BMI-P1-011
Autonomous priority after P1-011.

Scope:
- community submission flow
- AI-assisted contribution from photos/programs/links/text
- moderation and review lifecycle
- contributor reputation by topic/venue/region/evidence quality
- owner/camp profile claims without control over canonical adverse history
- anti-spam, abuse and duplicate-submission controls
- verified-contribution credit model
- `Contribute to Unlock` readiness

---

## App / Frontend Track

### BMI-APP-001 — Frontend Foundation & First Screens
Status: DONE — Issue #25 / PR #26
Deployment: GitHub Pages ACTIVE
URL: `https://aodxx.github.io/BullMatch-Intelligence/`

### BMI-APP-002 — Supabase Auth Login UI
Status: DONE — PR #31

### BMI-APP-003 — Controlled API + Production Data Wiring
Status: DONE — PR #33
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

### BMI-APP-004 — Visual Design Rebaseline: Real Bull / Sports Intelligence / Motion
Status: BLOCKED — product requirement dependency BMI-P1-010 is satisfied; execution order remains after BMI-P1-012 unless independent design-system work is explicitly prioritized.

Mandate:
- real bull and real venue imagery where rights/source permit
- no cute/cartoon bull identity
- no generic repeated dashboard/card template language
- high-energy sports-intelligence / broadcast-graphics feel
- real bull identity centered in profile and matchup experiences
- strong typography, statistics, layered imagery and data visualization
- purposeful transitions, stat reveals, matchup motion, timelines and micro-interactions
- reduced-motion and mobile-performance behavior required
- flagship `Matchup Intelligence` visual experience

Deliverables should include reusable visual system rules, motion language, image treatment, typography hierarchy and implemented production-facing components rather than mockups only.

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

### BMI-OPS-003 — Autonomous Hourly Development Continuity
Status: DONE

Purpose:
- allow scheduled runs to continue normal BullMatch development without requiring the owner to repeatedly type “continue”
- make GitHub the durable source of next-step context instead of relying on chat memory alone

Runbook:
- `docs/AUTO-RUN-RUNBOOK.md`

Rules:
- autonomous runs read repository state before work
- follow explicit priority order in the runbook
- preserve Task ID/branch/test/handoff discipline
- record blockers precisely and move to another safe task when possible
- do not repeat the same unresolved external blocker every run

---

## Phase 2 — First Automated Collection Pipeline

Status: PLANNED — follows stabilization of the community/domain contracts.

Planned sequence:
- select first permitted source
- implement connector
- raw source item/evidence persistence
- AI structured extraction
- entity matching
- duplicate detection
- verification/review routing
- scheduled collection run
- operator report

## Phase 3 — Multi-Source Expansion

- additional approved connectors
- YouTube metadata/transcripts where permitted
- discovery engine
- multi-source corroboration/conflicts
- daily operations reporting

## Phase 4 — Intelligence Products

- matchup intelligence
- rankings and opponent-adjusted form
- head-to-head / style-observation analysis
- camp/venue analysis
- historical trends
- evidence completeness/confidence
- advanced reports
- API and B2B data surfaces
- natural-language analysis over verified data

## Autonomous Priority Reference

Unless a production/security blocker is more urgent, use:

1. BMI-P1-011 — Database Schema v0.2
2. BMI-P1-012 — Contribution & Trust Architecture
3. BMI-APP-004 — Visual Design Rebaseline
4. BMI-P1-008 — Review Backend Foundation, re-scoped
5. Community contribution implementation
6. Automated collection pipeline
7. Intelligence products

Canonical autonomous operating instructions: `docs/AUTO-RUN-RUNBOOK.md`.

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the primary maintainer explicitly coordinates non-overlapping work.

When a task starts:
1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run checks/tests
6. submit PR/handoff
