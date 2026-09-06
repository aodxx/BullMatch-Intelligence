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
Current continuation branch: `agent/bmi-p1-008-identity-impact-preview`

### Foundation slice deployed

Production migration:

`20260906211732_add_bullmatch_review_backend_foundation`

Implemented:
- claim lifecycle supports `VERIFIED`, `SUPERSEDED`, and `WITHDRAWN` while preserving proposal/corroboration/conflict/rejection states
- explicit `review_case_claims` linkage between review cases and atomic claims
- controlled reviewer queue and review-case detail APIs
- reviewer evidence access remains service-mediated; restricted evidence content/storage references are not exposed
- ACTIVE ADMIN/REVIEWER authorization enforced in both Edge/API and PostgreSQL boundaries
- review `command_id` idempotency
- optimistic expected-status + `case_version` stale-write rejection
- commands: `CLAIM`, `UNCLAIM`, `COMMENT`, `APPROVE`, `REJECT`, `RESOLVE_CONFLICT`, `REOPEN`
- successful commands append `review_actions` and private `audit_log`
- direct MERGE/SPLIT execution remains blocked

Foundation verification:
- `anon` and `authenticated` cannot execute reviewer RPCs directly
- `service_role` can execute reviewer RPCs
- rollback-only command tests passed and retained no test review data
- regression coverage: `supabase/tests/p1_008_review_backend.sql`
- verification record: `supabase/P1-008-VERIFICATION.md`

### Identity merge/split impact preview deployed

Production migration:

`20260906212825_add_bullmatch_identity_impact_preview`

Production Edge Function:

`bullmatch-api` version 7

Implemented read-only Bull identity preview:
- accepts only `MERGE_SPLIT` review cases and currently supports `entity_type = BULL`
- returns source/target Bull summaries without performing any mutation
- reports affected aliases, match participants, distinct matches, VERIFIED/PUBLISHED matches, source mappings, fact provenance and prior identity events
- detects the hard contradiction where two proposed source Bull identities appeared as distinct participants in the same match
- reports unverified/archived source counts
- returns deterministic `impact_preview_fingerprint`
- always returns `execution_enabled: false`
- explicitly states that name similarity is not merge authority
- SPLIT remains assignment-plan-only at preview stage; no new canonical identity is created

Identity-preview validation completed against Production:
- `anon` EXECUTE = false
- `authenticated` EXECUTE = false
- `service_role` EXECUTE = true
- RPC remains `SECURITY DEFINER` with fixed empty `search_path`
- rollback-only fixture confirmed one affected match, one hard identity conflict, merge blocked, execution disabled and fingerprint present
- rollback follow-up confirmed zero retained test Bulls and zero retained test review cases
- current Production remains `bulls = 0`, `matches = 0`, `review_cases = 0`, `review_actions = 0`
- verification record: `supabase/P1-008-IDENTITY-PREVIEW-VERIFICATION.md`

Supabase advisors rerun after DDL:
- no direct identity-preview RPC exposure reported
- existing `bullmatch_private` RLS-enabled/no-policy INFO notices remain expected for intentionally service-only private tables
- existing Auth leaked-password-protection WARN remains outside this task
- unused-index INFO remains expected on the empty/nearly empty dataset; indexes were not removed merely to silence advisor output

### Canonical truth boundary

`APPROVE` currently means **atomic claim verified**. It does not directly update canonical Bull/Match/Event/Owner/Camp/Venue history.

The identity preview is advisory/read-only. It cannot merge or split identities, reassign match participants, archive Bulls, rewrite aliases, or publish claims.

Verified-claim promotion into canonical history remains a separate controlled operation requiring strict fact/type allowlists, provenance and audit.

## Exact Next Autonomous Action

Continue **BMI-P1-008** after the identity-preview PR is merged.

Next implementation order:
1. define narrowly scoped verified-claim -> canonical promotion operations with strict subject/field/type allowlists, `fact_provenance`, review-action linkage and private audit
2. add safe semantics for `LINK_ENTITY`, `CREATE_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE`, and selected `EDIT`
3. wire the production Review Queue UI to `REVIEW_QUEUE` / `REVIEW_CASE` and identity preview
4. only after preview + promotion/provenance safeguards are complete, design separately confirmed merge/split execution that requires an unchanged preview fingerprint and explicit reassignment plan

Do not implement merge/split as one-click AI or community actions. Do not publish unresolved/conflicted claims. Do not infer Bull identity from name similarity alone.

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation** — IN PROGRESS
2. Community contribution schema migration/API/UI implementation
3. First permitted automated source connector/pipeline
4. Intelligence products / Matchup Intelligence analytics
5. Deferred real-data APP-004 visual QA when canonical data becomes available

## Still Deferred

- destructive identity merge/split execution until deterministic preview, provenance and explicit reassignment safeguards exist
- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
