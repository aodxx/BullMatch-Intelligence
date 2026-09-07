# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS / ATOMIC PERSISTENCE SLICE IN REVIEW**

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
Current branch: `agent/bmi-p2-001-persistence-contract`
Current PR: **#66 — `[BMI-P2-001] Define atomic ingestion persistence boundary`**
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Merged baseline — PR #64

Delivered:
- source-agnostic `Connector` protocol + validated poll runner
- APPROVED + ACTIVE + polling-enabled policy gates
- connector/source/run/correlation identity enforcement
- duplicate `dedupe_key` rejection inside a poll
- safe checkpoint advancement only after valid output
- deterministic connector conformance tests

### Merged registry/run-state slice — PR #65

Delivered:
- validated `ApprovedSourceRegistry`
- runtime registry excludes `REVIEW_REQUIRED`/`BLOCKED`
- approved-but-paused/polling-disabled sources remain non-pollable
- persistence-neutral `CollectionRunState`
- existing AgentRun contract reused for SOURCE_MONITORING
- source-policy caps on poll item/request limits
- deterministic run metrics/output refs and terminal states
- contract-valid failure path
- AgentRun -> AgentError schema reference repair

Validation: shared contract/schema/example + connector registry/run-state tests PASS.

### Current atomic persistence slice — PR #66

Implemented on branch:
- persistence-neutral `IngestionPersistenceAdapter` / `IngestionTransaction` protocols
- `persist_poll_execution()` accepts validated PollExecution only
- source/correlation identity rechecked at persistence boundary
- normalized source item + evidence staging before checkpoint write
- source-item idempotency key `(source_id, dedupe_key)`
- exact replay remains idempotent without duplicate evidence
- same key with different normalized payload is rejected instead of overwritten
- unsafe checkpoint may store evidence while retaining previous cursor
- stale expected cursor is rejected before staging
- transaction begin itself is side-effect free
- staging/checkpoint exception rolls back entire batch
- deterministic in-memory adapter models the future DB transaction semantics for tests only

Required persistence invariant:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

No persistence API in this slice can write canonical Bull/Match/history, verification or publication state.

Validation scope:
- shared contract/schema/example validation
- existing connector + registry/run-state tests
- new atomic persistence tests for safe/unsafe checkpoint, replay, conflict rollback, stage failure and stale cursor

Safety preserved:
- no real source selected or contacted
- no network connector added
- no Production DB adapter or migration
- no source secret values loaded
- no canonical write capability
- synthetic UUIDs and `.invalid` URLs only in tests
- no AI-provider dependency

## Exact Next Safe Slices Inside BMI-P2-001

After PR #66 integration:

1. persisted AgentRun/run-state adapter compatible with `CollectionRunState`
2. PostgreSQL/Supabase ingestion adapter mapped to existing BullMatch private ingestion/runtime tables
3. rollback-only database conformance tests proving dedupe/evidence/checkpoint atomicity
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

Check PR #66 CI/integration. If merged, continue `BMI-P2-001` on a fresh branch from `main` with the persisted AgentRun/run-state adapter and database-adapter contract mapping. Do **not** select or poll a real external source inside BMI-P2-001.
