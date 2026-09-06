# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on top of active production foundation**

Overall status: **PRODUCTION API ACTIVE / FIRST REAL ADMIN ACTIVE / COMMUNITY BIG-DATA REBASELINE APPROVED / AUTONOMOUS HOURLY CONTINUATION ENABLED**

## Product Direction

BullMatch is now explicitly organized as three connected layers:

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
- BMI-OPS-003 Autonomous Hourly Development Continuity — DONE

## Thai Bullfighting Domain Rebaseline

The project must no longer model the domain as only `Bull + Match + Winner`.

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

Canonical domain reference:
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

## Autonomous Continuation

An hourly scheduled development task is active for BullMatch Intelligence.

The canonical continuity instructions are in:
- `docs/AUTO-RUN-RUNBOOK.md`

Each run must read repository state first, choose the next safe priority task, follow Task ID/branch/test/handoff rules, and leave an exact next action for the following run.

The owner should not need to repeatedly type “ดำเนินการต่อ” for ordinary forward progress.

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

Verified:
- Auth identity exists in project `kaanguobjhlusjvgbowt`
- email is confirmed
- exact Auth UUID is linked to `bullmatch.app_users`
- `bullmatch_api_member` reports member/ADMIN/ACTIVE
- authenticated database role check reports ADMIN authorized

For privacy and security, the public repository does not contain the owner's email, password, tokens or Auth UUID.

Runbook: `docs/FIRST-ADMIN-BOOTSTRAP.md`

## Verification Baseline

PR #33 passed its Web App CI on the merged head.

Main GitHub Actions run #26 passed:
- locked dependency install — PASS
- TypeScript/Vite production build — PASS
- Production Dashboard API smoke test — PASS (HTTP 200)
- `/me` without user token — PASS (HTTP 401)
- Configure Pages — PASS
- Upload Pages artifact — PASS
- Deploy GitHub Pages — PASS

Database rollback tests also proved:
- browser roles cannot invoke service bridge RPCs
- ACTIVE ADMIN command succeeds
- REVIEWER mutation is rejected
- audit actor/entity linkage survives the bridge
- no test fixtures remain

## Next Autonomous Engineering Gates

Unless a production/security blocker is more urgent, use this order:

1. **BMI-P1-010 — Product Rebaseline v0.3: Community Big Data + Intelligence**
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
