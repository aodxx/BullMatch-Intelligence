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

BMI-APP-004 implementation gate is complete. Canonical visual contract: `docs/VISUAL-SYSTEM.md`.

Delivered:
- real licensed atmosphere imagery used only as atmosphere
- BM product mark rather than mascot identity
- no cute/cartoon bull identity
- scoreboard statistics, action rails and arena-style VS composition
- safe canonical Bull Profile and participant Match imagery
- explicit no-verified-image fallbacks
- evidence-aware Data Coverage / Trust Signals
- reduced-motion + mobile safeguards
- no fabricated confidence percentage, odds, betting wallet, payout or settlement UI

Deferred QA remains non-blocking: Production has no real VERIFIED/PUBLISHED Bull/Match rows, so real-image states cannot yet be demonstrated without fabricating canonical data.

## BMI-P1-008 — Review Backend Foundation

Status: **IN PROGRESS**

Owner: Primary Maintainer (ChatGPT autonomous run)
Current continuation branch: `agent/bmi-p1-008-reviewed-entity-decisions`

### Review foundation deployed — PR #50

Production migration: `20260906211732_add_bullmatch_review_backend_foundation`

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

Production migration: `20260906212825_add_bullmatch_identity_impact_preview`

Implemented:
- deterministic read-only `MERGE_SPLIT` preview for Bull identities
- source/target Bull summaries and affected-row counts
- same-match distinct-Bull hard-conflict detection
- deterministic preview fingerprint
- `execution_enabled: false`
- name similarity is explicitly not merge authority
- no identity/history mutation

Verification:
- `supabase/tests/p1_008_identity_impact_preview.sql`
- `supabase/P1-008-IDENTITY-PREVIEW-VERIFICATION.md`

### Guarded VERIFIED claim -> canonical promotion deployed — PR #52

Production migration: `20260906214802_add_bullmatch_verified_claim_promotion`
Production Edge Function at that slice: `bullmatch-api` v9

Promotion policy `BMI-P1-008-BULL-DESCRIPTIVE-V1` allows only evidence-backed, EXPLICIT, VERIFIED Bull descriptive claims for:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Canonical name/aliases, identity, owner/camp, lineage, media, lifecycle, match participants/results/history and merge/split remain excluded.

`APPROVE` still verifies the atomic claim only. Canonical mutation requires the separate ADMIN-only promotion command with evidence, provenance, audit, idempotency and optimistic case-version checks.

Verification:
- `supabase/tests/p1_008_verified_claim_promotion.sql`
- `supabase/P1-008-CLAIM-PROMOTION-VERIFICATION.md`

### Reviewed entity / duplicate decisions deployed — current PR handoff

Production migration: `20260906215917_add_bullmatch_reviewed_entity_decisions`
Production Edge Function: `bullmatch-api` v10

Implemented:
- `LINK_ENTITY`
- `CONFIRM_DUPLICATE`
- `MARK_NOT_DUPLICATE`
- ACTIVE ADMIN/REVIEWER checks in Edge and PostgreSQL boundaries
- globally idempotent `command_id`
- optimistic expected-status + `case_version` checks
- candidate must belong to the review case
- canonical LINK target must exist, be VERIFIED and not archived
- Bull links require reviewed non-name-only identity basis
- Bull `NAME_ONLY` is explicitly blocked
- duplicate decisions mutate candidate resolution status only
- every successful decision records before/after review action + private audit
- all operations report `canonical_mutation: false`

Important boundary:
- `CONFIRM_DUPLICATE` does **not** merge Bulls
- `LINK_ENTITY` does **not** rewrite canonical Bull/Owner/Camp/Venue/Event data
- no historical match participant reassignment occurs
- no community or AI submission directly overwrites canonical truth

Production rollback regression passed for link, duplicate confirmation, not-duplicate decision, idempotent replay, case-version behavior, name-only Bull identity rejection, audit counts and canonical Bull immutability. Transaction rolled back.

Security Advisor rerun after the deployed migration found no new browser-executable decision RPC exposure. Existing service-only private-schema RLS INFO and the project-level leaked-password-protection warning remain unrelated/pre-existing.

Verification:
- `supabase/tests/p1_008_reviewed_entity_decisions.sql`
- `supabase/P1-008-ENTITY-DECISIONS-VERIFICATION.md`

## Canonical Truth Boundary

Community submissions, AI extraction, candidate resolution and reviewer verification cannot directly overwrite canonical history.

Current allowed canonical bridge remains deliberately narrow and policy-versioned. Bull identity is never inferred from name similarity alone. Duplicate confirmation is not merge execution.

## Exact Next Autonomous Action

Finish/merge the reviewed-entity-decisions PR after CI. Then continue **BMI-P1-008** on a fresh non-overlapping branch.

Next implementation order:
1. design guarded `CREATE_ENTITY` semantics with mandatory candidate/duplicate search evidence before any new Bull identity creation
2. define selected `EDIT` semantics only where they cannot bypass verified-claim promotion
3. wire production Review Queue UI to `REVIEW_QUEUE`, `REVIEW_CASE`, identity preview and safe reviewer commands
4. destructive merge/split remains deferred until a separately reviewed execution design requires an unchanged preview fingerprint plus explicit reassignment/provenance plan

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
