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
Status: READY — HIGHEST PRIORITY NEXT TASK

Dependencies satisfied:
- BMI-P1-011 DONE — PR #39
- BMI-P1-012 DONE — PR #40
- BMI-APP-004 implementation gate DONE — PR #41, #42, #46, #47, #48

Target scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- controlled reviewer evidence access
- atomic claim accept/reject/conflict/supersede handling
- contributor/community review context and risk tiers
- claim promotion with provenance/audit
- merge/split preview foundation

Required invariants:
- canonical history remains closed to direct community writes
- ACTIVE ADMIN/REVIEWER authorization is enforced server-side/database-side
- review operations are idempotent and concurrency-safe
- evidence/provenance/audit are preserved
- no majority-vote canonical truth
- no betting/wallet/settlement/payout capability

Exact next branch: `agent/bmi-p1-008-...`

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

Deliverable:
- `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`

Key contract:
- mobile/field-friendly contribution entry points
- AI as form assistant, never auto-publisher
- submission and atomic-claim state machines
- identity/duplicate safeguards before new bull creation
- evidence quality separated from contributor reputation
- reputation scoped by topic/venue/region and derived from verified outcomes
- contributor feedback/public-profile boundaries
- owner/camp/venue representation claims with restricted rights
- venue data-partner workflow
- anti-spam / duplicate / coordinated-manipulation signals
- community review risk tiers; no majority-vote truth
- Data Credit only for verified useful outcomes; not money or betting value

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
Status: DONE — IMPLEMENTATION GATE COMPLETE
Owner: Primary Maintainer (ChatGPT)

Merged production increments:
- PR #41 — sports-intelligence visual-system baseline
- PR #42 — safe canonical Bull Profile imagery
- PR #46 — verified/public Match participant image contract + migration reconciliation
- PR #47 — verified participant imagery in Match Detail
- PR #48 — evidence-aware Data Coverage / Trust Signals

Delivered:
- reusable `docs/VISUAL-SYSTEM.md`
- real licensed atmosphere imagery used only as atmosphere
- no cartoon/cute bull identity
- BM product mark rather than mascot branding
- scoreboard statistics / action rails / arena VS composition
- safe HTTP(S)-only `VerifiedBullImage`
- explicit no-verified-image fallbacks; never substitute another bull
- participant-specific canonical images via the service-only public read bridge
- reduced-motion + mobile responsive safeguards
- reusable Data Coverage rail based only on actual VERIFIED/PUBLISHED/sample/image state
- no fabricated prediction confidence, odds, wallet or payout UI

Validation:
- relevant PR typecheck/build PASS
- controlled Production API smoke PASS
- production-facing merged UI increments GitHub Pages deploy PASS
- participant-image RPC ACL/security boundary directly verified
- Supabase security/performance advisors run; no participant-image-specific security exposure found
- no fake Production Bull/Match data introduced

Deferred QA — NOT A BLOCKER:
- Production currently has no real VERIFIED/PUBLISHED Bull/Match rows, so canonical real-image states cannot yet be visually demonstrated end-to-end.
- current execution environment has no supported automated browser path for GitHub Pages screenshot inspection.
- when real canonical data exists, run non-mutating mobile/desktop visual QA; never create fake records only for screenshots.

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

1. **BMI-P1-008 — Review Backend Foundation**
2. Community contribution migration/API/UI implementation
3. Automated collection pipeline
4. Intelligence products
5. deferred APP-004 real-data visual QA when canonical data exists

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
