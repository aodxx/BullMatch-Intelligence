# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS / POSTGRES+PERSISTED RUN-STATE SLICE VALIDATED IN PR #68**

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
Current PR: **#68 — `[BMI-P2-001] Add PostgreSQL ingestion and persisted run-state adapters`**  
Current branch: `agent/bmi-p2-001-postgres-adapter`  
Previous merged PR: **#66 — atomic ingestion persistence boundary**  
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Merged connector baseline — PR #64

Delivered source-agnostic connector execution, APPROVED/ACTIVE/polling policy gates, source/run/correlation identity enforcement, per-poll dedupe rejection, safe checkpoint advancement, deterministic tests and shared-contract CI.

### Merged registry/run-state slice — PR #65

Delivered approved runtime source registry, pollability gates, persistence-neutral `CollectionRunState`, SOURCE_MONITORING AgentRun contract reuse, source-policy request caps, deterministic run metrics/terminal states and standards-resolvable AgentRun -> AgentError contract reference.

### Merged atomic persistence slice — PR #66

Delivered:

- persistence-neutral `IngestionPersistenceAdapter` / `IngestionTransaction`
- normalized item + evidence staging before checkpoint commit
- `(source_id, dedupe_key)` idempotency
- exact replay without duplicate evidence
- conflicting same-key payload rejection
- unsafe-checkpoint evidence persistence with old cursor retained
- stale expected cursor rejection before staging
- side-effect-free transaction begin and full rollback on failure
- request-compatible cursor shape (`strategy + value` only)
- deterministic in-memory conformance adapter

Required persistence invariant:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

### Validated PostgreSQL + persisted run-state slice — PR #68

Implemented:

- `PostgresIngestionPersistence` mapped to existing `bullmatch_private.sources`, `source_runtime_state`, `source_items` and `evidence`
- `PostgresCollectionRunStore` mapped to existing `bullmatch_private.agent_runs`
- persistence-time source policy recheck: APPROVED + ACTIVE + polling enabled
- source/runtime locks for checkpoint serialization
- stale expected cursor rejection before item staging
- first-poll runtime row is not created at `begin()`; checkpoint state is staged only inside the atomic transaction
- source item + evidence + checkpoint share one database transaction
- normalized-envelope fingerprint stored privately in `raw_metadata._bullmatch.normalized_envelope_fingerprint`
- `source_items.content_hash` remains reserved for actual source-content hashing
- legacy existing rows lacking the normalized fingerprint fail closed rather than being guessed as an exact replay
- ingested evidence remains `PENDING`, never VERIFIED/PUBLISHED
- CollectionRunState input/output references preserved in private AgentRun metrics namespace without a migration
- adapter has no SQL path to canonical Bull/Match/history, review decisions, verification, promotion or publication

Deterministic fake-DB conformance coverage:

- new item/evidence/checkpoint commit
- content-hash semantic preservation
- conflicting replay full rollback
- stale checkpoint rejection before staging
- source-policy recheck
- CollectionRunState -> AgentRun -> CollectionRunState round trip
- non-SOURCE_MONITORING AgentRun rejection

Validation on PR #68 implementation head:

- shared schema/example validation — PASS
- connector runner/registry/orchestration/persistence tests — PASS
- PostgreSQL/run-store conformance tests — PASS

No Production database connection, real source polling, migration, secret or fabricated canonical record is used by this slice.

## Exact Next Safe Slices Inside BMI-P2-001

After PR #68 integration:

1. rollback-only SQL/database conformance harness against the actual BullMatch-private schema, leaving no synthetic rows
2. reusable connector fixture helpers so future source connectors inherit common conformance tests
3. operational orchestration wrapper linking approved registry -> persisted run state -> connector -> atomic persistence without selecting a real source
4. persisted source-registry provider when required by the operational wrapper

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

Check PR #68 integration state. If merged, continue `BMI-P2-001` on a fresh branch from `main` with the rollback-only database conformance harness and reusable fixture helpers. Do **not** select, scrape or poll a real external source inside BMI-P2-001.
