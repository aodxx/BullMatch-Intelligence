# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — First Source Compliance Readiness**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / SOURCE-AGNOSTIC COLLECTION + PERSISTED POLICY REGISTRY COMPLETE / NO REAL SOURCE AUTHORIZED**

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
- BMI-P2-001 Source-Agnostic Collection Pipeline Foundation — COMPLETE — PR #64–#73
- BMI-P2-002 Persisted Source Policy Registry Alignment — COMPLETE — PR #74
- BMI-APP-001 through BMI-APP-004 — COMPLETE implementation gates
- BMI-OPS-001 through BMI-OPS-003 — COMPLETE

Production app: `https://aodxx.github.io/BullMatch-Intelligence/`

No fake Production Bull/Match/review/community/source records have been retained for testing.

## BMI-P1-013 — Community Contribution V1

Status: **IMPLEMENTATION GATE COMPLETE**  
Contract: `docs/COMMUNITY-CONTRIBUTION-V1.md`

V1 supports evidence-backed correction/observation for an existing VERIFIED Bull using a public HTTP(S) reference for `home_province`, `home_district`, `color_description`, and `breed_description`.

Delivered through PR #59–#62 with server-derived actor identity, REVIEW_REQUIRED atomic claims first, separate controlled promotion, idempotent intake and no AI auto-publish.

Deferred: public self-signup/onboarding policy, direct image/file evidence upload, broader contribution types, and real-data success-path UI QA when genuine VERIFIED data exists.

## BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation

Status: **IMPLEMENTATION GATE COMPLETE**  
Merged PRs: **#64–#73**  
Contracts: `docs/COLLECTION-PIPELINE-FOUNDATION.md`, `docs/COLLECTION-OPERATIONAL-ORCHESTRATION.md`

Delivered source-agnostic contract validation, APPROVED/ACTIVE gates, run/correlation identity, safe checkpoints, atomic normalized source-item + PENDING evidence persistence, replay/stale-cursor protection, PostgreSQL adapters, rollback-only real-schema conformance, reusable synthetic fixtures, one-poll operational orchestration and a read-only PostgreSQL checkpoint reader.

Required invariant remains:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

Collection code has no canonical Bull/Match/history, review, verification, promotion or publication write path.

## BMI-P2-002 — Persisted Source Policy Registry Alignment

Status: **IMPLEMENTATION GATE COMPLETE**  
Merged PR: **#74**  
Production migration: **20260907025225_align_bullmatch_source_policy_registry**

Delivered:

- additive nullable storage for `polling_timezone`, `polling_active_windows`, `max_items_per_run`, and complete `rate_limit` policy
- no guessed backfill/defaults for existing source rows
- basic database constraints for JSON shape and positive max-items
- read-only `PostgresSourceRegistryProvider`
- full reconstruction of `source-registry-entry/1.0.0` for complete rows
- fail-closed shared-schema validation when an APPROVED row lacks required policy
- no credentials in source registry contracts
- no source activation or network polling

Validation:

- current Supabase migration guidance reviewed before deployment
- rollback-only DDL trial against active BullMatch PostgreSQL schema — PASS
- post-rollback aligned-column count — 0
- Production migration applied through Supabase migration history — PASS
- post-migration schema verification — PASS
- Production source registry after migration: APPROVED sources = 0; APPROVED+ACTIVE+polling sources = 0
- final GitHub shared-contract/connector CI run #36 — PASS
- Supabase security/performance advisors run after DDL; no new task-specific issue identified

Existing advisor notices remain separate backlog/security operations concerns: private-schema RLS-with-no-policy INFO notices, unused-index INFO notices, and leaked-password-protection WARN. No access was broadened by BMI-P2-002.

## Next Engineering Task

### BMI-P2-003 — First Source Compliance Evaluation Framework

Status: **READY**  
Priority: highest safe task that does not authorize a source by itself.

Goal: create a source-evaluation dossier/template and evidence checklist so candidate Thai bullfighting sources can be assessed consistently before any connector is configured.

Required evaluation dimensions:

- source identity/operator and public purpose
- access method/API/RSS/public-page basis
- terms/robots/API policy compatibility where applicable
- polling/rate-limit expectations
- evidence storage/retention and attribution rights
- authentication/secret requirements
- source-specific cursor/dedupe semantics
- provenance/reliability tier rationale
- failure/withdrawal policy
- explicit decision state: REVIEW_REQUIRED / APPROVED / BLOCKED

Constraints:

- research/evaluation only; no automatic APPROVED decision
- no real source polling or credential creation
- do not ingest factual Bull/Match records during evaluation
- owner/compliance approval remains required before first Production source is enabled

## Deferred / External-Decision Items

- first Production source approval and connector activation
- open/public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name escalation
- venue-specific terminology requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing

## Exact Next Autonomous Action

Start `BMI-P2-003` from fresh `main` and build the source/compliance evaluation contract, checklist and deterministic decision-record format. It may research candidate source categories, but must not mark a real source APPROVED, store credentials, scrape/poll it, or create canonical Bull/Match data without an explicit source/compliance decision.
