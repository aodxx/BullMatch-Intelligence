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

### Durable Phase 1 boundaries

- community/source input creates evidence + atomic claims first
- canonical promotion is separate, controlled and auditable
- contributors never gain ADMIN/REVIEWER authority merely by submitting data
- uncertain Bull identity stays unresolved; name similarity is not identity proof
- destructive Bull MERGE/SPLIT and broad/high-risk promotion remain deferred
- no fabricated Production Bull/Match/community rows are retained for testing

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
Latest merged slices:
- PR #64 — executable connector contracts + checkpoint safety
- PR #65 — approved source registry loader + SOURCE_MONITORING run state
- PR #66 — atomic ingestion persistence boundary
Priority: highest current non-blocked engineering task.
Contract reference: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

Goal:
Make the existing Phase 0 source/connector/normalized-ingestion contracts executable and persistence-ready before any real Production source is selected.

### PR #64 — connector execution baseline — MERGED

- existing shared schemas reused
- source-agnostic `Connector` protocol + validated `run_connector_poll()`
- APPROVED + ACTIVE + polling-enabled policy gates
- connector/source/run/correlation identity enforcement
- duplicate `dedupe_key` rejection within one poll
- checkpoint advances only after valid output + `checkpoint_safe=true`
- deterministic tests + CI

### PR #65 — registry/run-state — MERGED

- approved-only runtime source registry
- duplicate source IDs rejected
- paused/poll-disabled approved sources remain non-pollable
- persistence-neutral `CollectionRunState`
- existing AgentRun contract reused for SOURCE_MONITORING
- poll item/request limits capped by source policy
- deterministic run metrics/output refs + terminal states
- standards-resolvable AgentRun -> AgentError reference

### PR #66 — atomic persistence contract — MERGED

- `IngestionPersistenceAdapter` / `IngestionTransaction` protocols
- `persist_poll_execution()` after validated connector output
- source/correlation identity recheck at persistence boundary
- normalized item + evidence staging before checkpoint commit
- `(source_id, dedupe_key)` idempotency
- exact replay without duplicate evidence
- conflicting same-key normalized payload rejected instead of overwritten
- unsafe checkpoint may persist evidence while retaining prior cursor
- stale expected cursor rejected before staging
- transaction begin is side-effect free; any error rolls full batch back
- persisted cursor shape is request-compatible `strategy + value`; transient `checkpoint_safe` is not stored
- deterministic in-memory conformance adapter only; no Production DB writes

Validation before PR #66 merge:
- schema/example validation — PASS
- connector runner tests — PASS
- registry/run-state tests — PASS
- atomic persistence tests — PASS

Required project-wide invariants:
1. normalized source output remains untrusted evidence/candidate input
2. connectors/orchestration/persistence never write canonical Bulls/Matches/history directly
3. conflicts remain unresolved until verification/review handles them
4. invalid output cannot commit cursor progress
5. source-specific secret values never enter shared contracts/logs/tests
6. test fixtures are deterministic and never persisted to Production
7. a real source connector requires a separate explicit source/compliance decision

### Exact next safe slices inside BMI-P2-001

1. persisted AgentRun/run-state adapter compatible with `CollectionRunState`
2. PostgreSQL/Supabase adapter mapping to existing `bullmatch_private` ingestion/runtime tables
3. rollback-only database conformance tests for item/evidence/checkpoint atomicity
4. reusable connector conformance fixture helpers
5. operational orchestration wrapper connecting registry -> run state -> connector -> persistence without selecting a real source

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
