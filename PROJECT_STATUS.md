# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Verified Database + Community Review Foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST COMPLETE / VISUAL REBASELINE COMPLETE / REVIEW BACKEND IN PROGRESS**

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

BMI-APP-004 implementation gate is complete.

Canonical visual contract:
- `docs/VISUAL-SYSTEM.md`

Delivered:
- real licensed atmosphere imagery used only as atmosphere
- BM product mark rather than mascot identity
- no cute/cartoon bull identity
- scoreboard statistics, action rails and arena-style VS composition
- safe canonical Bull Profile imagery
- participant-specific canonical Match imagery
- explicit no-verified-image fallbacks
- evidence-aware Data Coverage / Trust Signals
- reduced-motion + mobile safeguards
- no fabricated confidence percentage, odds, betting wallet, payout or settlement UI

Deferred QA remains non-blocking: Production has no real VERIFIED/PUBLISHED Bull/Match rows, so real-image states cannot yet be demonstrated without fabricating canonical data. Run non-mutating mobile/desktop visual QA when real records exist.

## BMI-P1-008 — Review Backend Foundation

Status: **IN PROGRESS**

Owner: Primary Maintainer (ChatGPT autonomous run)
Current continuation branch: `agent/bmi-p1-008-verified-claim-promotion`

### Review foundation deployed — PR #50

Production migration:
`20260906211732_add_bullmatch_review_backend_foundation`

Implemented:
- controlled REVIEWER/ADMIN queue + review-case detail API
- controlled reviewer evidence access
- ACTIVE ADMIN/REVIEWER checks in Edge and PostgreSQL boundaries
- idempotent `command_id`
- optimistic expected-status + `case_version` checks
- claim decisions: VERIFIED / REJECTED / CONFLICT / SUPERSEDED without direct canonical publication
- append-only review action + private audit records
- MERGE/SPLIT execution blocked

Verification:
- `supabase/tests/p1_008_review_backend.sql`
- `supabase/P1-008-VERIFICATION.md`

### Bull identity impact preview deployed — PR #51

Production migration:
`20260906212825_add_bullmatch_identity_impact_preview`

Implemented:
- deterministic read-only `MERGE_SPLIT` preview for Bull identities
- source/target Bull summaries and affected-row counts
- same-match distinct-Bull hard-conflict detection
- deterministic preview fingerprint
- `execution_enabled: false`
- name similarity is explicitly not merge authority
- no identity/history mutation

Production validation confirmed ACL, fixed search path, rollback-only hard-conflict behavior, and zero retained fixtures.

Verification:
- `supabase/tests/p1_008_identity_impact_preview.sql`
- `supabase/P1-008-IDENTITY-PREVIEW-VERIFICATION.md`

### Guarded VERIFIED claim -> canonical promotion deployed

Production migration:
`20260906214802_add_bullmatch_verified_claim_promotion`

Production Edge Function:
`bullmatch-api` version 9

This is the first deliberately narrow canonical promotion bridge. It is not general CRUD.

Promotion policy `BMI-P1-008-BULL-DESCRIPTIVE-V1` requires:
- ACTIVE ADMIN; REVIEWER may verify claims but cannot perform canonical promotion
- resolved review case with matching optimistic `case_version`
- claim linked to that review case
- claim state `VERIFIED`
- claim basis `EXPLICIT`
- subject type `BULL`
- explicit `subject_ref.canonical_subject_id`
- target Bull exists, is VERIFIED and is not archived
- at least one SUPPORTS evidence link
- JSON string value and conservative length limits
- same claim has not already created canonical provenance for that Bull/field

First allowlist only:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Explicitly not promotable in this slice:
- Bull canonical name / aliases / identity
- owner/camp relationships
- lineage
- imagery/media
- Bull lifecycle status
- match participants/opponents
- match result/duration/date/venue/event history
- merge/split

Successful promotion atomically performs:
- canonical Bull field update
- review-case version increment
- `PROMOTE_CLAIM` review action
- claim-level provenance
- SUPPORTS / CONTRADICTS evidence provenance
- private `REVIEW_PROMOTE_CLAIM` audit record

Idempotency uses the existing global review `command_id` ledger. Same-command replay does not remutate canonical state or increment version again.

Production validation completed:
- direct RPC ACL: anon=false, authenticated=false, service_role=true
- RPC is SECURITY DEFINER with fixed empty search path
- rollback-only evidence-backed `home_province` claim promoted successfully
- case version advanced 2 -> 3
- claim + evidence provenance rows recorded
- exactly one review action and one audit record recorded
- same command replayed idempotently
- disallowed `canonical_name` promotion was blocked
- rollback left zero test Bull, review case and source fixtures
- Supabase Security Advisor reports no new direct promotion-RPC browser exposure

Regression / verification:
- `supabase/tests/p1_008_verified_claim_promotion.sql`
- `supabase/P1-008-CLAIM-PROMOTION-VERIFICATION.md`

### Canonical truth boundary

`APPROVE` still means **the atomic claim is verified**; it does not itself mutate canonical tables.

Canonical mutation now requires the separate ADMIN-only promotion operation and is allowed only under a versioned strict field policy with evidence, provenance, audit and optimistic concurrency.

Community submissions, AI extraction and reviewer verification cannot bypass this promotion boundary.

## Exact Next Autonomous Action

Finish/merge the current verified-claim-promotion PR after CI. Then continue **BMI-P1-008** on a fresh non-overlapping branch.

Next implementation order:
1. define safe semantics for `LINK_ENTITY`, `CONFIRM_DUPLICATE`, and `MARK_NOT_DUPLICATE` using existing candidate tables, provenance/audit and idempotent review commands
2. design `CREATE_ENTITY` separately with mandatory candidate search / duplicate safeguards before any new Bull identity can be created
3. define selected `EDIT` semantics only where it does not bypass claim verification/promotion
4. wire production Review Queue UI to `REVIEW_QUEUE`, `REVIEW_CASE`, identity preview and safe reviewer commands
5. destructive merge/split remains deferred until a separately reviewed execution design requires an unchanged preview fingerprint plus explicit reassignment/provenance plan

Do not expand canonical promotion to names, identity, match result/history, lineage or affiliations without domain-specific promotion rules. Do not publish unresolved/conflicted claims. Do not infer Bull identity from name similarity alone.

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation** — IN PROGRESS
2. Community contribution schema migration/API/UI implementation
3. First permitted automated source connector/pipeline
4. Intelligence products / Matchup Intelligence analytics
5. Deferred real-data APP-004 visual QA when canonical data becomes available

## Still Deferred

- destructive identity merge/split execution
- broad/high-risk canonical promotion
- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
