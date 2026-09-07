# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — First Source Compliance Readiness**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / SOURCE-AGNOSTIC COLLECTION + PERSISTED POLICY REGISTRY + SOURCE COMPLIANCE FRAMEWORK COMPLETE / NO REAL SOURCE AUTHORIZED**

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
- BMI-P2-003 First Source Compliance Evaluation Framework — COMPLETE — PR #77
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

## BMI-P2-003 — First Source Compliance Evaluation Framework

Status: **IMPLEMENTATION GATE COMPLETE**  
Merged PR: **#77**  
Contract: `source-compliance-evaluation/1.0.0`  
Guide: `docs/SOURCE-COMPLIANCE-EVALUATION.md`

Delivered a deterministic pre-approval dossier covering source/operator identity, access method and policy evidence, retention/attribution rights, proposed polling/rate-limit/cursor/dedupe policy, provenance/reliability rationale, secret requirement names, withdrawal/failure behavior and source-specific validation expectations.

Decision safety:

- every unresolved candidate remains `REVIEW_REQUIRED`
- `APPROVED` requires an explicit `OWNER_OR_COMPLIANCE` decision actor/time, at least one decision-basis reference and zero blockers
- `BLOCKED` requires a recorded blocking reason
- the framework itself cannot create or activate a Production source
- synthetic example uses `.invalid`; no real Bull/Match/source facts are retained as fixture data

Validation:

- shared-contract validation CI run #38 — PASS
- deterministic source-compliance contract tests — PASS through CI
- no migration, Production API, auth, browser grant or source-registry activation impact

## Next Engineering Task

### BMI-P2-004 — Candidate Source Dossier Research

Status: **READY**  
Priority: highest safe next task that advances first-source readiness without authorizing a source.

Goal: identify a small shortlist of plausible Thai bullfighting information-source candidates and prepare `REVIEW_REQUIRED` dossiers using the BMI-P2-003 contract.

Research boundaries:

- manual/browser public-web research only; no connector polling or bulk scraping
- record public source/operator identity, access-policy surfaces, rights/attribution evidence and unresolved questions
- propose source-specific runtime policy only where public evidence supports it; do not invent rates/windows
- do not collect candidate Bull/Match facts as fixtures or write Production records
- do not create credentials
- do not mark any candidate `APPROVED`

## External Decision Blocker

The **first Production source connector and activation remain BLOCKED** because BullMatch currently has no explicit owner/compliance-approved real source. The minimum external action later required is an explicit `APPROVED` decision for one completed source dossier under `source-compliance-evaluation/1.0.0`. Until that exists, no connector may be enabled against a real source and no source row may be activated merely to continue development.

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

Start `BMI-P2-004` from fresh `main`. Research a small number of plausible real source candidates using public browser-accessible policy/operator evidence, create only `REVIEW_REQUIRED` dossiers, and leave the approval decision to the owner/compliance authority. Do not poll, scrape at connector scale, create credentials, activate the private source registry, or ingest Bull/Match facts during this research task.
