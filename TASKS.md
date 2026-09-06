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
Status: DONE — IMPLEMENTATION GATE COMPLETE
Merged/deployed slices: PR #50, #51, #52, #53, #54, #55, #56

Delivered:

**Review foundation — PR #50 / migration `20260906211732_add_bullmatch_review_backend_foundation`**
- controlled REVIEWER/ADMIN queue + detail API
- controlled evidence access with access-class redaction
- idempotent review commands + optimistic case version
- claim VERIFIED/REJECTED/CONFLICT/SUPERSEDED decisions
- append-only review actions + private audit

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

**Reviewed entity/duplicate decisions — PR #53 / migration `20260906215917_add_bullmatch_reviewed_entity_decisions`**
- `LINK_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE`
- ACTIVE ADMIN/REVIEWER authorization
- command-id idempotency + optimistic case version
- verified/nonarchived link targets
- Bull non-name-only identity basis; `NAME_ONLY` blocked
- duplicate decisions do not merge canonical entities
- `canonical_mutation: false`

**Guarded reviewed Bull CREATE_ENTITY — PR #54 / migration `20260906224832_add_bullmatch_guarded_review_create_entity`**
- policy `BMI-P1-008-BULL-CREATE-V1`
- ACTIVE ADMIN only
- completed candidate search + duplicate search + search policy version required
- strong creation basis required; `NAME_ONLY` blocked
- unresolved/confirmed duplicate candidate blocks creation
- active same-normalized-name Bull blocks creation conservatively
- successful path creates canonical name only and leaves Bull `UNVERIFIED`
- no owner/camp/lineage/media/descriptive/match fields written
- idempotent replay + audit/provenance safeguards

**Production Review Queue UI — PR #55**
- authenticated reviewer control room wired to existing Production review APIs
- queue, case detail, atomic claims, evidence, candidate signals and append-only audit history
- CLAIM / UNCLAIM / COMMENT / APPROVE / REJECT controls use fresh command IDs and optimistic case status/version
- APPROVE is clearly separated from canonical promotion
- read-only MERGE/SPLIT impact preview; no destructive identity controls
- responsive sports-intelligence UI and valid empty-Production state without fabricated fixtures
- Web CI + controlled Production API smoke + GitHub Pages deployment passed

**Safe review metadata EDIT — PR #56 / migration `20260906225757_add_bullmatch_review_metadata_edit` / Edge v12**
- policy `BMI-P1-008-REVIEW-METADATA-EDIT-V1`
- only `priority` and `summary` review-routing metadata are editable
- subject/claim/evidence/canonical fields cannot be changed through EDIT
- idempotent command + optimistic case version + reviewer note
- `canonical_mutation: false`
- rollback-only Production regression and security review passed

Required invariants preserved:
- canonical history remains closed to direct community writes
- claim verification and canonical promotion remain separate
- UNVERIFIED entity creation is not publication/verification
- ACTIVE ADMIN/REVIEWER authorization is server/database enforced
- review operations are idempotent and concurrency-safe
- evidence/provenance/audit are preserved
- no majority-vote canonical truth
- name similarity alone never proves Bull identity
- unresolved/conflicted claims are not published
- no betting/wallet/settlement/payout capability

Explicitly deferred outside the BMI-P1-008 implementation gate:
- destructive Bull identity MERGE/SPLIT execution; future work must require an unchanged impact-preview fingerprint plus explicit reassignment/provenance safeguards
- broad/high-risk canonical EDIT or promotion for Bull identity/name/aliases, owner/camp affiliations, lineage, media and match history
- distinct-Bull same-name creation escalation policy

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

### BMI-P1-013 — Community Contribution Intake Foundation
Status: IN PROGRESS
Owner: Primary Maintainer (ChatGPT autonomous run)
Current branch: `agent/bmi-p1-013-community-origin-contract`
Contract: `docs/COMMUNITY-CONTRIBUTION-V1.md`

Selected first V1 input:
**Evidence-backed correction/observation for an existing VERIFIED Bull profile using a public HTTP(S) source reference.**

V1 atomic field allowlist:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

This matches the existing guarded claim-promotion policy and keeps contributor intake useful without creating a new identity or direct canonical write.

Production inspection at task start confirmed Schema v0.2 community origin is not yet applied:
- `bullmatch_private.community_submissions` absent
- contributor profile/reputation tables absent
- `evidence.source_item_id` still NOT NULL
- `claims.extraction_run_id` still NOT NULL

Current implementation order:
1. additive community-origin + contributor-profile migration
2. rollback-only compatibility/security/idempotency tests
3. controlled authenticated submission RPC/Edge operation
4. contributor `MY_SUBMISSIONS` safe projection
5. mobile contribution UI

Required invariants:
- authenticated actor ID derived server-side, never trusted from payload
- contributor does not require ADMIN/REVIEWER role and gains no privileged role
- submission/evidence/claim/review tables remain server-mediated
- one submission produces atomic `REVIEW_REQUIRED` claims, never canonical mutation
- existing source-ingestion evidence/claims remain valid and retain IDs
- idempotency key retry cannot create duplicate submission/evidence/claim/review case
- canonical Bull row must remain unchanged after contribution
- no AI auto-publish
- no betting/wallet/settlement/payout fields or flow

Exact next slice:
Implement the additive migration defined in `docs/COMMUNITY-CONTRIBUTION-V1.md`, then run rollback-only compatibility and access-control tests before exposing the submission route.

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
Status: PLANNED — follows community contribution stabilization.

## Phase 3 — Multi-Source Expansion
Status: PLANNED

## Phase 4 — Intelligence Products
Status: PLANNED

Includes Matchup Intelligence, opponent-adjusted form, shared-opponent/style analysis, camp/venue analysis, evidence completeness/confidence, advanced reports and API/B2B surfaces.

## Autonomous Priority Reference

1. **BMI-P1-013 — Community Contribution Intake Foundation**
2. Automated collection pipeline after contribution/review contracts stabilize in production
3. Intelligence products
4. deferred APP-004 real-data visual QA
5. separately approved destructive identity operations only when their safety design is complete

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
