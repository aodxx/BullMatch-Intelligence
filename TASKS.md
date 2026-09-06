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
Status: IN PROGRESS
Owner: Primary Maintainer (ChatGPT autonomous run)
Current branch: `agent/bmi-p1-008-guarded-create-entity`

Dependencies satisfied:
- BMI-P1-011 DONE — PR #39
- BMI-P1-012 DONE — PR #40
- BMI-APP-004 implementation gate DONE — PR #41, #42, #46, #47, #48

Completed/deployed slices:

**Review foundation — PR #50 / migration `20260906211732_add_bullmatch_review_backend_foundation`**
- controlled REVIEWER/ADMIN queue + detail API
- controlled evidence access
- idempotent review commands + optimistic case version
- claim VERIFIED/REJECTED/CONFLICT/SUPERSEDED decisions
- append-only review action + private audit
- MERGE/SPLIT execution blocked

**Bull identity impact preview — PR #51 / migration `20260906212825_add_bullmatch_identity_impact_preview`**
- deterministic read-only MERGE/SPLIT preview
- same-match distinct-Bull hard-conflict detection
- deterministic fingerprint
- execution disabled
- name similarity is not merge authority

**Guarded VERIFIED claim promotion — PR #52 / migration `20260906214802_add_bullmatch_verified_claim_promotion`**
- ADMIN-only canonical promotion separate from claim APPROVE
- evidence-backed EXPLICIT VERIFIED Bull claims only
- first allowlist: `home_province`, `home_district`, `color_description`, `breed_description`
- identity/name/alias, affiliation, lineage, media, lifecycle, match history/results and merge/split excluded
- provenance + review action + audit + idempotency

**Reviewed entity/duplicate decisions — PR #53 / migration `20260906215917_add_bullmatch_reviewed_entity_decisions` / Edge v10**
- `LINK_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE`
- ACTIVE ADMIN/REVIEWER authorization
- command-id idempotency + optimistic case version
- verified/nonarchived link targets
- Bull non-name-only identity basis; `NAME_ONLY` blocked
- duplicate decisions do not merge canonical entities
- `canonical_mutation: false`
- verification: `supabase/P1-008-ENTITY-DECISIONS-VERIFICATION.md`

**Guarded reviewed Bull CREATE_ENTITY — current PR / migration `20260906224832_add_bullmatch_guarded_review_create_entity` / Edge v11**
- policy `BMI-P1-008-BULL-CREATE-V1`
- ACTIVE ADMIN only
- Bull `NEW_ENTITY_CANDIDATE` attached to an OPEN/IN_REVIEW NEW_ENTITY or ENTITY_MATCH case
- completed candidate search + duplicate search + search policy version required
- strong creation basis required; `NAME_ONLY` blocked
- unresolved/confirmed duplicate candidate blocks creation
- confirmed Bull link in candidate group blocks creation
- active same-normalized-name Bull blocks creation conservatively
- successful path creates only canonical name and leaves Bull `UNVERIFIED`
- no owner/camp/lineage/media/descriptive/match fields written
- candidate links to new Bull
- one review-case version increment, one CREATE_ENTITY review action, private audit + existing Bull-created audit
- idempotent replay returns same Bull
- rollback-only Production regression passed with zero retained fixtures
- migration filename reconciled to Production version
- verification: `supabase/P1-008-GUARDED-CREATE-ENTITY-VERIFICATION.md`

Remaining BMI-P1-008 scope:
- selected EDIT semantics that cannot bypass claim verification/promotion
- production Review Queue UI wiring
- destructive merge/split only in a later separately confirmed slice

Required invariants:
- canonical history remains closed to direct community writes
- claim verification and canonical promotion remain separate
- UNVERIFIED entity creation is not publication/verification
- ACTIVE ADMIN/REVIEWER authorization is server/database enforced; CREATE_ENTITY and canonical promotion are ADMIN-only under current policy
- review operations are idempotent and concurrency-safe
- evidence/provenance/audit are preserved
- no majority-vote canonical truth
- name similarity alone never proves Bull identity
- unresolved/conflicted claims are not published
- no betting/wallet/settlement/payout capability

Exact next BMI-P1-008 implementation slice after the current CREATE_ENTITY PR merges:
1. selected `EDIT` semantics only where they cannot bypass atomic-claim verification or canonical-promotion policy
2. production Review Queue UI wiring
3. separately designed destructive merge/split only after fingerprint-bound reassignment/provenance safeguards

Do not implement a broad generic EDIT over Bull identity, name/aliases, lineage, owner/camp affiliation, media or match history.

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline
Status: DONE — PR #36

### BMI-P1-010 — Product Rebaseline v0.3
Status: DONE — PR #38

### BMI-P1-011 — Database Schema v0.2
Status: DONE — PR #39

Deliverables:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`

### BMI-P1-012 — Contribution & Trust Architecture
Status: DONE — PR #40

Deliverable:
- `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`

Core contract:
- mobile/field-friendly contribution entry points
- AI as form assistant, never auto-publisher
- atomic claims and identity/duplicate safeguards
- evidence quality separate from contributor reputation
- community review risk tiers; no majority-vote truth
- Data Credit is not money/betting value

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

### BMI-APP-004 — Visual Design Rebaseline
Status: DONE — IMPLEMENTATION GATE COMPLETE
Merged increments: PR #41, #42, #46, #47, #48

Delivered real-bull/sports-intelligence visual system, safe verified imagery, explicit no-image fallback, Data Coverage/Trust Signals, reduced motion/mobile protection and no betting/payout UI.

Deferred non-blocking QA: run real-data visual verification when genuine canonical records exist; never fabricate them for screenshots.

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
Status: PLANNED — follows community/review stabilization.

## Phase 3 — Multi-Source Expansion
Status: PLANNED

## Phase 4 — Intelligence Products
Status: PLANNED

Includes Matchup Intelligence, opponent-adjusted form, shared-opponent/style analysis, camp/venue analysis, evidence completeness/confidence, advanced reports and API/B2B surfaces.

## Autonomous Priority Reference

1. **BMI-P1-008 — Review Backend Foundation**
2. Community contribution migration/API/UI
3. Automated collection pipeline
4. Intelligence products
5. deferred APP-004 real-data visual QA

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
