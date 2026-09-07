# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS / POSTGRES ADAPTER MERGED / ROLLBACK-ONLY DB CONFORMANCE VALIDATED**

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

V1 supports evidence-backed correction/observation for an existing VERIFIED Bull using a public HTTP(S) reference for `home_province`, `home_district`, `color_description`, and `breed_description`.

Delivered through PR #59–#62 with server-derived actor identity, REVIEW_REQUIRED atomic claims first, separate controlled promotion, idempotent intake and no AI auto-publish.

Deferred: public self-signup/onboarding policy, direct image/file evidence upload, broader contribution types, and real-data success-path UI QA when genuine VERIFIED data exists.

## BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation

Status: **IN PROGRESS**  
Owner: Primary Maintainer  
Latest merged PR: **#68 — PostgreSQL ingestion + persisted run-state adapters**  
Current branch: `agent/bmi-p2-001-db-conformance`  
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Merged connector foundation — PR #64–#66

Delivered:

- source-agnostic connector execution
- APPROVED/ACTIVE/polling gates
- source/run/correlation/connector identity checks
- safe checkpoint advancement
- approved-only runtime registry
- persistence-neutral SOURCE_MONITORING run state
- atomic normalized item + evidence + checkpoint persistence contract
- `(source_id, dedupe_key)` idempotency
- exact replay without duplicate evidence
- conflicting replay rejection
- stale cursor rejection and full rollback

Required invariant:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

### PostgreSQL + persisted run-state mapping — PR #68 — MERGED

Implemented and CI-validated:

- `PostgresIngestionPersistence` mapped to existing `bullmatch_private.sources`, `source_runtime_state`, `source_items`, and `evidence`
- `PostgresCollectionRunStore` mapped to existing `bullmatch_private.agent_runs`
- persistence-time APPROVED + ACTIVE + polling-enabled recheck
- source/runtime row locking and stale-cursor rejection
- source item + evidence + checkpoint in one DB transaction
- normalized-envelope fingerprint under private `raw_metadata._bullmatch.normalized_envelope_fingerprint`
- `source_items.content_hash` preserved for actual source-content hashing
- evidence inserted as `PENDING`, not verified/published
- CollectionRunState input/output refs preserved in AgentRun metrics without migration
- no canonical Bull/Match/history, review, verification, promotion or publication write path

PR #68 head validation:

- shared schema/example validation — PASS
- connector conformance suite — PASS
- PostgreSQL/run-store fake-DB tests — PASS

### Rollback-only real-schema conformance — CURRENT SLICE

File: `supabase/tests/p2_001_collection_persistence_rollback.sql`

The harness was executed against the active BullMatch Supabase PostgreSQL schema using only fixed synthetic UUIDs and `.invalid` URLs.

It verifies:

- deployed `sources`, `source_runtime_state`, `source_items`, `evidence`, and `agent_runs` accept the intended adapter storage shape
- source item + evidence + checkpoint mutations inside an intentionally failed PostgreSQL subtransaction are all restored together
- the successful staging shape satisfies deployed constraints
- SOURCE_MONITORING AgentRun mapping satisfies the deployed table
- the outer transaction always rolls back
- after rollback, fixture counts in `sources`, `source_items`, `evidence`, and `agent_runs` are all **0**

No Production Bull/Match/canonical record, migration, grant, policy or persistent fixture was created.

## Exact Next Safe Slices Inside BMI-P2-001

After the rollback-only harness is integrated:

1. reusable connector fixture/conformance helpers
2. operational orchestration wrapper: approved registry -> checkpoint -> persisted run state -> connector -> atomic persistence
3. persisted source-registry provider if required by the wrapper
4. task sign-off for the source-agnostic foundation once the end-to-end synthetic orchestration path is deterministic

A real source-specific connector remains outside BMI-P2-001 until an explicit source/compliance decision identifies permitted access method, rate limits, retention/rights constraints and source-specific tests.

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

Integrate the rollback-only conformance harness, then continue `BMI-P2-001` on a fresh branch from `main` with reusable connector fixture helpers and the source-agnostic operational orchestration wrapper. Do **not** select, scrape or poll a real external source.
