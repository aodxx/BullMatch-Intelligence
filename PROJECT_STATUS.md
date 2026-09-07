# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS / ATOMIC PERSISTENCE SLICE MERGED**

## Product Direction / Truth Boundary

BullMatch remains:

1. **Community Data Network**
2. **Verified BullMatch Big Data**
3. **Intelligence Products**

Canonical flow:

`Community Contribution or Permitted Source -> Evidence -> Atomic Claims -> Entity Resolution -> Review/Verification -> Controlled Promotion -> Published History -> Analytics`

Neither contributors nor automated collectors may directly overwrite canonical Bull/Match history. BullMatch is a data/statistics/research/analytics product, not a bet-taking, wallet, odds-settlement or payout service.

## Completed Implementation Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE — PR #16
- BMI-P1-002 Core Database — DONE — PR #18
- BMI-P1-004 Authorization — DONE — PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE — PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE — PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE — PR #29
- BMI-P1-008 Review Backend Foundation — COMPLETE — PR #50–#56
- BMI-P1-009 Thai Bullfighting Domain Rebaseline — DONE — PR #36
- BMI-P1-010 Product Rebaseline v0.3 — DONE — PR #38
- BMI-P1-011 Database Schema v0.2 — DONE — PR #39
- BMI-P1-012 Contribution & Trust Architecture — DONE — PR #40
- BMI-P1-013 Community Contribution Intake V1 — COMPLETE — PR #59–#62
- BMI-APP-001 through BMI-APP-004 — COMPLETE implementation gates
- BMI-OPS-001 through BMI-OPS-003 — COMPLETE

Production app: `https://aodxx.github.io/BullMatch-Intelligence/`

No fake Production Bull/Match/review/community data has been retained for testing.

## BMI-P1-013 — Community Contribution V1

Status: **IMPLEMENTATION GATE COMPLETE**
Contract: `docs/COMMUNITY-CONTRIBUTION-V1.md`

V1 supports evidence-backed correction/observation for an existing VERIFIED Bull using a public HTTP(S) reference for:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Delivered:
- PR #59 community origin/storage compatibility
- PR #60 controlled authenticated submission API
- PR #61 own-record-only `MY_SUBMISSIONS` projection
- PR #62 mobile Community contribution UI deployed to GitHub Pages

Preserved boundaries:
- actor derived server-side
- no contributor ADMIN/REVIEWER privilege
- no direct private/canonical browser writes
- REVIEW_REQUIRED atomic claims first; canonical promotion separate
- idempotent intake
- no AI auto-publish

Deferred:
- public self-signup/onboarding policy
- direct image/file evidence upload
- program/result/comparison-day/new-Bull contribution types
- genuine success-path UI verification until real VERIFIED canonical Bull data exists

## BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation

Status: **IN PROGRESS**
Owner: Primary Maintainer
Latest merged PR: **#66 — `[BMI-P2-001] Define atomic ingestion persistence boundary`**
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Merged baseline — PR #64

Delivered source-agnostic connector execution, APPROVED/ACTIVE/polling policy gates, source/run/correlation identity enforcement, per-poll dedupe rejection, safe checkpoint advancement, deterministic tests and shared-contract CI.

### Merged registry/run-state slice — PR #65

Delivered approved runtime source registry, pollability gates, persistence-neutral `CollectionRunState`, SOURCE_MONITORING AgentRun contract reuse, source policy request caps, deterministic run metrics/terminal states and standards-resolvable AgentRun -> AgentError contract reference.

Validation: shared contracts/examples and connector registry/run-state tests PASS.

### Merged atomic persistence slice — PR #66

Delivered:
- persistence-neutral `IngestionPersistenceAdapter` / `IngestionTransaction` protocols
- `persist_poll_execution()` after validated connector output
- source/correlation identity recheck at persistence boundary
- normalized item + evidence staging before checkpoint commit
- `(source_id, dedupe_key)` idempotency
- exact replay without duplicate evidence
- conflicting same-key payload rejection instead of overwrite
- unsafe checkpoint evidence persistence with previous cursor retained
- stale expected cursor rejection before staging
- side-effect-free transaction begin and full rollback on failure
- request-compatible persisted cursor shape (`strategy + value` only); transient `checkpoint_safe` is never persisted
- deterministic in-memory adapter for conformance only

CI initially exposed the cursor-shape mismatch during exact replay. The defect was fixed before merge and a regression assertion was added.

Validation before merge:
- shared schema/example validation — PASS
- connector runner tests — PASS
- registry/run-state tests — PASS
- atomic persistence tests — PASS

Required persistence invariant:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

No connector/orchestration/persistence API can write canonical Bull/Match/history, verification or publication state.

## Exact Next Safe Slices Inside BMI-P2-001

1. persisted AgentRun/run-state adapter compatible with `CollectionRunState`
2. PostgreSQL/Supabase ingestion adapter mapped to existing `bullmatch_private` ingestion/runtime tables
3. rollback-only database conformance tests proving item/evidence/checkpoint atomicity
4. reusable connector fixture helpers
5. operational orchestration wrapper linking approved registry -> run state -> connector -> persistence without selecting a real source

A real source-specific connector remains outside this foundation until an explicit source/compliance decision identifies permitted access method, rate limits, retention/rights constraints and source-specific tests.

## Deferred / External-Decision Items

- first Production source selection and compliance approval
- open/public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name escalation
- venue-specific terminology requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing

## Exact Next Autonomous Action

Continue `BMI-P2-001` on a fresh branch from `main` with the persisted AgentRun/run-state adapter and PostgreSQL/Supabase adapter contract mapping to existing BullMatch-private ingestion/runtime tables. Use rollback-only/synthetic conformance testing; do **not** select or poll a real external source.
