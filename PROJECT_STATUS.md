# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS / REGISTRY+RUN-STATE SLICE VALIDATED**

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
Current branch: `agent/bmi-p2-001-registry-run-state`
Current PR: **#65 — `[BMI-P2-001] Add approved registry loader and collection run state`**
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Previous merged baseline — PR #64

Phase 0 already defined the required JSON Schemas under `packages/contracts/`. PR #64 made the connector boundary executable without creating a competing schema family.

Delivered:
- standards-resolvable connector request/result cross-schema references
- source-agnostic `Connector` protocol
- `run_connector_poll()` contract/invariant validation
- source policy gates: APPROVED + ACTIVE + polling enabled
- connector-key binding
- source/run/correlation identity enforcement
- normalized-item connector name/version enforcement
- duplicate `dedupe_key` rejection per poll result
- checkpoint rule: cursor advances only after valid output and `checkpoint_safe=true`
- deterministic connector conformance tests
- shared-contract CI coverage

### Current validated slice — PR #65

Delivered on branch:
- `ApprovedSourceRegistry` validates shared source-registry entries
- runtime view contains only policy-APPROVED sources
- duplicate source IDs rejected
- approved-but-paused/polling-disabled sources remain non-pollable
- connector filtering returns only ACTIVE + poll-enabled approved sources
- persistence-neutral `CollectionRunState`
- existing `AgentRun` contract reused with `agent_type=SOURCE_MONITORING`
- schema-valid poll requests bound to run/correlation/source identity
- item/request limits capped by source policy
- deterministic metrics/output references accumulated from validated `PollExecution`
- terminal health/error mapping to SUCCEEDED/PARTIAL/FAILED
- explicit contract-valid SOURCE_MONITORING failure path
- AgentRun -> AgentError cross-schema `$ref` repaired to the canonical 1.0.0 `$id`

Validation on latest implementation head:
- shared JSON Schema validation — PASS
- contract examples — PASS
- connector cross-schema resolution — PASS
- existing connector conformance tests — PASS
- new source-registry/run-state integration tests — PASS

Safety preserved:
- no real external source selected or contacted
- no network connector added
- no Production persistence or migration
- no source secret values loaded
- no canonical Bull/Match/history write capability
- fixtures use synthetic UUIDs and `.invalid` URLs only in test memory
- no AI-provider dependency

## Exact Next Safe Slices Inside BMI-P2-001

After PR #65 integration:

1. deterministic persistence adapter interfaces for source-item/evidence staging
2. transactional boundary for dedupe + evidence persistence + safe checkpoint commit
3. persisted run-state adapter compatible with `CollectionRunState`
4. reusable connector conformance fixture helpers
5. database adapter conformance tests without retaining synthetic Production rows

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

Check PR #65 integration state. If merged, continue `BMI-P2-001` on a fresh branch from `main` with the deterministic persistence adapter interfaces and transactional dedupe/evidence/checkpoint contract. Do **not** select or poll a real external source inside BMI-P2-001.
