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
Status: IN PROGRESS — PRODUCTION INCREMENTS DEPLOYED
Owner: Primary Maintainer (ChatGPT)
Latest merged work:
- PR #41 — real-bull / sports-intelligence visual-system baseline
- PR #42 — safe verified Bull Profile imagery from `primary_image_ref`

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

Implemented and deployed:
- `docs/VISUAL-SYSTEM.md` reusable image/type/motion rules
- additive `visual-system.css` layer so legacy UI behavior remains reversible
- real licensed bull-fighting atmosphere Hero image; never used as canonical bull identity
- BM typographic brand treatment rather than mascot identity
- scoreboard statistic presentation
- action rails replacing generic quick-card language
- dark sports/broadcast Bull Profile stage
- arena-style Match Detail + animated VS signal
- generic bull portraits removed from bull-specific/participant missing-image states
- explicit `ยังไม่มีภาพยืนยัน` / `NO VERIFIED PHOTO` fallbacks
- `prefers-reduced-motion` and responsive/mobile safeguards
- Bull Profile now renders the existing production `bull.primary_image_ref` only when it resolves to HTTP(S)
- image-load errors fall back safely rather than substituting another bull
- login product mark no longer uses the bull mascot glyph

Validation completed:
- PR #41 Web App CI PASS: typecheck/build + controlled Production API smoke
- PR #41 main GitHub Pages deploy PASS
- PR #42 Web App CI PASS: typecheck/build + controlled Production API smoke
- PR #42 main GitHub Pages deploy PASS
- no production bull/match data fabricated for visual testing
- no Supabase migration/auth/API mutation introduced by PR #41 or #42

Known limitation:
- Production currently has no real Bull/Match rows, so verified bull photo rendering cannot be end-to-end visually demonstrated without fabricating data; do not add fake records just for screenshots.
- Match participant API currently has no participant-specific verified image reference. Match Detail must keep explicit no-photo placeholders until that contract exists.
- Dashboard atmosphere currently hotlinks a CC0 Wikimedia thumbnail; long-term approved assets should move to BullMatch-controlled storage.

Exact next APP-004 work:
1. define a participant-image read contract that exposes only verified/public image references without leaking private evidence
2. add reusable evidence-strength / data-confidence visual primitives for future intelligence surfaces
3. use those primitives on current verified/published data surfaces where meaningful
4. refine React-level loading/reveal transitions only where CSS-only motion is insufficient
5. perform browser/mobile visual verification when a supported browser-testing path is available; do not create fake production records
6. keep Matchup Intelligence visual language ready for Phase 4 analytics rather than inventing prediction data now

Allowed files/areas:
- `apps/web/src/`
- `apps/web/public/` for documented visual assets/attribution
- controlled API read model only when required for verified public imagery
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

1. BMI-APP-004 — finish visual-system implementation gates above
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