# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source-Agnostic Automated Collection Pipeline Foundation**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / BMI-P2-001 IN PROGRESS**

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
Branch: `agent/bmi-p2-001-collection-foundation`
PR: **#64 — `[BMI-P2-001] Make connector contracts executable and checkpoint-safe`**
Contract note: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

### Discovery during implementation

Phase 0 already defined the required JSON Schemas under `packages/contracts/`:
- source registry entry
- connector poll request/result
- normalized ingestion envelope
- agent errors/runs
- extraction/resolution/verification contracts

Therefore BMI-P2-001 does not create a competing schema family. It turns the existing contracts into an executable connector boundary.

### First implementation baseline

PR #64 adds:
- standards-resolvable cross-schema `$ref` values for connector poll request/result while preserving 1.0.0 payload meaning
- source-agnostic Python `Connector` protocol
- `run_connector_poll()` contract/invariant validation
- source policy gates: APPROVED + ACTIVE + polling enabled
- connector-key binding
- source/run/correlation identity enforcement
- normalized-item connector name/version enforcement
- duplicate `dedupe_key` rejection per poll result
- checkpoint rule: cursor advances only after valid output and only when `checkpoint_safe=true`
- deterministic in-memory conformance tests
- shared-contract CI coverage for connector runtime

The runner intentionally has:
- no real-source connector
- no network access
- no Production persistence
- no canonical Bull/Match write capability
- no AI-provider dependency

### Validation

PR #64 shared-contract CI: **PASS**
- JSON Schema validation PASS
- example validation PASS
- connector cross-schema resolution PASS
- connector conformance unit tests PASS

Test fixtures use synthetic identifiers and `.invalid` URLs only in test memory. They are not Bull history and are never persisted to Production.

### Exact next safe slices inside BMI-P2-001

1. approved source-registry loader
2. orchestration/run-state abstraction compatible with existing agent-run contract
3. deterministic persistence adapter interfaces for source-item/evidence staging
4. transaction boundary for dedupe + safe checkpoint persistence
5. reusable connector conformance fixture helpers

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

Continue `BMI-P2-001` from PR #64 after checking whether the PR merged and whether another active branch has claimed a non-overlapping slice.

If PR #64 is merged, implement the source-registry loader + run-state abstraction next. Do **not** select or poll a real external source in BMI-P2-001.
