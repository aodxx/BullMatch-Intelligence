# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on top of active production foundation**

Overall status: **PRODUCTION API ACTIVE / FIRST REAL ADMIN ACTIVE / COMMUNITY BIG-DATA PRODUCT CONTRACT v0.3 READY FOR INTEGRATION / AUTONOMOUS CONTINUATION ACTIVE**

## Product Direction

BullMatch is explicitly organized as three connected layers:

1. **Community Data Network** — people in the Thai bullfighting ecosystem contribute observations, corrections, programs, results, identity evidence, lineage claims, photos/links and local knowledge.
2. **Verified BullMatch Big Data** — evidence, AI assistance, entity resolution, contributor reputation and controlled review convert submissions into auditable facts.
3. **Intelligence Products** — verified history supports bull profiles, matchup analysis, advanced statistics, reports, APIs and venue/camp/media tools.

Core principle:

`Open Contribution -> Evidence -> Atomic Claims -> Entity Resolution -> Corroboration/Review -> Verified Facts -> Published History -> Analytics`

Community contributors do not directly overwrite canonical history.

BullMatch remains a data/statistics/research/analytics product. It is not a bet-taking, wallet, odds-settlement or payout service.

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE via PR #29
- BMI-P1-009 Thai Bullfighting Domain Rebaseline — DONE via PR #36
- BMI-APP-001 Frontend Foundation & First Screens — DONE via PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE via PR #31
- BMI-APP-003 Controlled API + Production Data Wiring — DONE via PR #33
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Current Contract Work

### BMI-P1-010 — Product Rebaseline v0.3

Status: **REVIEW / READY TO MERGE**
Branch: `agent/bmi-p1-010-product-rebaseline-v0-3`

`PRD.md` has been re-authored as the community Big Data + intelligence product contract.

The contract now defines:

- three-layer product architecture: Community Data Network / Verified Big Data / Intelligence Products
- open contribution with closed canonical truth
- atomic claims and evidence-first verification
- Thai bullfighting temporal/domain lifecycle requirements
- contributor roles, feedback and multidimensional reputation
- `Contribute to Unlock` readiness without rewarding raw submission volume
- monetization lanes: Pro, reports, API, venue/camp/media tools and compatible sponsorship
- legal boundary excluding bet-taking, wallet, settlement and payout functions
- Matchup Intelligence as explainable evidence-aware analytics rather than guaranteed picks
- real-bull / real-venue sports-intelligence visual and motion requirements
- security, scalability, free-plan and accessibility requirements
- explicit next contract for additive Database Schema v0.2

No production schema, API, secrets or production data were changed by P1-010.

## Thai Bullfighting Domain Rebaseline

The project must not model the domain as only `Bull + Match + Winner`.

The approved domain baseline includes:

- stable bull identity independent of name
- historical aliases
- physical/color/marking/horn observations
- fighting-style / `ทางชน` observations with evidence
- lineage claims with provenance
- owner/camp/keeper relationships over time
- comparison day / `วันเปรียบ`
- proposed/rejected/accepted pairings
- versioned match programs and amendments
- actual match occurrence, result, duration and reason
- venue/event rule versions
- recovery/rest and subsequent history
- evidence uncertainty and claim-level verification

Canonical domain references:
- `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`
- `docs/THAI-BULLFIGHTING-FIELD-VALIDATION.md`

## Visual / UX Mandate

Future BullMatch UI must not default to cartoon bulls, cute iconography or repetitive generic dashboard templates.

Approved direction:

- real bull photography and real venue atmosphere where rights/source permit
- bull identity centered on real animal imagery
- high-energy sports-intelligence / broadcast-graphics presentation
- strong typography, statistics and purpose-built indicators
- layered imagery, motion, matchup transitions, stat reveals, timelines and animated data visualization where useful
- `Matchup Intelligence` as a flagship visual experience
- reusable motion language and image treatment rather than page-by-page gimmicks
- reduced-motion accessibility and mobile-performance protection

This requirement applies to the production application, not to generating decorative images in chat.

## Production Infrastructure

Selected shared Supabase host: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`)

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

### Production API Boundary

Applied migration:
`20260906092707_add_bullmatch_controlled_api_bridge`

Deployed Edge Function:
- `bullmatch-api`
- version 1
- status ACTIVE

Flow:

`GitHub Pages React app -> bullmatch-api Edge Function -> service-only public RPC bridge -> bullmatch/bullmatch_private domain`

The browser never receives a service-role key and cannot execute the three bridge RPCs directly. `PUBLIC`, `anon`, and `authenticated` have no EXECUTE permission on them; only `service_role` does.

Public API returns verified/published data only. Protected requests validate the Supabase Auth user before resolving BullMatch membership or accepting commands.

ADMIN mutations remain protected twice:
1. Edge Function requires ACTIVE ADMIN membership.
2. Existing BullMatch domain functions independently enforce `require_admin()` and write the private audit trail.

## Production Web App

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

Live data surfaces:
- Dashboard counts
- Bull list/search
- Bull Profile
- W/L/D statistics and win rate
- recent form
- Bull match history/opponents
- published Matches list
- Match Detail

Signed-in role comes from `/me` using `bullmatch.app_users`.

UI authorization:
- Manual Entry: ACTIVE ADMIN
- Review shell: ACTIVE ADMIN or REVIEWER
- authenticated alone grants no BullMatch application role

Current Production Bull/Match records intentionally remain empty. Visible zero/empty states are real Production state, not fabricated sample data.

## First Production ADMIN

The first intended real Supabase Auth account has been bootstrapped as BullMatch `ADMIN / ACTIVE`.

For privacy and security, the public repository does not contain the owner's email, password, tokens or Auth UUID.

Runbook: `docs/FIRST-ADMIN-BOOTSTRAP.md`

## Verification Baseline

P1-010 is documentation/product-contract only.

Checks performed in this task:

- required repository collaboration/status/runbook documents read before work
- no conflicting P1-010 branch found before claim
- PRD v0.3 checked against the approved Thai bullfighting domain baseline and autonomous product direction
- legal/product boundary preserved
- no migration/API/runtime changes introduced
- no production records fabricated
- no secrets or personal credentials added

Existing production baseline remains the PR #33 verified state.

## Next Autonomous Engineering Gates

Unless a production/security blocker is more urgent, use this order:

1. Merge BMI-P1-010 after PR review/checks
2. **BMI-P1-011 — Database Schema v0.2: Community Claims + Temporal Domain**
3. **BMI-P1-012 — Contribution & Trust Architecture**
4. **BMI-APP-004 — Visual Design Rebaseline: Real Bull / Sports Intelligence / Motion**
5. **BMI-P1-008 — Review Backend Foundation, re-scoped to the new contribution model**
6. Community contribution implementation
7. First permitted automated source connector/pipeline
8. Intelligence products and advanced matchup analytics

Detailed rules and blocking behavior: `docs/AUTO-RUN-RUNBOOK.md`.

## Still Deferred / Requires Later Resolution

- AI provider selection
- first production source selection/compliance approval
- venue-specific field validation for uncertain terminology/rules
- real community incentive pricing/credit economics until contribution behavior can be measured
