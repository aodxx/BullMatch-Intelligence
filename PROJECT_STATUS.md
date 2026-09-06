# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Community / Domain Rebaseline on active production foundation**

Overall status: **PRODUCTION API ACTIVE / PRODUCT v0.3 COMPLETE / DATABASE SCHEMA v0.2 COMPLETE / CONTRIBUTION & TRUST COMPLETE / VISUAL REBASELINE DEPLOYABLE / REVIEW BACKEND NEXT**

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
- BMI-APP-004 Visual Design Rebaseline — DONE via PR #41
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

## Visual Design Rebaseline Result

PR #41 established a production-facing BullMatch visual system instead of another generic rounded-card dashboard.

Implemented:

- `apps/web/src/visual-system.css` loaded after legacy styles for additive/reversible rollout
- real bull-fighting atmosphere photography on the Dashboard hero with documented CC0 usage
- atmosphere imagery is explicitly not presented as a Thai venue, canonical bull or verified event
- brand mark is typography-led rather than a cute/cartoon bull mascot
- production statistics use scoreboard/data-broadcast treatment
- shortcut actions use editorial/action rails rather than repeated tiles
- Bull Profile becomes a dark identity stage and generic bull SVG is not presented as the real animal
- Match Detail uses arena/VS composition and does not present a generic bull glyph as participant identity
- sports-intelligence typography/navigation/data-surface language
- purposeful hero/score/VS motion
- `prefers-reduced-motion` handling and mobile adaptations
- `docs/VISUAL-SYSTEM.md` is the reusable visual/motion/image contract

Validation:

- GitHub Actions Web App workflow run #32: PASS
- Typecheck and build: PASS
- controlled production API smoke test: PASS
- no Supabase migration, Edge Function, RPC, auth or API behavior changed
- no production Bull/Match data fabricated
- no false bull identity image introduced

Important image boundary:

- The existing public Bull API already returns `bull.primary_image_ref` for a canonical verified bull.
- PR #41 intentionally does not fake this binding through CSS or atmosphere imagery.
- React-level rendering of `primary_image_ref`, broken-image behavior, signed/allowed media URLs and participant-specific Match images are now tracked as `BMI-APP-005`.
- Until that binding exists, the UI must remain explicit that no verified image is available rather than substituting another bull.

## Contribution & Trust Architecture

`docs/CONTRIBUTION-TRUST-ARCHITECTURE.md` remains the contract for mobile-first community contribution, AI-assisted confirmation, atomic claims, scoped reputation, anti-abuse controls, profile claims, community review boundaries and Data Credit / Contribute-to-Unlock readiness.

Canonical history remains closed to direct community writes.

## Database Contract

Schema v0.2 remains authoritative in:
- `docs/DATABASE-SCHEMA.md`
- `docs/DATABASE-SCHEMA-V0.2-MIGRATION-PLAN.md`

The production API still reads existing verified/published canonical tables. No production community migration has been applied yet.

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

## Review Backend Status

**BMI-P1-008 — Review Backend Foundation is now the highest-priority READY engineering task.**

It was originally operator-centric and was deliberately delayed until Schema v0.2 + Contribution & Trust contracts existed.

The re-scoped implementation must now support:

- review-case read/claim/unclaim operations
- idempotent review commands
- optimistic concurrency / expected case version
- evidence and atomic claim context
- claim-level accept/reject/conflict/supersede decisions
- contributor/community risk context
- controlled verified-claim promotion with provenance/audit
- merge/split preview safeguards for identity work
- no direct publication by AI/community contributors

## Exact Next Autonomous Action

Start **BMI-P1-008 — Review Backend Foundation, re-scoped**.

Required startup actions:

1. inspect current `bullmatch.review_cases`, `review_actions`, private claims/evidence/provenance migrations and current API bridge
2. claim a dedicated `agent/bmi-p1-008-...` branch
3. define the minimum review command/API contract against Schema v0.2 and Contribution & Trust risk tiers
4. implement idempotent + optimistic-concurrency review operations without weakening ADMIN/REVIEWER authorization
5. keep evidence/private tables server-only
6. add migration/tests and update Edge API only where required
7. preserve existing public API behavior
8. run database/security/API/web checks relevant to changed surfaces

## Next Engineering Gates

1. **BMI-P1-008 — Review Backend Foundation, re-scoped** — READY
2. Community contribution schema migration/API/UI implementation
3. **BMI-APP-005 — Verified Bull Identity Image Binding** when the UI/API track is active
4. First permitted automated source connector/pipeline
5. Intelligence products / Matchup Intelligence analytics

## Still Deferred

- AI provider selection
- first production source selection/compliance approval
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds and pricing until real usage data exists
