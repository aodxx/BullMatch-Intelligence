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
- BMI-P1-008 Review Backend Foundation — DONE — PR #50–#56
- BMI-P1-009 Thai Bullfighting Domain Rebaseline — DONE — PR #36
- BMI-P1-010 Product Rebaseline v0.3 — DONE — PR #38
- BMI-P1-011 Database Schema v0.2 — DONE — PR #39
- BMI-P1-012 Contribution & Trust Architecture — DONE — PR #40
- BMI-P1-013 Community Contribution Intake Foundation — DONE — V1 gate — PR #59–#62

Durable Phase 1 boundaries:

- community/source input creates evidence + atomic claims first
- canonical promotion is separate, controlled and auditable
- contributors never gain ADMIN/REVIEWER authority merely by submitting data
- uncertain Bull identity stays unresolved; name similarity is not identity proof
- no fabricated Production Bull/Match/community rows are retained for testing

---

## App / Frontend Track

- BMI-APP-001 Frontend Foundation — DONE — PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE — PR #31
- BMI-APP-003 Controlled API + Production Data Wiring — DONE — PR #33
- BMI-APP-004 Visual Design Rebaseline — DONE — implementation gate — PR #41, #42, #46, #47, #48

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

Status: **DONE — IMPLEMENTATION GATE**  
Owner: Primary Maintainer  
Merged PRs: **#64–#72**  
Contracts: `docs/COLLECTION-PIPELINE-FOUNDATION.md`, `docs/COLLECTION-OPERATIONAL-ORCHESTRATION.md`

Delivered:

- source-agnostic validated connector runner
- APPROVED + ACTIVE + polling gates
- connector/source/run/correlation identity checks
- duplicate-key rejection and safe checkpoint advancement
- approved-only runtime registry
- persistence-neutral `CollectionRunState` using SOURCE_MONITORING AgentRun
- atomic normalized source item + evidence + checkpoint persistence
- replay idempotency, conflicting replay rejection and stale-cursor protection
- PostgreSQL ingestion + persisted run-state adapters
- rollback-only real-schema conformance with zero retained fixtures
- reusable synthetic connector conformance fixtures
- operational one-poll orchestration from registry/checkpoint through atomic persistence
- read-only PostgreSQL checkpoint reader
- shared-contract and complete connector test suite passing in CI

Project-wide invariants:

1. normalized source output remains untrusted evidence/candidate input
2. collection runtime cannot write canonical Bulls/Matches/history directly
3. conflicts remain unresolved until review/verification
4. invalid output cannot commit cursor progress
5. source secrets never enter contracts/logs/tests
6. deterministic fixtures never remain in Production
7. a real source connector requires a separate explicit source/compliance decision

No real source was selected, scraped or polled under BMI-P2-001.

### BMI-P2-002 — Persisted Source Policy Registry Alignment

Status: **READY**  
Priority: highest current non-blocked internal engineering task.  
Dependencies: BMI-P2-001.

Problem:

`bullmatch_private.sources` does not currently contain every value required to reconstruct `source-registry-entry/1.0.0` deterministically. Dedicated storage is missing for at least polling timezone, active windows, max-items-per-run and the complete rate-limit policy object.

Goal:

- compare the shared source registry contract to the deployed private source table
- design the smallest additive/reversible storage alignment
- avoid undocumented defaults or hidden `connector_config` conventions
- implement a read-only PostgreSQL `SourceRegistryProvider`
- validate full contract reconstruction with deterministic fake-DB and schema tests
- preserve service-role/private-schema boundary
- do not select/contact a real source
- do not add canonical Bull/Match/history writes

Expected branch: `agent/bmi-p2-002-source-policy-registry`.

A first Production source connector remains blocked until an explicit source/compliance decision defines permitted access method, rights/retention, rate limits, authentication/secret handling and source-specific tests.

## Phase 3 — Multi-Source Expansion

Status: PLANNED — after an approved first source proves Phase 2 contracts.

## Phase 4 — Intelligence Products

Status: PLANNED — after sufficient verified sample depth.

Includes Matchup Intelligence, opponent-adjusted form, shared-opponent/style analysis, camp/venue analysis, evidence completeness/confidence, reports and API/B2B surfaces.

---

## Autonomous Priority Reference

1. **BMI-P2-002 — Persisted Source Policy Registry Alignment** — READY
2. first permitted Production source connector — BLOCKED on explicit source/compliance selection
3. Intelligence Products / Matchup Intelligence — wait for sufficient verified data depth
4. deferred APP-004 real-data visual QA — wait for genuine verified data
5. destructive identity operations — separate safety approval required

## Deferred / External-Decision Items

- first Production source selection/compliance approval
- public contributor signup/onboarding policy
- AI provider selection
- destructive Bull identity merge/split execution
- broad/high-risk canonical promotion
- distinct-Bull same-name escalation policy
- venue-specific uncertain terminology/rules
- exact contributor reputation formula
- Data Credit / Pro-unlock thresholds/pricing

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the Primary Maintainer coordinates non-overlapping work.

When a task starts:

1. record owner
2. mark IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside scope
5. run relevant checks/tests
6. submit PR/handoff
