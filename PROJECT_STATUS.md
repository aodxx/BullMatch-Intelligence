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

Status: **IN PROGRESS**

Owner: Primary Maintainer (ChatGPT autonomous run)
Current continuation branch: `agent/bmi-p1-008-guarded-create-entity`

### Review foundation — PR #50

Production migration: `20260906211732_add_bullmatch_review_backend_foundation`

Delivered controlled REVIEWER/ADMIN queue/detail reads, evidence projection, idempotent review commands, optimistic `case_version`, claim verification/rejection/conflict handling, append-only review actions and private audit. MERGE/SPLIT execution remains blocked.

Verification:
- `supabase/tests/p1_008_review_backend.sql`
- `supabase/P1-008-VERIFICATION.md`

### Bull identity impact preview — PR #51

Production migration: `20260906212825_add_bullmatch_identity_impact_preview`

Delivered deterministic read-only Bull MERGE/SPLIT impact preview, same-match hard-conflict detection, fingerprint and `execution_enabled: false`. Name similarity is never merge authority.

Verification:
- `supabase/tests/p1_008_identity_impact_preview.sql`
- `supabase/P1-008-IDENTITY-PREVIEW-VERIFICATION.md`

### Guarded VERIFIED claim promotion — PR #52

Production migration: `20260906214802_add_bullmatch_verified_claim_promotion`

Policy `BMI-P1-008-BULL-DESCRIPTIVE-V1` permits only ADMIN promotion of evidence-backed, EXPLICIT, VERIFIED Bull claims for:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Canonical names/aliases, identity, owner/camp, lineage, media, lifecycle, match participants/results/history and merge/split remain excluded. `APPROVE` verifies a claim only; canonical mutation remains a separate policy-controlled operation.

Verification:
- `supabase/tests/p1_008_verified_claim_promotion.sql`
- `supabase/P1-008-CLAIM-PROMOTION-VERIFICATION.md`

### Reviewed entity / duplicate decisions — PR #53

Production migration: `20260906215917_add_bullmatch_reviewed_entity_decisions`
Production Edge Function at that slice: v10

Delivered:
- `LINK_ENTITY`
- `CONFIRM_DUPLICATE`
- `MARK_NOT_DUPLICATE`
- ACTIVE ADMIN/REVIEWER checks at Edge + database boundary
- command-id idempotency and optimistic case-version checks
- verified/nonarchived canonical link target requirement
- Bull strong identity-basis requirement; `NAME_ONLY` blocked
- duplicate decisions resolve candidate metadata only; they do not merge canonical entities
- before/after review action + private audit
- `canonical_mutation: false`

Verification:
- `supabase/tests/p1_008_reviewed_entity_decisions.sql`
- `supabase/P1-008-ENTITY-DECISIONS-VERIFICATION.md`

### Guarded reviewed Bull CREATE_ENTITY — current PR handoff

Production migration: `20260906224832_add_bullmatch_guarded_review_create_entity`
Production Edge Function: `bullmatch-api` v11
Policy: `BMI-P1-008-BULL-CREATE-V1`

This is the first reviewed new-identity creation path and is intentionally narrower than generic ADMIN CRUD.

Required:
- ACTIVE ADMIN only
- review case `OPEN` / `IN_REVIEW` with matching optimistic `case_version`
- case type `NEW_ENTITY` or `ENTITY_MATCH`
- Bull candidate attached to that review case
- candidate decision `NEW_ENTITY_CANDIDATE`
- candidate has no canonical target yet
- explicit completed candidate search
- explicit completed duplicate search
- nonblank search policy version
- strong reviewed creation basis: `VISUAL_IDENTITY`, `EXTERNAL_IDENTIFIER`, `OFFICIAL_RECORD`, `MATCH_HISTORY_CONTEXT`, or `MULTI_SIGNAL`
- reviewer note

Blocked:
- `NAME_ONLY`
- missing search completion
- any unresolved or confirmed duplicate candidate in the candidate group
- an already confirmed Bull link in the group
- an active Bull with the same normalized name

Successful creation:
- creates only `canonical_name`
- new Bull remains `UNVERIFIED`
- does not write owner/camp/lineage/media/descriptive/match fields
- candidate becomes `CONFIRMED_LINK` to the new Bull
- review-case version advances once
- writes one `CREATE_ENTITY` review action and private `REVIEW_CREATE_ENTITY` audit
- reuses existing audited `BULL_CREATED` primitive
- same-command replay returns the same Bull without another insert/version change

The exact normalized-name collision rule is deliberately conservative. A legitimately distinct Bull sharing the same name requires a future explicit distinct-identity escalation design rather than silent duplicate creation.

Production rollback regression passed:
- valid path created one UNVERIFIED identity
- no out-of-scope fields were written
- replay was idempotent
- incomplete search blocked
- unresolved duplicate blocked
- normalized-name collision blocked
- `NAME_ONLY` blocked
- rollback left zero test Bulls and zero rollback review cases

Direct RPC ACL verified:
- anon=false
- authenticated=false
- service_role=true
- SECURITY DEFINER with fixed empty search path

Security Advisor found no new browser-executable CREATE_ENTITY RPC exposure. Existing private-schema RLS INFO and Auth leaked-password-protection warning remain unrelated/pre-existing.

Migration filename was reconciled to the exact Production version `20260906224832`.

Verification:
- `supabase/tests/p1_008_guarded_create_entity.sql`
- `supabase/P1-008-GUARDED-CREATE-ENTITY-VERIFICATION.md`

## Canonical Truth Boundary

Community submissions, AI extraction, candidate matching and reviewer verification do not directly publish canonical history.

The guarded CREATE_ENTITY command creates an **UNVERIFIED identity container only**. It does not verify or publish the Bull and cannot enrich identity/lineage/affiliation/media/match history through the creation command.

## Exact Next Autonomous Action

Finish/merge the guarded CREATE_ENTITY PR after repository checks/handoff. Then continue **BMI-P1-008** on a fresh non-overlapping branch.

Next implementation order:
1. define selected `EDIT` semantics only where they cannot bypass atomic-claim verification and policy-controlled canonical promotion
2. wire production Review Queue UI to `REVIEW_QUEUE`, `REVIEW_CASE`, identity preview and safe reviewer commands
3. destructive merge/split remains deferred until a separately reviewed execution design requires unchanged preview fingerprint plus explicit reassignment/provenance plan

Do not introduce a broad generic review edit that can mutate Bull identity, lineage, owner/camp affiliations, media or match history. Those require domain-specific claim/promotion policies.

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation** — IN PROGRESS
2. Community contribution schema migration/API/UI implementation
3. First permitted automated source connector/pipeline
4. Intelligence products / Matchup Intelligence analytics
5. Deferred real-data APP-004 visual QA when canonical data becomes available

## Still Deferred

- destructive identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name creation escalation policy
- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
