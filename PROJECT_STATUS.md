# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Verified Database + Community Review Foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST COMPLETE / VISUAL REBASELINE COMPLETE / REVIEW BACKEND NEXT**

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

No fake Production Bull/Match records have been introduced.

## BMI-APP-004 — Completed Visual Rebaseline

Canonical visual contract:
- `docs/VISUAL-SYSTEM.md`

### Delivered production system

PR #41 established the sports-intelligence baseline:
- documented real bull-fighting atmosphere image with rights/source attribution
- atmosphere photography never presented as a canonical bull identity
- BM product mark rather than mascot branding
- scoreboard-style statistics and stronger typography
- action rails rather than generic repeated rounded cards
- dark verified Bull Profile stage
- arena-style Match Detail / VS composition
- purposeful reveal / hero drift / VS motion
- reduced-motion and mobile-responsive safeguards

PR #42 added canonical Bull Profile imagery:
- `bull.primary_image_ref` rendering through an HTTP(S)-only safe image component
- lazy loading / async decoding
- broken/missing images fall back to explicit `ยังไม่มีภาพยืนยัน`
- no substitute animal is used for a specific bull

PR #46 reconciled the verified/public Match participant-image contract:
- canonical `public.bullmatch_api_public_query(...)` remains the single service-only read bridge
- Match/MATCHES participant payloads include canonical `primary_image_ref`
- duplicate concurrent v2 RPC was removed
- `anon` / `authenticated` cannot execute the RPC directly; `service_role` can
- repository migration history was reconciled to Production
- pgTAP contract coverage added

PR #47 connected Match Detail to verified participant imagery:
- each participant renders its own `primary_image_ref`
- missing/invalid/broken references keep an explicit no-verified-image state
- match participant image treatment includes sports/arena crop, contrast, motion and reduced-motion handling

PR #48 added evidence-aware data coverage UI:
- reusable `DataCoverageRail`
- Bull Profile reports VERIFIED record state, published-history count, statistical sample size and primary-image availability
- Match Detail reports VERIFIED/PUBLISHED state, participant snapshot count and usable image-reference coverage
- no synthetic confidence percentage, odds or unexplained prediction score is created

### Validation

For PR #41, #42, #46, #47 and #48:
- relevant Web App typecheck/build passed
- controlled Production API smoke passed
- merged production-facing UI increments passed GitHub Pages build/deploy where applicable

Supabase participant-image boundary was also verified directly:
- canonical public RPC exists
- duplicate v2 RPC is absent
- `anon` EXECUTE = false
- `authenticated` EXECUTE = false
- `service_role` EXECUTE = true
- canonical function contains participant `primary_image_ref`

Supabase advisors were run after the contract reconciliation. No participant-image-specific security exposure was found. Existing RLS-with-no-policy INFO findings are on intentionally private `bullmatch_private` tables. Existing leaked-password-protection WARN is an Auth configuration item outside APP-004. Performance findings were unused-index INFO on the new/near-empty dataset; indexes were not removed merely to silence advisor output.

## APP-004 Deferred Real-Data Visual QA

APP-004 implementation is complete, but one QA item remains intentionally deferred rather than fabricating Production data:

- Production currently has no real VERIFIED/PUBLISHED Bull/Match rows, so real-image Bull Profile / Match Detail states cannot be demonstrated end-to-end with canonical records yet.
- The current execution environment did not provide a supported browser path for visual screenshot inspection of GitHub Pages.
- Build, API smoke and Pages deployment validation passed.

When the first real VERIFIED/PUBLISHED Bull/Match data exists, run a non-mutating mobile/desktop visual QA pass covering real image, missing image, long Thai bull names and Match VS composition. **Do not create fake canonical records solely for screenshots.**

This deferred QA does not block the reusable visual-system implementation gate or the Review Backend.

## Visual Integrity Rules Going Forward

- use real bull / real venue imagery only where identity/source/rights are valid
- never use another animal as a placeholder for a specific bull
- no cute/cartoon bull identity
- avoid generic dashboard-card repetition
- preserve strong sports-intelligence / broadcast hierarchy
- distinguish verified data coverage from model inference
- do not invent confidence percentages before a defined evidence model supports them
- honor reduced-motion and mobile performance
- Matchup Intelligence remains a future explainable analytics surface, not betting UI

## Review Backend — Current Priority

### BMI-P1-008 — Review Backend Foundation

Status: **READY — HIGHEST PRIORITY NEXT TASK**

It must implement the already-approved Schema v0.2 / Contribution & Trust contracts:
- review-case API/domain operations
- idempotent review commands
- optimistic concurrency
- reviewer evidence access through a controlled boundary
- atomic claim accept/reject/conflict/supersede handling
- contributor/community review context and risk tiers
- claim promotion with provenance/audit
- identity merge/split preview safeguards

Canonical truth remains closed to direct community writes.

## Exact Next Autonomous Action

Start **BMI-P1-008 — Review Backend Foundation**.

Required startup sequence:
1. inspect current review/claim/evidence tables, functions, migrations and tests
2. claim a dedicated `agent/bmi-p1-008-...` branch
3. define minimal server-mediated Review API contracts before UI changes
4. enforce ACTIVE ADMIN/REVIEWER authorization at server/database boundaries
5. make commands idempotent and concurrency-safe
6. preserve source evidence/provenance and append-only audit behavior
7. never promote unresolved/unverified submissions directly to canonical history
8. run database tests, security advisors and controlled API validation
9. document exact implemented operations and any remaining blockers

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation** — READY / NEXT
2. Community contribution schema migration/API/UI implementation
3. First permitted automated source connector/pipeline
4. Intelligence products / Matchup Intelligence analytics
5. Deferred real-data APP-004 visual QA when canonical data becomes available

## Still Deferred

- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
