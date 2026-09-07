# Project Status

Last structural update: 2026-09-07

## Project

**BullMatch Intelligence**  
Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 2 — Source Compliance Boundary Reached**

Overall status: **PRODUCTION API ACTIVE / VERIFIED+REVIEW FOUNDATION COMPLETE / COMMUNITY CONTRIBUTION V1 COMPLETE / SOURCE-AGNOSTIC COLLECTION + PERSISTED POLICY REGISTRY + SOURCE COMPLIANCE FRAMEWORK + CANDIDATE DOSSIER RESEARCH COMPLETE / NO REAL SOURCE AUTHORIZED**

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
- BMI-P2-004 Candidate Source Dossier Research — COMPLETE research gate — PR #79–#80
- BMI-APP-001 through BMI-APP-004 — COMPLETE implementation gates
- BMI-OPS-001 through BMI-OPS-003 — COMPLETE

Production app: `https://aodxx.github.io/BullMatch-Intelligence/`

No fake Production Bull/Match/review/community/source records have been retained for testing.

## Phase 2 Collection Foundation

BMI-P2-001 through BMI-P2-003 delivered the source-agnostic connector runtime, atomic evidence/checkpoint persistence, PostgreSQL adapters, persisted source-policy registry alignment and the explicit source-compliance decision contract.

Required invariant remains:

`validated normalized items + evidence + safe checkpoint -> one atomic transaction`

Collection code has no canonical Bull/Match/history, review, verification, promotion or publication write path.

A source is not executable merely because it is public. Real-source activation requires an APPROVED source-registry/compliance decision.

## BMI-P2-004 — Candidate Source Dossier Research

Status: **RESEARCH GATE COMPLETE**  
PRs: **#79–#80**  
Evidence log: `docs/SOURCE-EVIDENCE-RESEARCH-NOTES.md`

Candidate findings:

- **wuachon.co** — strongest direct domain relevance. Public browser accessibility and program-oriented publication are confirmed, but operator identity, terms/robots/automation policy, reuse/license basis and runtime policy remain unresolved. `REVIEW_REQUIRED`, reliability `UNKNOWN`, cross-check `REQUIRED`, `polling_enabled=false`.
- **Thailand Sports Almanac** — official government sports-reference candidate with potential provenance/context value, but Bull-specific coverage depth and automation/reuse policy remain unresolved. `REVIEW_REQUIRED`, `polling_enabled=false`.
- **Surat Thani Provincial Government** — first-party About evidence strengthens official operator provenance. The source remains an episodic corroboration candidate; recurring automated access/reuse permission and source-specific runtime policy are unresolved. `REVIEW_REQUIRED`, `polling_enabled=false`.

All dossiers retain `authority=UNASSIGNED` and explicit blocking reasons. No connector polling, bulk scraping, credential creation, Production source activation, Bull/Match fixture ingestion or canonical write occurred.

Validation for PR #80: shared schema/examples and connector conformance tests **PASS** in workflow run #43. The contracts workflow now includes `docs/source-evaluations/**`, so future dossier edits automatically run these safety checks.

## External Decision Boundary

The **first Production source connector and activation are BLOCKED** because BullMatch has no explicit owner/compliance-approved real source.

Minimum external action required:

1. resolve enough first-party operator/access/rights/runtime evidence for a selected dossier;
2. record an explicit `OWNER_OR_COMPLIANCE` `APPROVED` decision under `source-compliance-evaluation/1.0.0` with decision-basis references and zero blockers.

Until that exists, no real connector may be enabled and no private source row may be activated merely to preserve development momentum.

## Other Deferred / External-Decision Items

- open/public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name escalation
- venue-specific terminology requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing

## Exact Next Autonomous Action

There is currently **no additional READY engineering task** that can safely cross the Phase 2 boundary without one of: explicit source approval, genuine verified data depth, or a separate owner policy decision.

Do not repeatedly redo the same source-policy search or invent a connector. Resume when new first-party evidence or an explicit owner/compliance decision exists; then start a dedicated first-source connector Task ID from fresh `main` and keep normalized collection output on the evidence/review path rather than canonical history.
