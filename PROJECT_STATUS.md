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

`Open Contribution -> Evidence -> Atomic Claims -> Resolution -> Verification -> Published History -> Analytics`

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
Branch: `agent/bmi-p1-008-review-backend-foundation`

### Foundation slice now deployed

Production migration:

`20260906211732_add_bullmatch_review_backend_foundation`

Production Edge Function:

`bullmatch-api` version 6

Implemented:
- claim lifecycle now supports `VERIFIED`, `SUPERSEDED`, and `WITHDRAWN` while preserving proposal/corroboration/conflict/rejection states
- explicit `review_case_claims` linkage between review cases and atomic claims
- controlled reviewer queue API
- controlled review-case detail API with claims, evidence, candidate matches/duplicates and append-only history
- reviewer evidence access remains service-mediated; restricted evidence content/storage references are not exposed
- ACTIVE ADMIN/REVIEWER authorization enforced in both Edge/API and PostgreSQL boundary
- review `command_id` idempotency
- optimistic expected-status + `case_version` stale-write rejection
- implemented commands: `CLAIM`, `UNCLAIM`, `COMMENT`, `APPROVE`, `REJECT`, `RESOLVE_CONFLICT`, `REOPEN`
- successful commands append `review_actions` and private `audit_log`
- `MERGE` / `SPLIT` execution explicitly blocked in this foundation slice
- Edge API preserves existing public data reads and ADMIN mutation path

### Canonical truth boundary

`APPROVE` currently means **atomic claim verified**. It does not directly update canonical Bull/Match/Event/Owner/Camp/Venue history.

Verified-claim promotion into canonical history remains a separate controlled operation requiring provenance/audit. This is intentional: community review does not become unrestricted canonical CRUD.

### Validation completed

Direct Production checks passed:
- `anon` cannot execute reviewer query/command RPCs
- `authenticated` cannot execute reviewer query/command RPCs
- `service_role` can execute reviewer query/command RPCs
- `review_case_claims` has RLS enabled
- rollback-only command test passed for CLAIM, version increment, idempotent replay, stale-write rejection and single audit/action record
- rollback left Production with `review_cases = 0` and `review_actions = 0`
- controlled reviewer queue returns an empty array normally on the current empty dataset

Regression coverage:
- `supabase/tests/p1_008_review_backend.sql`
- verification record: `supabase/P1-008-VERIFICATION.md`

Supabase advisors were run after DDL:
- no direct reviewer-RPC browser exposure found
- existing `bullmatch_private` RLS-enabled/no-policy INFO notices remain expected for service-only private tables
- existing Auth leaked-password-protection WARN remains outside this task
- unused-index INFO is expected on the nearly empty Production dataset; indexes were not removed merely to silence advisor output

## Exact Next Autonomous Action

Continue **BMI-P1-008** on the same Task/branch unless the current PR has already merged; after merge, create a new non-overlapping `agent/bmi-p1-008-...` continuation branch.

Next implementation order:
1. add controlled, deterministic **identity merge/split impact preview**; still no destructive execution
2. define narrowly scoped verified-claim -> canonical promotion operations with `fact_provenance` + audit and strict field/type allowlists
3. add safe semantics for `LINK_ENTITY`, `CREATE_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE`, and selected `EDIT`
4. wire the production Review Queue UI to `REVIEW_QUEUE` / `REVIEW_CASE`
5. only after impact preview + provenance rules are complete, design separately confirmed merge/split execution

Do not implement merge/split as one-click AI or community actions. Do not publish unresolved/conflicted claims.

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation** — IN PROGRESS
2. Community contribution schema migration/API/UI implementation
3. First permitted automated source connector/pipeline
4. Intelligence products / Matchup Intelligence analytics
5. Deferred real-data APP-004 visual QA when canonical data becomes available

## Still Deferred

- destructive identity merge/split execution until deterministic impact preview/provenance safeguards exist
- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
