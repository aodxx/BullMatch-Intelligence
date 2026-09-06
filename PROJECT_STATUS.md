# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on active production foundation**

Overall status: **PRODUCTION API ACTIVE / COMMUNITY BIG-DATA PRODUCT CONTRACT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST ARCHITECTURE NEXT**

## Product Direction

BullMatch is organized as three connected layers:

1. **Community Data Network** — people in the Thai bullfighting ecosystem contribute observations, corrections, programs, results, identity evidence, lineage claims, photos/links and local knowledge.
2. **Verified BullMatch Big Data** — evidence, AI assistance, entity resolution, contributor reputation and controlled review convert submissions into auditable facts.
3. **Intelligence Products** — verified history supports bull profiles, matchup analysis, advanced statistics, reports, APIs and venue/camp/media tools.

Core principle:

`Open Contribution -> Evidence -> Atomic Claims -> Entity Resolution -> Corroboration/Review -> Verified Facts -> Published History -> Analytics`

Community contributors do not directly overwrite canonical history.

BullMatch remains a data/statistics/research/analytics product, not a bet-taking, wallet, odds-settlement or payout service.

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
- BMI-P1-011 Database Schema v0.2 — COMPLETE IN PR #39
- BMI-APP-001 Frontend Foundation & First Screens — DONE via PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE via PR #31
- BMI-APP-003 Controlled API + Production Data Wiring — DONE via PR #33
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Database Schema v0.2 Result

`docs/DATABASE-SCHEMA.md` is now the implementation contract for Community Claims + Thai Bullfighting Temporal Domain.

It preserves the deployed canonical API/table foundation and adds a migration-ready design for:

- contributor participation profiles separate from privileged app roles
- community submissions with idempotent client keys and moderation status
- community-origin evidence without fabricating external source items
- extraction runs that can originate from source items or community evidence
- atomic claims from AI/source/community/operator/system origins
- claim-level evidence, supersession, conflict and review linkage
- temporal bull affiliations: owner/co-owner/camp/breeder/keeper/handler/trainer
- people/aliases for relevant non-owner actors
- real-bull media and private durable external identifiers
- physical/color/marking/horn/yod observations
- evidence-backed fighting-style / `ทางชน` observations
- verified lineage/parentage graph
- first-class `วันเปรียบ` comparison sessions and entries
- pairing lifecycle separated from actual matches
- versioned event programs and amendments
- versioned venue/event rule profiles
- multidimensional contributor reputation derived from verified outcomes
- profile-representation claims without authority to erase verified adverse history
- anti-abuse/quality signals
- controlled fact promotion with provenance/audit

`docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md` defines additive migration slices and compatibility/rollback rules.

`docs/DATABASE-SCHEMA-NAMESPACE-OVERLAY.md` is now historical because v0.2 uses `bullmatch` / `bullmatch_private` directly.

## Key Production Compatibility Findings

The existing production foundation remains active and unchanged in BMI-P1-011.

Current API still reads verified/published records from the established canonical tables including:

- `bullmatch.bulls`
- `owners`, `camps`, `venues`, `events`
- `matches`, `match_participants`, `match_results`
- existing statistics/views

The v0.2 contract intentionally does not rename/drop those objects or change their IDs/function signatures.

Two existing private assumptions were identified as blockers for community contribution and are handled additively in the migration plan:

1. `bullmatch_private.evidence.source_item_id` is currently mandatory.
2. `bullmatch_private.claims.extraction_run_id` is currently mandatory.

No production DDL was applied in P1-011.

## Production Infrastructure

Selected shared Supabase host: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`).

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

Production API flow remains:

`GitHub Pages React app -> bullmatch-api Edge Function -> service-only RPC bridge -> bullmatch/bullmatch_private`

Browser roles do not receive service-role credentials or direct privileged RPC execution.

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

Current production Bull/Match records remain intentionally empty; no sample data was fabricated.

## Visual / UX Mandate

Future UI work must use real bull / real venue imagery where rights permit, high-energy sports-intelligence presentation, strong typography and purposeful motion. Cartoon/cute bull identity and generic repeated dashboard templates are not the approved direction.

`Matchup Intelligence` remains the flagship future visual experience, with reduced-motion/mobile-performance safeguards.

## Validation for BMI-P1-011

Completed:

- read mandatory collaboration/status/runbook/product/domain documents
- verified no conflicting P1-011 branch ownership before claim
- inspected current production migrations for canonical entities, matches/results, evidence/claims and service API bridge
- documented additive/backward-compatible schema changes instead of destructive replacement
- no production migration applied
- no API/runtime code changed
- no production records fabricated
- no secrets or personal credentials added
- shared-Supabase schema isolation preserved

PR: **#39 — `[BMI-P1-011] Define Database Schema v0.2`**

## Exact Next Autonomous Action

Start **BMI-P1-012 — Contribution & Trust Architecture** after PR #39 integration.

Required focus:

1. define field-friendly contribution flows for photo/program/result/link/text/correction inputs
2. define AI-assisted extraction + user confirmation without bypassing claim verification
3. define submission, claim, moderation and review state transitions
4. define contributor reputation dimensions and event-to-score policy boundaries
5. define anti-spam, duplicate flooding, evidence reuse and abuse controls
6. define owner/camp/venue profile claims and restricted management rights
7. define verified-contribution credit / `Contribute to Unlock` readiness without rewarding raw volume
8. define API/security boundaries for contributor self-service
9. leave BMI-P1-008 review backend re-scoped to these contracts

## Next Engineering Gates

1. **BMI-P1-012 — Contribution & Trust Architecture** — READY after P1-011 merge
2. **BMI-APP-004 — Visual Design Rebaseline**
3. **BMI-P1-008 — Review Backend Foundation, re-scoped**
4. Community contribution migration/API/UI implementation
5. First permitted automated source connector/pipeline
6. Intelligence products and advanced matchup analytics

## Still Deferred / Requires Later Resolution

- AI provider selection
- first production source selection/compliance approval
- venue-specific field validation for uncertain terminology/rules
- real contributor credit economics until actual contribution/review behavior can be measured
