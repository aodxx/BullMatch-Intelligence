# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on active production foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST ARCHITECTURE COMPLETE / VISUAL REBASELINE NEXT**

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
- BMI-P1-012 Contribution & Trust Architecture — COMPLETE IN PR #40
- BMI-APP-001 Frontend Foundation — DONE via PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE via PR #31
- BMI-APP-003 Production API Wiring — DONE via PR #33
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Contribution & Trust Architecture Result

`docs/CONTRIBUTION-TRUST-ARCHITECTURE.md` now defines how BullMatch can scale data collection through the bullfighting community without turning the database into uncontrolled crowdsourced CRUD.

Key decisions:

- mobile-first contribution entry points instead of one large database form
- program/poster/result-board photo flow with parsing + compact confirmation
- fast match-result flow for contributors at the venue
- bull identity/profile, comparison day, correction and URL/video-reference contribution flows
- AI acts as a form assistant, not an auto-publisher
- submission and atomic-claim state machines are separate
- likely existing bull identities are shown before allowing new bull creation
- evidence quality is evaluated separately from contributor reputation
- reputation is multidimensional and scoped by topic/venue/region
- reputation derives from verified outcomes, not self-declared expertise or raw volume
- contributor public profile is opt-in and excludes private contact/internal moderation data
- contributors can see accepted/rejected/conflicted outcomes through a feedback loop
- owner/camp/venue representation claims can unlock scoped first-party tools but never erase adverse verified history
- venue operators are treated as strategic primary-data partners
- anti-spam design covers duplicate flooding, evidence reuse, suspicious coordination and rate/routing controls
- community review is risk-tiered; it is not majority voting
- Data Credit is earned from verified useful outcomes only
- `Contribute to Unlock` remains a future access mechanism, not money/betting balance/transferable token
- contributor self-service API remains server-mediated; authenticated identity is derived from validated tokens

## Database Contract

Schema v0.2 remains authoritative in:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`

The production API still reads the existing canonical verified/published tables. No production DDL/API/runtime changes were made in P1-011 or P1-012.

## Production Infrastructure

Shared Supabase project: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`).

BullMatch-owned schemas only:
- `bullmatch`
- `bullmatch_private`

Production flow:

`GitHub Pages React app -> bullmatch-api Edge Function -> service-only RPC bridge -> BullMatch schemas`

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

No fake production bull/match records have been introduced.

## Visual / UX Mandate

The next priority is the production visual rebaseline.

Mandatory direction:
- real bull and real venue imagery where rights permit
- no cute/cartoon bull identity
- no generic repeated card/dashboard template language
- sports-intelligence / broadcast-graphics energy
- strong typography and numbers
- image-led bull identity
- layered imagery, motion, transitions, stat reveals and timelines where useful
- flagship Matchup Intelligence visual language
- reduced-motion accessibility and mobile performance protection

This must become a reusable system, not page-by-page decoration.

## Review Backend Status

BMI-P1-008 is now **READY but intentionally ordered after BMI-APP-004** unless a backend integrity/security need becomes more urgent.

Its re-scoped implementation must use:
- Schema v0.2 atomic claims/evidence
- Contribution & Trust risk tiers
- idempotent review commands
- conflict/supersession handling
- provenance/audit
- identity merge/split safeguards

## Validation for BMI-P1-012

- contract aligned to PRD v0.3 and Schema v0.2
- no production migration/API/runtime change
- no secrets/personal credentials added
- no fabricated production records
- canonical history remains protected from direct community writes
- exact reputation score/credit economics intentionally deferred until real contribution behavior can be measured

PR: **#40 — `[BMI-P1-012] Define Contribution & Trust Architecture`**

## Exact Next Autonomous Action

Start **BMI-APP-004 — Visual Design Rebaseline: Real Bull / Sports Intelligence / Motion**.

Required startup actions:
1. inspect current `apps/web` structure/styles/components
2. claim dedicated branch
3. define reusable visual system before broad page edits
4. use real bull/venue imagery only where rights/source permit; do not fabricate production identities
5. establish typography, layout, surfaces, image treatment, data visualization and motion grammar
6. implement production-facing components/screens, not mockups only
7. verify mobile responsiveness, loading/error/empty states and reduced-motion behavior
8. run web build/tests and fix ordinary issues

## Next Engineering Gates

1. **BMI-APP-004 — Visual Design Rebaseline** — READY
2. **BMI-P1-008 — Review Backend Foundation, re-scoped** — READY after visual task by execution order
3. Community contribution schema migration/API/UI implementation
4. First permitted automated source connector/pipeline
5. Intelligence products / Matchup Intelligence analytics

## Still Deferred

- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
