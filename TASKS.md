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
Status: READY — AUTONOMOUS PRIORITY 1

Dependencies satisfied after:
- BMI-P1-011 DONE — PR #39
- BMI-P1-012 DONE — PR #40
- BMI-APP-004 DONE — PR #41

Target scope:
- review case API/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- claim-level accept/reject/conflict/supersede handling
- contributor/community review context and risk tiers
- claim promotion with provenance/audit
- merge/split preview foundation

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
Status: DONE — PR #41
Owner: Primary Maintainer (ChatGPT)
Branch: `agent/bmi-app-004-visual-rebaseline`

Delivered:
- reusable `visual-system.css` loaded after legacy styles for reversible rollout
- real bull-fighting atmosphere photography in Dashboard hero with documented CC0 source and non-identity usage rule
- typographic BM brand treatment instead of bull mascot identity
- scoreboard-style statistics and action-rail layout instead of repeated generic cards
- sports/broadcast typography, navigation and data-surface language
- Bull Profile identity stage that does not pretend a generic bull icon is the real animal
- Match Detail arena / VS composition without generic bull identity glyphs
- motion grammar for hero, score reveals and matchup presentation
- `prefers-reduced-motion` handling and mobile adaptations
- `docs/VISUAL-SYSTEM.md` defining image, typography, motion and identity rules

Validation:
- Web App workflow run #32 passed
- Typecheck and build passed
- controlled production API smoke test passed
- no API/auth/database logic changed
- no fabricated production bull identity image introduced

Important boundary:
- APP-004 establishes the production visual language and honest no-image states.
- Rendering a canonical bull's real `primary_image_ref` and participant-specific matchup images requires React/API binding work and is tracked separately as BMI-APP-005 rather than being hidden inside this visual-system task.

### BMI-APP-005 — Verified Bull Identity Image Binding
Status: PLANNED — AFTER REVIEW BACKEND OR WHEN UI/API WORK IS NEXT

Scope:
- render `bull.primary_image_ref` safely in Bull Profile when present
- keep explicit `ยังไม่มีภาพยืนยัน` fallback when absent or invalid
- define allowed/signed media URL handling and broken-image behavior
- extend public Match participant view model/API before showing participant-specific matchup images
- never substitute atmosphere photography as canonical bull identity
- verify mobile, accessibility, image loading and performance behavior

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

1. BMI-P1-008 — Review Backend Foundation, re-scoped
2. Community contribution migration/API/UI implementation
3. BMI-APP-005 — Verified Bull Identity Image Binding when UI/API track is active
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
