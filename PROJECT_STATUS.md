# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community Contribution Implementation on Verified/Review Foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST COMPLETE / VISUAL REBASELINE COMPLETE / REVIEW FOUNDATION IMPLEMENTATION GATE COMPLETE / COMMUNITY CONTRIBUTION NEXT**

## Product Direction

BullMatch is organized as:

1. **Community Data Network**
2. **Verified BullMatch Big Data**
3. **Intelligence Products**

Canonical flow:

`Open Contribution -> Evidence -> Atomic Claims -> Resolution -> Verification -> Controlled Promotion -> Published History -> Analytics`

Community contributors never directly overwrite canonical history.

BullMatch remains a data/statistics/research/analytics platform, not a bet-taking, wallet, odds-settlement or payout service.

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

No fake Production Bull/Match/review records have been introduced.

## Visual Rebaseline

BMI-APP-004 implementation gate is complete. Canonical visual contract: `docs/VISUAL-SYSTEM.md`.

Delivered:
- real licensed atmosphere imagery used only as atmosphere
- no cute/cartoon Bull identity
- BM product mark rather than mascot identity
- sports-intelligence scoreboard / arena VS language
- safe canonical Bull Profile and Match participant imagery
- explicit no-verified-image fallbacks
- evidence-aware Data Coverage / Trust Signals
- reduced-motion + mobile safeguards
- no fabricated confidence percentage, odds, wallet, payout or settlement UI

Deferred QA remains non-blocking: Production currently has no real VERIFIED/PUBLISHED Bull/Match rows, so real-image states are not fabricated merely for screenshots.

## BMI-P1-008 — Review Backend Foundation

Status: **IMPLEMENTATION GATE COMPLETE**

Merged/deployed increments:

### PR #50 — Review foundation
Production migration: `20260906211732_add_bullmatch_review_backend_foundation`

Delivered server-mediated REVIEWER/ADMIN queue/detail, evidence projection with access-class redaction, idempotent commands, optimistic `case_version`, claim decisions, append-only review actions and private audit. Direct community writes to canonical history remain impossible through review commands.

### PR #51 — Bull identity impact preview
Production migration: `20260906212825_add_bullmatch_identity_impact_preview`

Delivered deterministic read-only MERGE/SPLIT impact preview, same-match distinct-Bull hard-conflict detection, deterministic fingerprint and `execution_enabled: false`. Name similarity is never identity authority.

### PR #52 — Guarded VERIFIED claim promotion
Production migration: `20260906214802_add_bullmatch_verified_claim_promotion`

First canonical promotion policy is ADMIN-only and narrowly allows evidence-backed EXPLICIT VERIFIED Bull claims for `home_province`, `home_district`, `color_description`, and `breed_description` with fact provenance and audit. Claim APPROVE and canonical promotion remain separate operations.

### PR #53 — Reviewed entity / duplicate decisions
Production migration: `20260906215917_add_bullmatch_reviewed_entity_decisions`

Delivered `LINK_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE` with role checks, idempotency, optimistic case version and strong Bull identity basis. `NAME_ONLY` is blocked. Duplicate confirmation does not merge canonical Bulls.

### PR #54 — Guarded reviewed Bull CREATE_ENTITY
Production migration: `20260906224832_add_bullmatch_guarded_review_create_entity`

Creates only an **UNVERIFIED Bull identity container** after completed candidate/duplicate searches and a strong reviewed creation basis. It writes only canonical name, never owner/camp/lineage/media/descriptive facts/match history, and cannot verify or publish the new Bull.

### PR #55 — Production Review Queue UI

The previous placeholder is now a production reviewer control room using already-deployed reviewer APIs.

Delivered:
- reviewer queue and case detail
- atomic claim and evidence inspection
- entity-match/duplicate candidate signals
- append-only audit history
- CLAIM / UNCLAIM / COMMENT / APPROVE / REJECT using fresh command IDs and optimistic case status/version
- explicit canonical truth boundary in the interface
- read-only Bull identity impact preview for MERGE_SPLIT cases
- no destructive merge/split controls
- responsive sports-intelligence layout and empty-production state without fake fixtures

Validation:
- PR Web CI TypeScript/build PASS
- controlled Production API smoke PASS
- main GitHub Pages deploy PASS

### PR #56 — Safe review metadata EDIT
Production migration: `20260906225757_add_bullmatch_review_metadata_edit`
Production Edge Function: `bullmatch-api` v12
Policy: `BMI-P1-008-REVIEW-METADATA-EDIT-V1`

Allowed EDIT surface is deliberately limited to review routing metadata:
- `priority`
- `summary`

It cannot modify subject identity/ref, case truth/status, claim values/status, evidence, duplicate/entity decisions, Bull identity/name, owner/camp, lineage/media, match/event/venue history, provenance or canonical promotion state.

Required:
- ACTIVE ADMIN/REVIEWER
- schema version 1.0.0
- unique command ID
- OPEN/IN_REVIEW case
- optimistic case version
- reviewer note

Production rollback regression and security advisor validation passed. Direct browser roles cannot execute the service-only EDIT RPC.

## BMI-P1-008 Boundary / Deferred Work

The review foundation implementation gate is complete because the approved non-destructive review lifecycle now has controlled reads, evidence access, case/claim decisions, identity/duplicate decisions, guarded UNVERIFIED Bull creation, narrow canonical promotion, safe routing metadata EDIT, audit/provenance, concurrency/idempotency and a production reviewer UI.

The following are **not** silently included in this completed gate and remain separately deferred:
- destructive Bull MERGE/SPLIT execution
- broad/high-risk canonical EDIT/promotion of identity/name/aliases
- owner/camp affiliation promotion
- lineage/media promotion
- match-history/result canonical promotion beyond separately reviewed policies
- distinct-Bull same-name creation escalation

A future destructive identity task must require an unchanged impact-preview fingerprint plus an explicit reassignment/provenance plan and new regression/security review.

## Canonical Truth Boundary

Community submissions, AI extraction, candidate matching and reviewer verification do not directly publish canonical history.

`APPROVE` verifies an atomic claim. Canonical promotion is separate, fact-specific and policy-controlled. `CREATE_ENTITY` creates an UNVERIFIED identity container only. Review metadata EDIT never changes canonical truth.

## Next Task

### BMI-P1-013 — Community Contribution Intake Foundation
Status: **READY / UNCLAIMED**

This is now the highest-priority non-blocked task.

Goal: implement the first production-safe community contribution path against Schema v0.2, Contribution & Trust Architecture and the completed Review Backend.

Recommended first V1 slice:
**Bull profile correction / observation with evidence or a public source reference.**

Why this first:
- useful to real community contributors
- exercises contributor -> evidence -> atomic claim -> entity candidate/resolution -> review routing
- does not require solving the full comparison-day/program/match ingestion workflow immediately
- can remain fully outside canonical history until verification/promotion policy permits a fact

Required startup for the next run:
1. read `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`
2. read `docs/CONTRIBUTION-TRUST-ARCHITECTURE.md`
3. inspect current contribution/community tables and auth boundaries in Production/repo
4. claim `BMI-P1-013` on a dedicated branch
5. define a narrow versioned submission contract before DDL/API/UI edits
6. keep contributor writes server-mediated and canonical tables closed
7. add idempotency, evidence linkage, likely-existing-entity search and review-case routing
8. expose contributor-visible submission state without leaking private reviewer/audit data
9. validate migrations/security/API/UI without retaining fabricated Production fixtures

## Next Engineering Gates

1. **BMI-P1-013 — Community Contribution Intake Foundation** — READY
2. first permitted automated source connector/pipeline after contribution/review contracts stabilize
3. intelligence products / Matchup Intelligence analytics
4. deferred real-data APP-004 visual QA when canonical data becomes available
5. separately approved destructive identity operations only after their safety design is complete

## Still Deferred

- destructive identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name creation escalation policy
- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
