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
Status: DONE — PR #16

### BMI-P1-002 — Core Database Migrations
Status: DONE — PR #18

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED YET

Rules:
- do not fabricate Bull/Match/source records
- add only stable reference/config data when a real dependency exists

### BMI-P1-004 — Admin Authentication & Roles
Status: DONE — PR #20

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: DONE — PR #22

### BMI-P1-006 — Manual Match Entry & Verification
Status: DONE — PR #24

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: DONE — PR #29

### BMI-P1-008 — Review Backend Foundation
Status: BLOCKED / RE-SCOPED

Reason:
- original operator-centric review assumptions are too narrow
- implementation must follow Community Data Network + atomic-claim + contributor-trust contracts

Resume after:
- BMI-P1-011 Database Schema v0.2
- BMI-P1-012 Contribution & Trust Architecture

Target scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- claim-level accept/reject/conflict/supersede handling
- contributor/community review context
- merge/split preview foundation

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline
Status: DONE — PR #36

Deliverables:
- `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`
- `docs/THAI-BULLFIGHTING-FIELD-VALIDATION.md`

Result:
- stable bull identity independent of name
- temporal owner/camp/keeper context
- traits/horn/yod/style observations
- comparison day, pairing, program versions, actual match and result as separate domain concepts
- evidence uncertainty and venue/rule variation treated explicitly

### BMI-P1-010 — Product Rebaseline v0.3: Community Big Data + Intelligence
Status: DONE — PR #38

Result:
- Community Data Network / Verified Big Data / Intelligence Products
- atomic claims and evidence-first verification
- contributor value exchange and multidimensional trust
- monetization lanes without bet-taking/wallet/settlement/payout functionality
- real-bull / sports-intelligence / motion design mandate

### BMI-P1-011 — Database Schema v0.2: Community Claims + Temporal Domain
Status: DONE — PR #39
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p1-011-database-schema-v0-2`

Deliverables:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`
- `docs/DATABASE-SCHEMA-NAMESPACE-OVERLAY.md` updated to historical status
- `PROJECT_STATUS.md`
- `TASKS.md`

Result:
- additive/backward-compatible contract over active production schema
- first-class community submissions/evidence origins
- claims generalized beyond AI extraction
- contributor participation separate from privileged app roles
- temporal bull affiliations and relevant people/keeper/handler entities
- real-bull media + private external identifiers
- trait/horn/yod and `ทางชน` observations
- lineage/parentage graph
- first-class comparison session -> pairing -> program version -> actual match lifecycle
- versioned venue/event rule profiles
- multidimensional contributor reputation + profile claims + abuse signals
- controlled promotion/provenance and explicit migration/rollback plan

Validation:
- inspected current production canonical/private migrations and service-only API bridge
- no production migration/API/runtime changes in this contract task
- no production data fabricated
- no secrets introduced
- shared-Supabase isolation preserved

### BMI-P1-012 — Contribution & Trust Architecture
Status: IN PROGRESS
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p1-012-contribution-trust-architecture`

Dependencies satisfied:
- BMI-P1-011 DONE — PR #39

Scope:
- field-friendly community submission flow
- AI-assisted extraction + compact user confirmation
- submission/claim/moderation/review lifecycle
- contributor reputation by topic/venue/region/evidence quality
- owner/camp/venue profile claims without control over canonical adverse history
- anti-spam, duplicate flooding, evidence reuse and abuse controls
- verified-contribution credit model
- `Contribute to Unlock` readiness without rewarding raw submission volume
- contributor self-service API/security boundaries

Expected deliverable:
- `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`
- updates to `PROJECT_STATUS.md` / `TASKS.md`
- no production migrations/API runtime changes in this architecture task

---

## App / Frontend Track

### BMI-APP-001 — Frontend Foundation & First Screens
Status: DONE — PR #26
Deployment: GitHub Pages ACTIVE
URL: `https://aodxx.github.io/BullMatch-Intelligence/`

### BMI-APP-002 — Supabase Auth Login UI
Status: DONE — PR #31

### BMI-APP-003 — Controlled API + Production Data Wiring
Status: DONE — PR #33

Completed:
- service-role-only RPC bridge
- `bullmatch-api` Edge Function ACTIVE
- public verified-data routes
- `/me` server-owned BullMatch membership/role
- ADMIN command bridge with domain-level authorization/audit
- production web app reads production API
- no fake production Bull/Match data

### BMI-APP-004 — Visual Design Rebaseline: Real Bull / Sports Intelligence / Motion
Status: BLOCKED BY EXECUTION ORDER — product dependency satisfied; execute after BMI-P1-012 unless explicitly reprioritized.

Mandate:
- real bull and real venue imagery where rights/source permit
- no cute/cartoon bull identity
- no generic repeated dashboard/card-template language
- high-energy sports-intelligence / broadcast-graphics feel
- real bull identity centered in profile and matchup experiences
- strong typography, statistics, layered imagery and data visualization
- purposeful transitions, stat reveals, matchup motion, timelines and micro-interactions
- reduced-motion and mobile-performance behavior required
- flagship `Matchup Intelligence` visual experience

---

## Operations

### BMI-OPS-001 — Enable GitHub Pages
Status: DONE — Issue #27

### BMI-OPS-002 — Bootstrap First Production ADMIN
Status: DONE

### BMI-OPS-003 — Autonomous Hourly Development Continuity
Status: DONE
Runbook: `docs/AUTO-RUN-RUNBOOK.md`

---

## Phase 2 — First Automated Collection Pipeline

Status: PLANNED — follows stabilization of community/domain/review contracts.

Planned sequence:
- select first permitted source
- implement connector
- raw source/evidence persistence
- extraction
- entity matching
- duplicate detection
- verification/review routing
- scheduled collection
- operator report

## Phase 3 — Multi-Source Expansion

- additional approved connectors
- discovery engine
- multi-source corroboration/conflicts
- daily operations reporting

## Phase 4 — Intelligence Products

- matchup intelligence
- opponent-adjusted form
- shared-opponent/style analysis
- camp/venue analysis
- historical trends
- evidence completeness/confidence
- advanced reports
- API/B2B data surfaces
- natural-language analysis over verified data

## Autonomous Priority Reference

Unless a production/security blocker is more urgent:

1. BMI-P1-012 — Contribution & Trust Architecture
2. BMI-APP-004 — Visual Design Rebaseline
3. BMI-P1-008 — Review Backend Foundation, re-scoped
4. Community contribution migration/API/UI implementation
5. Automated collection pipeline
6. Intelligence products

Canonical autonomous operating instructions: `docs/AUTO-RUN-RUNBOOK.md`.

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the primary maintainer coordinates non-overlapping work.

When a task starts:
1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run relevant checks/tests
6. submit PR/handoff
