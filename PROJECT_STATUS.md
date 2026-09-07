# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / REVIEW FOUNDATION COMPLETE / VISUAL REBASELINE COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / COLLECTION FOUNDATION NEXT**

## Product Direction

BullMatch is organized as:

1. **Community Data Network**
2. **Verified BullMatch Big Data**
3. **Intelligence Products**

Canonical flow:

`Open Contribution or Permitted Source -> Evidence -> Atomic Claims -> Entity Resolution -> Review/Verification -> Controlled Promotion -> Published History -> Analytics`

Community contributors and automated collectors never directly overwrite canonical history.

BullMatch remains a data/statistics/research/historical-record/analytics platform, not a bet-taking, wallet, odds-settlement or payout service.

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE via PR #29
- BMI-P1-008 Review Backend Foundation — IMPLEMENTATION GATE COMPLETE via PR #50–#56
- BMI-P1-009 Thai Bullfighting Domain Rebaseline — DONE via PR #36
- BMI-P1-010 Product Rebaseline v0.3 — DONE via PR #38
- BMI-P1-011 Database Schema v0.2 — DONE via PR #39
- BMI-P1-012 Contribution & Trust Architecture — DONE via PR #40
- BMI-P1-013 Community Contribution Intake Foundation — **V1 IMPLEMENTATION GATE COMPLETE via PR #59–#62**
- BMI-APP-001 Frontend Foundation — DONE via PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE via PR #31
- BMI-APP-003 Production API Wiring — DONE via PR #33
- BMI-APP-004 Visual Design Rebaseline — IMPLEMENTATION GATE COMPLETE via PR #41, #42, #46, #47, #48
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Production Infrastructure

Shared Supabase project: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`).

BullMatch-owned schemas:
- `bullmatch`
- `bullmatch_private`

Production flow:

`GitHub Pages React app -> bullmatch-api Edge Function -> service-only RPC bridge -> BullMatch schemas`

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

No fake Production Bull/Match/review/community records have been introduced.

## Canonical Truth Boundary

The authoritative rule remains:

`Evidence/Submission -> Atomic Claim -> Review/Verification -> Controlled Promotion -> Canonical/Published Fact`

Important consequences:
- community submissions never directly update a Bull profile or match history
- automated extraction never directly publishes canonical facts
- `APPROVE` verifies a claim; canonical promotion is a separate fact-specific controlled operation
- unresolved/conflicting evidence remains preserved and auditable
- name similarity alone never proves Bull identity

## BMI-APP-004 — Visual Rebaseline

Status: **IMPLEMENTATION GATE COMPLETE**
Canonical visual contract: `docs/VISUAL-SYSTEM.md`.

Delivered:
- real licensed atmosphere imagery used only as atmosphere
- no cute/cartoon Bull identity
- sports-intelligence scoreboard / arena VS language
- safe canonical Bull Profile and Match participant imagery
- explicit no-verified-image fallbacks
- evidence-aware Data Coverage / Trust Signals
- reduced-motion + mobile safeguards
- no fabricated confidence percentage, odds, wallet, payout or settlement UI

Deferred non-blocking QA: Production currently has no genuine VERIFIED/PUBLISHED Bull/Match rows, so real-data screenshot states are not fabricated merely for QA.

## BMI-P1-008 — Review Backend Foundation

Status: **IMPLEMENTATION GATE COMPLETE**
Merged/deployed: PR #50–#56.

The review foundation now provides:
- controlled reviewer queue/detail/evidence reads
- idempotent commands and optimistic concurrency
- atomic claim decisions
- append-only review actions and audit/provenance
- guarded duplicate/entity decisions
- read-only Bull MERGE/SPLIT impact preview with destructive execution disabled
- narrow evidence-backed canonical promotion policy
- guarded UNVERIFIED Bull identity-container creation
- Production reviewer UI
- safe routing metadata EDIT only

Explicitly deferred:
- destructive Bull MERGE/SPLIT
- broad identity/name/alias promotion
- owner/camp, lineage/media and match-history promotion
- distinct-Bull same-name escalation policy

## BMI-P1-013 — Community Contribution Intake Foundation

Status: **V1 IMPLEMENTATION GATE COMPLETE**
Contract: `docs/COMMUNITY-CONTRIBUTION-V1.md`

### V1 scope

Evidence-backed correction/observation for an existing VERIFIED Bull profile using a public HTTP(S) source reference.

Allowed atomic facts:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

### PR #59 — Community origin foundation
Production migrations:
- `20260906232656_add_bullmatch_community_origin_foundation`
- `20260906232826_index_bullmatch_claim_supersession`

Delivered contributor profiles, private community submissions and generalized evidence/claim origins while preserving source-ingestion compatibility and browser default-deny.

### PR #60 — Controlled contribution API
Production migration:
- `20260906234150_add_bullmatch_community_correction_submit`

Production Edge Function: `bullmatch-api` v13 at this slice.

Delivered authenticated server-mediated Bull correction submission with:
- actor derived from validated Bearer token
- VERIFIED/nonarchived Bull target
- four-field allowlist
- public HTTP(S) evidence requirement
- deterministic idempotency/dedupe/value fingerprints
- evidence + atomic REVIEW_REQUIRED claim + review case creation
- no canonical mutation and no fabricated confidence

### PR #61 — Contributor `MY_SUBMISSIONS`
Production migration:
- `20260906235014_add_bullmatch_my_submissions_query`

Production Edge Function: `bullmatch-api` v14 at this slice.

Delivered own-record-only contributor feedback projection. It intentionally excludes source URL/note, reviewer identities/notes, moderation metadata, audit internals and other contributors.

### PR #62 — Mobile Community Contribution UI
Merged/deployed to GitHub Pages.

Delivered:
- authenticated Community contribution route for ordinary provisioned users
- Dashboard/navigation entry
- Bull Profile `เสนอแก้ไขข้อมูล` action
- VERIFIED Bull selection only
- one atomic correction + public evidence URL flow
- explicit review-before-profile-change language
- `การส่งข้อมูลของฉัน` status view
- pending/accepted/rejected/conflict/superseded/withdrawn states
- mobile sports-intelligence styling and reduced-motion behavior

Validation:
- PR TypeScript/typecheck/build PASS
- controlled Production API smoke PASS
- main TypeScript/build PASS
- main Production API smoke PASS
- GitHub Pages deployment PASS

### V1 limitations / deferred expansion

These are intentional boundaries, not hidden blockers:

1. Production has no genuine VERIFIED/PUBLISHED Bull suitable for a retained success-path contribution fixture. Database behavior was validated with rollback-only temporary records and no fake records were retained.
2. Open/public self-signup is not part of V1. The UI works for provisioned authenticated accounts. Any open-registration flow requires separate auth/abuse/privacy policy design.
3. V1 accepts public HTTP(S) source references only; direct image/file evidence upload is future work.
4. Program/result/comparison-day/new-Bull contribution types remain future expansion slices.

## Next Task

### BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation
Status: **READY / UNCLAIMED**

This is the highest-priority non-blocked engineering task.

Goal: establish the shared ingestion envelope and connector execution contracts that future permitted source connectors must use, without prematurely choosing/scraping a Production source.

Required first slice:
1. define a versioned normalized ingestion envelope
2. define source registry and connector/run/result interfaces
3. require source identifier/URL, retrieval timestamp, source publication timestamp when known, connector name/version and evidence reference
4. route extracted facts into evidence/atomic claims and review states rather than canonical tables
5. preserve `DISCOVERED -> EXTRACTED -> UNVERIFIED/REVIEW_REQUIRED -> VERIFIED -> PUBLISHED`
6. preserve conflicts rather than forcing a winner
7. add idempotency/dedupe contracts and deterministic tests
8. document connector compliance boundaries and how an approved source plugs in later

Expected implementation areas:
- `agents/connectors/`
- shared contracts under `packages/contracts/` if appropriate
- deterministic tests/scripts
- docs

Not authorized inside BMI-P2-001:
- selecting/scraping a real Production source without explicit source/compliance decision
- direct canonical Bull/Match writes
- inventing source facts or retaining fake Production data
- selecting an AI provider merely to complete the foundation

## Next Engineering Gates

1. **BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation** — READY
2. first permitted Production source connector after explicit source/compliance selection
3. Intelligence Products / Matchup Intelligence after verified data depth is sufficient
4. deferred APP-004 real-data visual QA
5. separately approved destructive identity operations only after their safety design is complete

## Deferred / External-Decision Items

- first Production source selection and source-specific compliance approval
- open/public contributor signup/onboarding policy
- AI provider selection
- destructive identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name creation escalation policy
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists

## Exact Next Autonomous Action

Start `BMI-P2-001` only after re-reading the control files and checking active branches/PRs.

Startup actions:
1. claim BMI-P2-001 in `TASKS.md`
2. create `agent/bmi-p2-001-collection-foundation`
3. inspect existing `agents/`, `packages/`, source/evidence schema and agent specification before choosing file layout
4. define contracts first, then implement deterministic source-agnostic runner/test scaffolding
5. do not call or scrape an external source in this task
6. validate tests/build and leave a PR handoff with exact source-specific next boundary
