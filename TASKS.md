# Task Registry

This file is the high-level project map. GitHub Issues/PRs are the canonical execution/handoff records.

## Phase 0 — Foundation & Architecture — COMPLETE

BMI-P0-001 through BMI-P0-010: **DONE**.

---

## Phase 1 — Verified Database / Community Foundation — COMPLETE GATES

### BMI-P1-001 — Shared Supabase Bootstrap
Status: DONE — PR #16

### BMI-P1-002 — Core Database Migrations
Status: DONE — PR #18

### BMI-P1-003 — Seed / Reference Data
Status: DEFERRED — NO REQUIRED MVP SEED; never fabricate Production history.

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
Merged/deployed slices: PR #50, #51, #52, #53, #54, #55, #56.

Delivered:
- controlled REVIEWER/ADMIN queue/detail and evidence projection
- idempotent commands + optimistic concurrency
- atomic claim decisions and append-only audit/provenance
- read-only Bull MERGE/SPLIT impact preview; destructive execution remains disabled
- narrow ADMIN-only promotion for evidence-backed VERIFIED Bull facts
- guarded duplicate/entity decisions; name-only identity proof is blocked
- guarded UNVERIFIED Bull identity-container creation
- Production Review Queue UI
- safe review-routing metadata EDIT limited to priority/summary

Preserved invariants:
- canonical history closed to direct community writes
- APPROVE and canonical promotion are separate operations
- no majority-vote truth or name-similarity auto-merge
- no betting/wallet/settlement/payout capability

Deferred outside this gate:
- destructive identity MERGE/SPLIT
- broad/high-risk identity/name/alias promotion
- owner/camp affiliation, lineage/media and match-history promotion
- distinct-Bull same-name escalation policy

### BMI-P1-009 — Thai Bullfighting Domain Rebaseline
Status: DONE — PR #36

### BMI-P1-010 — Product Rebaseline v0.3
Status: DONE — PR #38

### BMI-P1-011 — Database Schema v0.2
Status: DONE — PR #39
Deliverables: `docs/DATABASE-SCHEMA.md`, `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`.

### BMI-P1-012 — Contribution & Trust Architecture
Status: DONE — PR #40
Deliverable: `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`.

### BMI-P1-013 — Community Contribution Intake Foundation
Status: DONE — **V1 IMPLEMENTATION GATE COMPLETE**
Owner: Primary Maintainer
Contract: `docs/COMMUNITY-CONTRIBUTION-V1.md`
Merged/deployed slices: PR #59, #60, #61, #62.

Selected V1 input:
**Evidence-backed correction/observation for an existing VERIFIED Bull profile using a public HTTP(S) source reference.**

V1 atomic field allowlist:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Delivered:

**PR #59 — Community-origin foundation**
- Production migrations `20260906232656` + `20260906232826`
- contributor profiles and private community submissions
- generalized evidence/claim origin while preserving source-extraction compatibility
- service-role-only storage / browser default-deny
- rollback-only isolation regression PASS; no retained fixtures

**PR #60 — Controlled Bull correction submission API**
- Production migration `20260906234150`
- `bullmatch-api` Edge v13
- actor derived from validated bearer token, never payload
- existing VERIFIED/nonarchived Bull required
- public HTTP(S) evidence required
- deterministic idempotency/dedupe/value fingerprints
- creates submission + evidence + atomic REVIEW_REQUIRED claim + OPEN DATA_QUALITY review case
- confidence stays NULL; no AI auto-publish
- canonical Bull unchanged in rollback regression
- direct RPC execution revoked from PUBLIC/anon/authenticated

**PR #61 — Safe `MY_SUBMISSIONS` contributor projection**
- Production migration `20260906235014_add_bullmatch_my_submissions_query`
- `bullmatch-api` Edge v14
- authenticated actor derived server-side
- own-record-only projection
- exposes safe submission state, public Bull identity and claim outcome only
- does not expose source URL/note, reviewer identity/notes, moderation/audit internals or other contributors
- rollback-only leak/isolation regression PASS

**PR #62 — Mobile community contribution experience**
- authenticated `contribute` route for ordinary registered contributors
- Dashboard/navigation Community entry
- `เสนอแก้ไขข้อมูล` action from VERIFIED Bull Profile
- existing VERIFIED Bull selection only; no V1 identity creation
- four-field atomic correction UI + required public source URL
- explicit REVIEW_REQUIRED / review-before-canonical-promotion messaging
- “การส่งข้อมูลของฉัน” feedback view from `MY_SUBMISSIONS`
- pending/accepted/rejected/conflict/superseded/withdrawn states
- sports-intelligence mobile styling, loading/error/empty/success states and reduced-motion support
- PR TypeScript/build PASS
- controlled Production API smoke PASS
- main GitHub Pages deployment PASS

Required invariants preserved:
- contributor actor identity is server-derived
- ordinary contributor gains no ADMIN/REVIEWER privilege
- browser cannot write private submission/evidence/claim/review or canonical tables directly
- submission creates REVIEW_REQUIRED atomic claims, never canonical mutation
- idempotent replay cannot create duplicate intake records
- contributor self-service is own-record-only
- no AI auto-publish
- no betting/wallet/settlement/payout flow

Known V1 limitations / intentionally deferred:
- Production currently has no genuine VERIFIED/PUBLISHED Bull suitable for a retained success-path contribution fixture. Rollback-only DB tests were used; no fake canonical/community rows were retained for screenshots.
- Public self-signup/onboarding is not part of this V1 gate. The current app supports provisioned authenticated users; any open-registration policy requires a separate abuse/privacy/auth design task.
- V1 supports public URL evidence references only, not photo/file upload.
- program/result/comparison-day/new-Bull contribution types remain future slices.

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
Merged increments: PR #41, #42, #46, #47, #48.

Delivered real-bull/sports-intelligence visual system, safe verified imagery, explicit no-image fallback, Data Coverage/Trust Signals, reduced-motion/mobile protection and no betting/payout UI.

Deferred non-blocking QA: verify real-image states when genuine canonical records exist; never fabricate them for screenshots.

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

## Phase 2 — Automated Collection Pipeline

### BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation
Status: **READY / UNCLAIMED**
Priority: highest next non-blocked engineering task.

Goal:
Build the reusable, source-agnostic ingestion boundary now that community/review contracts are stable, without selecting or scraping an unapproved Production source.

Required first slice:
1. define/version the normalized ingestion envelope used by every future connector
2. define source registry + connector interface + run/result contracts
3. persist source URL/identifier, retrieved timestamp, published timestamp when known, connector name/version and raw evidence reference
4. emit evidence/claims through the established unverified/review pipeline; never write canonical Bull/Match/history directly
5. preserve `DISCOVERED -> EXTRACTED -> UNVERIFIED/REVIEW_REQUIRED -> VERIFIED -> PUBLISHED`
6. preserve conflicts rather than choosing a winner automatically
7. add idempotency/dedupe and deterministic test fixtures in tests only
8. add unit/contract tests without retaining fabricated Production data
9. document how a later source-specific connector plugs in after source/compliance approval

Explicit boundary:
- **Do not choose or scrape the first Production source inside BMI-P2-001.** First Production source selection/compliance remains separately deferred.
- No AI provider decision is required for the initial deterministic envelope/runner foundation.
- No canonical publication from connector output.

Expected areas:
- `agents/connectors/`
- `agents/extraction/` only for shared interfaces if necessary
- `packages/contracts/` for versioned shared contracts if appropriate
- `docs/`
- tests/scripts required for deterministic validation

Dependencies: BMI-P1-008 DONE, BMI-P1-011 DONE, BMI-P1-012 DONE, BMI-P1-013 V1 DONE.

## Phase 3 — Multi-Source Expansion
Status: PLANNED — after one approved source connector proves the Phase 2 contracts.

## Phase 4 — Intelligence Products
Status: PLANNED
Includes Matchup Intelligence, opponent-adjusted form, shared-opponent/style analysis, camp/venue analysis, evidence completeness/confidence, advanced reports and API/B2B surfaces.

---

## Autonomous Priority Reference

1. **BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation**
2. first permitted Production source connector after explicit source/compliance selection
3. Intelligence Products / Matchup Intelligence when verified sample depth is sufficient
4. deferred APP-004 real-data visual QA
5. separately approved destructive identity operations only after safety design

Canonical autonomous instructions: `docs/AUTO-RUN-RUNBOOK.md`.

## Deferred / External-Decision Items

- first Production source selection and source-specific compliance approval
- open/public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name creation escalation policy
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing until real usage data exists

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the Primary Maintainer coordinates non-overlapping work.

When a task starts:
1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run relevant checks/tests
6. submit PR/handoff
