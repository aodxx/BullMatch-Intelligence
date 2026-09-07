# Task Registry

This file is the high-level project map. GitHub Issues/PRs are the canonical execution/handoff records.

## Phase 0 — Foundation & Architecture — COMPLETE

BMI-P0-001 through BMI-P0-010: **DONE**.

---

## Phase 1 — Verified Database / Community Foundation — COMPLETE GATES

- BMI-P1-001 Shared Supabase Bootstrap — DONE — PR #16
- BMI-P1-002 Core Database Migrations — DONE — PR #18
- BMI-P1-003 Seed / Reference Data — DEFERRED; no fabricated Production seed
- BMI-P1-004 Admin Authentication & Roles — DONE — PR #20
- BMI-P1-005 Bull/Camp/Owner/Venue CRUD — DONE — PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE — PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE — PR #29
- BMI-P1-008 Review Backend Foundation — DONE — implementation gate complete — PR #50–#56
- BMI-P1-009 Thai Bullfighting Domain Rebaseline — DONE — PR #36
- BMI-P1-010 Product Rebaseline v0.3 — DONE — PR #38
- BMI-P1-011 Database Schema v0.2 — DONE — PR #39
- BMI-P1-012 Contribution & Trust Architecture — DONE — PR #40
- BMI-P1-013 Community Contribution Intake Foundation — DONE — V1 implementation gate complete — PR #59–#62

### BMI-P1-008 durable boundaries

Delivered controlled review reads/actions, optimistic concurrency/idempotency, atomic claim decisions, evidence/audit/provenance, guarded duplicate/entity decisions, read-only Bull identity impact preview, narrow evidence-backed promotion, guarded UNVERIFIED Bull creation, reviewer UI and routing-metadata EDIT.

Still deferred: destructive Bull MERGE/SPLIT, broad identity/name/alias promotion, owner/camp/lineage/media/match-history promotion, distinct-Bull same-name escalation.

### BMI-P1-013 durable boundaries

V1 supports an evidence-backed correction/observation for an existing VERIFIED Bull using a public HTTP(S) source reference.

Allowlisted fields:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Delivered:
- PR #59 community-origin/evidence/claim foundation
- PR #60 authenticated controlled correction submission API
- PR #61 own-record-only `MY_SUBMISSIONS` feedback projection
- PR #62 mobile Community contribution UI + Production deployment

Invariants:
- contributor actor is server-derived
- contributor gains no ADMIN/REVIEWER privilege
- no browser direct write to private/canonical tables
- submission creates REVIEW_REQUIRED atomic claims, never canonical mutation
- idempotent replay does not duplicate intake rows
- no AI auto-publish
- no betting/wallet/settlement/payout flow

Deferred: public self-signup/onboarding policy, direct file/photo upload, program/result/comparison-day/new-Bull contribution types. No fake canonical/community Production rows are retained for testing.

---

## App / Frontend Track

- BMI-APP-001 Frontend Foundation — DONE — PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE — PR #31
- BMI-APP-003 Controlled API + Production Data Wiring — DONE — PR #33
- BMI-APP-004 Visual Design Rebaseline — DONE — implementation gate complete — PR #41, #42, #46, #47, #48

Production URL: `https://aodxx.github.io/BullMatch-Intelligence/`

Visual boundary: real-bull/sports-intelligence language, safe verified imagery/fallbacks, Data Coverage/Trust Signals, reduced-motion/mobile protection, no fabricated odds/confidence/payout UI.

---

## Operations

- BMI-OPS-001 Enable GitHub Pages — DONE
- BMI-OPS-002 Bootstrap First Production ADMIN — DONE
- BMI-OPS-003 Autonomous Development Continuity — DONE

Runbook: `docs/AUTO-RUN-RUNBOOK.md`.

---

## Phase 2 — Automated Collection Pipeline

### BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation
Status: **IN PROGRESS**
Owner: Primary Maintainer (ChatGPT autonomous run)
Branch: `agent/bmi-p2-001-collection-foundation`
Priority: highest current non-blocked engineering task.
Contract reference: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

Goal:
Make the existing Phase 0 source/connector/normalized-ingestion contracts executable and testable before any real Production source is selected.

Current implementation slice:
- reuse existing `packages/contracts` schemas rather than create competing contracts
- repair connector request/result `$ref` resolution against canonical schema `$id` values
- add source-agnostic `Connector` protocol and validated poll runner under `agents/connectors/`
- block polling unless source policy is APPROVED, source ACTIVE and polling enabled
- enforce source/run/correlation/connector identity boundaries
- reject duplicate `dedupe_key` values inside a poll result
- advance cursor only after valid output and only when `checkpoint_safe=true`
- add deterministic in-memory conformance tests
- extend shared-contract CI to run connector tests
- no network access, no Production persistence and no canonical write capability in this slice

Required invariants:
1. normalized connector output remains untrusted evidence/candidate input
2. connectors never write canonical Bulls/Matches/history directly
3. conflicts are preserved for resolution/review rather than silently overwritten
4. invalid output cannot commit cursor progress
5. source-specific secrets never appear in shared contracts/logs/tests
6. test fixtures are deterministic and never persisted to Production
7. a real source connector requires a separate explicit source/compliance decision

Safe next slices inside BMI-P2-001 after this baseline passes CI:
1. source-registry loader for approved entries
2. orchestration/run-state abstraction
3. deterministic persistence adapter interfaces for source item/evidence
4. transactional dedupe/checkpoint persistence contract
5. reusable connector conformance fixture helpers

Explicitly not authorized in BMI-P2-001:
- selecting or scraping the first real Production source
- bypassing source policy/compliance review
- choosing an AI provider merely to complete foundation work
- direct canonical publication

Dependencies satisfied: BMI-P1-008, BMI-P1-011, BMI-P1-012, BMI-P1-013 V1.

## Phase 3 — Multi-Source Expansion
Status: PLANNED — after an approved first source proves Phase 2 contracts.

## Phase 4 — Intelligence Products
Status: PLANNED — after sufficient verified sample depth.
Includes Matchup Intelligence, opponent-adjusted form, shared-opponent/style analysis, camp/venue analysis, evidence completeness/confidence, reports and API/B2B surfaces.

---

## Autonomous Priority Reference

1. **BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation** — IN PROGRESS
2. first permitted Production source connector after explicit source/compliance selection
3. Intelligence Products / Matchup Intelligence when verified data depth is sufficient
4. deferred APP-004 real-data visual QA
5. separately approved destructive identity operations only after safety design

## Deferred / External-Decision Items

- first Production source selection and source-specific compliance approval
- open/public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name creation escalation policy
- venue-specific uncertain terminology/rules requiring field validation
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing until real usage data exists

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the Primary Maintainer coordinates non-overlapping work.

When a task starts:
1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run relevant checks/tests
6. submit PR/handoff
