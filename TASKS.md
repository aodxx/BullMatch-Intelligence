# Task Registry

This file is the high-level project map. GitHub Issues/PRs track execution.

## Phase 0 — Foundation & Architecture — COMPLETE

BMI-P0-001 through BMI-P0-010: **DONE**.

---

## Phase 1 — Core Verified Database / Community Rebaseline

### BMI-P1-001 — Shared Supabase Bootstrap
Status: DONE — PR #16

### BMI-P1-002 — Core Database Migrations
Status: DONE — PR #18

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED YET

### BMI-P1-004 — Admin Authentication & Roles
Status: DONE — PR #20

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: DONE — PR #22

### BMI-P1-006 — Manual Match Entry & Verification
Status: DONE — PR #24

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: DONE — PR #29

### BMI-P1-008 — Review Backend Foundation
Status: READY — RE-SCOPED AGAINST COMMUNITY CONTRACTS

Dependencies satisfied after:
- BMI-P1-011 DONE — PR #39
- BMI-P1-012 DONE — PR #40

Target scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- claim-level accept/reject/conflict/supersede handling
- contributor/community review context and risk tiers
- claim promotion with provenance/audit
- merge/split preview foundation

Execution order: after BMI-APP-004 unless a backend integrity/security need makes P1-008 more urgent.

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline
Status: DONE — PR #36

### BMI-P1-010 — Product Rebaseline v0.3
Status: DONE — PR #38

### BMI-P1-011 — Database Schema v0.2
Status: DONE — PR #39

Key deliverables:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`
- additive community/temporal/trust schema contract

### BMI-P1-012 — Contribution & Trust Architecture
Status: DONE — PR #40
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p1-012-contribution-trust-architecture`

Deliverable:
- `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`

Result:
- mobile/field-friendly contribution entry points for program/result/bull/comparison/correction/link inputs
- AI used as form assistant with compact human confirmation
- explicit submission + atomic claim state machines
- identity/duplicate safeguards before new bull creation
- evidence-quality model separate from contributor reputation
- reputation scoped by topic/venue/region and derived from verified outcomes
- contributor feedback/public-profile boundaries
- owner/camp/venue representation claims with restricted rights
- venue data-partner workflow
- anti-spam, duplicate flooding, evidence reuse and coordinated-manipulation signals
- community review risk tiers; no majority-vote canonical truth
- review queue routing factors
- Data Credit / Contribute-to-Unlock boundaries without raw-volume rewards
- contributor API/security/privacy boundaries
- success metrics, failure modes and implementation sequence

Validation:
- architecture/documentation only
- no production migration/API/runtime changes
- no secrets or fabricated production data
- canonical history remains closed to direct community writes
- Data Credit is not money, a betting wallet or transferable gambling value

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

### BMI-APP-004 — Visual Design Rebaseline: Real Bull / Sports Intelligence / Motion
Status: IN PROGRESS
Owner: Primary Maintainer (ChatGPT)
Branch: `agent/bmi-app-004-visual-rebaseline`

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

Expected outcome:
- reusable visual system rules
- motion language
- image-treatment rules
- typography/data-visualization grammar
- implemented production-facing components, not mockups only

Allowed files/areas:
- `apps/web/src/`
- `apps/web/public/` for documented visual assets/attribution
- `docs/` visual-system documentation
- `TASKS.md`
- `PROJECT_STATUS.md`

---

## Operations

### BMI-OPS-001 — Enable GitHub Pages
Status: DONE

### BMI-OPS-002 — Bootstrap First Production ADMIN
Status: DONE

### BMI-OPS-003 — Autonomous Development Continuity
Status: DONE
Runbook: `docs/AUTO-RUN-RUNBOOK.md`

---

## Phase 2 — First Automated Collection Pipeline

Status: PLANNED — follows community/review implementation stabilization.

## Phase 3 — Multi-Source Expansion

Status: PLANNED

## Phase 4 — Intelligence Products

Status: PLANNED

Includes:
- Matchup Intelligence
- opponent-adjusted form
- shared-opponent/style analysis
- camp/venue analysis
- evidence completeness/confidence
- advanced reports
- API/B2B data surfaces

## Autonomous Priority Reference

Unless a production/security blocker is more urgent:

1. BMI-APP-004 — Visual Design Rebaseline
2. BMI-P1-008 — Review Backend Foundation, re-scoped
3. Community contribution migration/API/UI implementation
4. Automated collection pipeline
5. Intelligence products

Canonical autonomous instructions: `docs/AUTO-RUN-RUNBOOK.md`.

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the primary maintainer coordinates non-overlapping work.

When a task starts:
1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run relevant checks/tests
6. submit PR/handoff
