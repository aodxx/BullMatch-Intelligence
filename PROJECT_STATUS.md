# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — First Source Compliance Readiness**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / SOURCE-AGNOSTIC COLLECTION + PERSISTED POLICY REGISTRY + SOURCE COMPLIANCE FRAMEWORK COMPLETE / CANDIDATE DOSSIER RESEARCH ACTIVE / NO REAL SOURCE AUTHORIZED**

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

Delivered additive source policy storage, no guessed backfill/defaults for existing source rows, fail-closed shared-schema validation and a read-only PostgreSQL source-registry provider. Production migration and post-migration schema checks passed. Production source registry remained at APPROVED sources = 0 and APPROVED+ACTIVE+polling sources = 0.

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
- the framework cannot create or activate a Production source
- synthetic example uses `.invalid`; no real Bull/Match/source facts are retained as fixture data

## BMI-P2-004 — Candidate Source Dossier Research

Status: **IN PROGRESS — FIRST-PARTY EVIDENCE FOLLOW-UP**  
Initial shortlist merged: **PR #79**  
Active branch: `agent/bmi-p2-004-first-party-evidence`

Current candidate set:

- **wuachon.co** — strongest direct domain relevance in the shortlist. Manual browser research confirms the public homepage is accessible and visibly program-oriented, but no reliable first-party operator identity, terms, robots, automation policy or reuse/license basis was established. It remains `REVIEW_REQUIRED`, reliability `UNKNOWN`, cross-check `REQUIRED`, and `polling_enabled=false`.
- **Thailand Sports Almanac** — official government sports reference with possible provenance/context value. No new first-party automation/reuse policy was established in the current follow-up, so its dossier remains intentionally unchanged and `REVIEW_REQUIRED`.
- **Surat Thani Provincial Government** — first-party About evidence strengthens official operator provenance for provincial content. This does not establish permission for recurring automated retrieval or content reuse; the candidate remains an episodic corroboration source and `REVIEW_REQUIRED`.

Evidence log: `docs/SOURCE-EVIDENCE-RESEARCH-NOTES.md`.

No connector polling, bulk scraping, credential creation, private source-registry activation, Bull/Match fixture ingestion or Production canonical write occurred.

## External Decision Blocker

The **first Production source connector and activation remain BLOCKED** because BullMatch currently has no explicit owner/compliance-approved real source.

The minimum external action later required is an explicit `APPROVED` decision for one sufficiently evidenced dossier under `source-compliance-evaluation/1.0.0`. Until that exists, no connector may be enabled against a real source and no source row may be activated merely to continue development.

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

Complete validation and PR handoff for the BMI-P2-004 first-party evidence follow-up. If the dossiers remain contract-valid and non-approved, merge the research update. After that, do not implement or activate a real connector unless new first-party policy/rights evidence resolves the relevant blockers and an explicit `OWNER_OR_COMPLIANCE` approval exists. If no such evidence/decision exists, record the source-approval blocker as the Phase 2 boundary and move to the next safe task that does not depend on fabricated data or unauthorized collection.
