# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on active production foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST COMPLETE / VISUAL REBASELINE IN PROGRESS AND DEPLOYED**

## Product Direction

BullMatch is organized as:

1. **Community Data Network**
2. **Verified BullMatch Big Data**
3. **Intelligence Products**

Canonical flow:

`Open Contribution -> Evidence -> Atomic Claims -> Resolution -> Verification -> Published History -> Analytics`

Community contributors never directly overwrite canonical history.

BullMatch remains a data/statistics/research/analytics platform, not a bet-taking, wallet, settlement or payout service.

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
- BMI-APP-004 Visual Rebaseline increment 1 — DEPLOYED via PR #41
- BMI-APP-004 Verified Bull Profile imagery — DEPLOYED via PR #42
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Contribution & Trust Architecture

`docs/CONTRIBUTION-TRUST-ARCHITECTURE.md` defines how BullMatch scales data collection through the bullfighting community without uncontrolled crowdsourced CRUD.

Key rules remain:

- mobile-first task-oriented contribution flows
- AI assists data entry but does not auto-publish
- submission and atomic claim state machines are separate
- identity/duplicate checks precede new bull creation
- evidence quality is separate from contributor reputation
- reputation is multidimensional/scoped and derives from verified outcomes
- owner/camp/venue profile claims unlock scoped first-party tools but never erase verified adverse history
- community review is risk-tiered, not majority-vote truth
- Data Credit rewards verified useful contribution and is not money/betting balance/transferable value
- contributor self-service remains server-mediated

## Database Contract

Schema v0.2 remains authoritative in:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`

The production API still reads existing canonical verified/published tables. No production DDL was introduced by P1-011/P1-012 or APP-004 PR #41/#42.

## Production Infrastructure

Shared Supabase project: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`).

BullMatch-owned schemas only:
- `bullmatch`
- `bullmatch_private`

Production flow:

`GitHub Pages React app -> bullmatch-api Edge Function -> service-only RPC bridge -> BullMatch schemas`

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

No fake production Bull/Match records have been introduced.

## Visual Rebaseline — Current Production State

Canonical visual contract:
- `docs/VISUAL-SYSTEM.md`

Merged/deployed work:

### PR #41 — Sports-intelligence visual-system baseline

Implemented:
- real bull-fighting atmosphere photo in Dashboard Hero using documented CC0 source
- photograph used as atmosphere only, never as a canonical bull identity
- BM typographic product mark rather than mascot brand treatment
- scoreboard-style statistics
- action rails instead of generic rounded quick-card tiles
- dark verified Bull Profile stage
- arena-style Match Detail / VS composition
- explicit no-verified-photo participant placeholders rather than generic bull portraits
- sports/broadcast navigation treatment
- purposeful CSS reveal / hero drift / VS motion
- `prefers-reduced-motion` + responsive/mobile rules

Validation:
- PR Web App typecheck/build PASS
- controlled Production API smoke PASS
- main GitHub Pages build/deploy PASS

### PR #42 — Verified Bull Profile imagery

Implemented:
- Bull Profile consumes existing `bull.primary_image_ref`
- only HTTP(S) references render directly
- image lazy loading + async decode
- broken/missing images fall back to `ยังไม่มีภาพยืนยัน`
- no generic bull photograph is substituted for a canonical bull
- login identity mark changed from bull mascot glyph to BM monogram

Validation:
- PR Web App typecheck/build PASS
- controlled Production API smoke PASS
- main GitHub Pages build/deploy PASS

## Visual Integrity Rules

Future UI work must continue to follow:

- real bull / real venue imagery where rights permit
- never use another animal to stand in for a specific bull
- no cute/cartoon bull identity
- no generic repeated dashboard/card-template language as default
- strong typography and numbers
- sports-intelligence / broadcast-graphics energy
- evidence/data quality visually distinct from model inference
- purposeful motion only
- reduced-motion accessibility and mobile performance protection
- Matchup Intelligence remains flagship future visual language, but no prediction data is fabricated before verified analytics exist

## Current Visual Limitations

1. Production currently has no real Bull/Match records. Therefore `primary_image_ref` rendering cannot be demonstrated end-to-end with a real canonical bull without creating fake data; fake records remain prohibited.
2. Match API participants currently do not expose participant-specific verified/public image references, so Match Detail correctly keeps explicit no-photo placeholders.
3. Dashboard atmosphere currently depends on a Wikimedia thumbnail URL. Long-term production should copy approved assets into BullMatch-controlled storage after rights/source review.
4. Browser/mobile screenshot verification has not yet been completed through an available automated browser path; build/API validation has passed.

## Review Backend Status

BMI-P1-008 is **READY but ordered after completion of the current APP-004 implementation gate**, unless a backend integrity/security issue becomes more urgent.

Its re-scoped implementation must use:
- Schema v0.2 atomic claims/evidence
- Contribution & Trust risk tiers
- idempotent review commands
- conflict/supersession handling
- provenance/audit
- identity merge/split safeguards

## Exact Next Autonomous Action

Continue **BMI-APP-004** rather than restarting it.

Next implementation sequence:

1. define a verified/public participant-image read contract for Match Detail; do not expose private evidence/storage references
2. add reusable evidence-strength / data-confidence visual primitives for later matchup/profile/report surfaces
3. apply confidence/evidence primitives only where current API data can support them honestly
4. refine React-level reveal/loading transitions where CSS-only behavior is insufficient
5. perform supported browser/mobile visual verification when available without adding fake production records
6. once the APP-004 reusable system is sufficiently complete, mark APP-004 DONE and move to **BMI-P1-008 Review Backend Foundation**

## Next Engineering Gates

1. **BMI-APP-004 — finish verified imagery + evidence/confidence visual primitives** — IN PROGRESS
2. **BMI-P1-008 — Review Backend Foundation, re-scoped** — READY after APP-004 gate
3. Community contribution schema migration/API/UI implementation
4. First permitted automated source connector/pipeline
5. Intelligence products / Matchup Intelligence analytics

## Still Deferred

- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists