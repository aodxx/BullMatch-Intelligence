# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Automated Collection Readiness**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 SOURCE-AGNOSTIC FOUNDATION COMPLETE / FIRST REAL SOURCE NOT YET AUTHORIZED**

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
- BMI-P2-001 Source-Agnostic Collection Pipeline Foundation — COMPLETE — PR #64–#72
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

Status: **IMPLEMENTATION GATE COMPLETE**  
Owner: Primary Maintainer  
Merged PRs: **#64–#72**  
Contracts: `docs/COLLECTION-PIPELINE-FOUNDATION.md`, `docs/COLLECTION-OPERATIONAL-ORCHESTRATION.md`

Delivered:

- source-agnostic connector execution and shared contract validation
- APPROVED/ACTIVE/polling gates and connector/source/run/correlation identity checks
- safe checkpoint advancement and duplicate-key rejection
- approved-only runtime registry
- persistence-neutral `CollectionRunState` mapped to `SOURCE_MONITORING` AgentRun
- atomic normalized source item + PENDING evidence + checkpoint persistence contract
- `(source_id, dedupe_key)` replay idempotency, conflicting replay rejection and stale-cursor rejection
- PostgreSQL ingestion adapter over existing BullMatch-private ingestion/runtime tables
- persisted PostgreSQL AgentRun store
- rollback-only conformance against the deployed BullMatch PostgreSQL schema with zero retained fixtures
- reusable synthetic connector fixtures using fixed UUIDs and `.invalid` URLs only
- operational one-poll wrapper: approved registry -> persisted checkpoint -> run state -> connector -> atomic persistence -> terminal run
- read-only `PostgresCheckpointReader` over `bullmatch_private.source_runtime_state`
- CI coverage for schemas/examples and the complete connector conformance suite

Required invariant remains:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

Collection code has no canonical Bull/Match/history, review, verification, promotion or publication write path.

### Latest validation

- PR #71 `Validate shared contracts` run #29 — PASS
- PR #72 `Validate shared contracts` run #32 — PASS
- schema/example validation — PASS
- full connector unittest discovery including operational orchestration and PostgreSQL checkpoint-reader tests — PASS

### Persisted source-registry storage gap

The deployed `bullmatch_private.sources` table does **not** currently store every field required to reconstruct `source-registry-entry/1.0.0` deterministically. Missing dedicated storage includes at least:

- polling timezone
- polling active windows
- polling max-items-per-run
- complete rate-limit policy object

These values must not be guessed from defaults or silently invented from `connector_config`.

This gap does not invalidate the source-agnostic foundation because the operational wrapper consumes the already-defined `SourceRegistryProvider` abstraction, but a real Production source must not be enabled until source-policy storage is explicitly aligned.

## Next Engineering Task

### BMI-P2-002 — Persisted Source Policy Registry Alignment

Status: **READY**  
Priority: highest non-blocked internal engineering task.

Goal: define and implement an additive, deterministic storage mapping for the complete `source-registry-entry/1.0.0` polling/rate-limit policy, then provide a read-only PostgreSQL `SourceRegistryProvider` with conformance tests.

Constraints:

- additive/reversible migration only if columns are required
- do not encode undocumented policy defaults
- no real source selection, scraping or polling
- no credentials in registry payloads
- preserve service-role/private-schema boundary
- no canonical data writes

After BMI-P2-002, a first real source connector remains blocked on an explicit source/compliance decision covering permitted access method, rate limits, rights/retention, authentication and source-specific tests.

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

Start `BMI-P2-002` from fresh `main`: inspect the `source-registry-entry/1.0.0` contract against `bullmatch_private.sources`, design the smallest additive policy-storage migration, implement a read-only PostgreSQL `SourceRegistryProvider`, and prove mapping/validation with deterministic tests. Do not select or contact a real external source.
