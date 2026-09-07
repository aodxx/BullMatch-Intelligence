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
Active branch: `agent/bmi-p2-001-persistence-contract`
Current PR: **#66 — `[BMI-P2-001] Define atomic ingestion persistence boundary`**
Previous merged slices:
- PR #64 — executable connector contracts + checkpoint safety
- PR #65 — approved source registry loader + SOURCE_MONITORING run state
Priority: highest current non-blocked engineering task.
Contract reference: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

Goal:
Make the existing Phase 0 source/connector/normalized-ingestion contracts executable and persistence-ready before any real Production source is selected.

### Delivered baseline — PR #64

- existing `packages/contracts` schemas reused instead of introducing competing contracts
- connector request/result cross-schema `$ref` repair against canonical schema `$id`s
- source-agnostic `Connector` protocol and validated `run_connector_poll()`
- APPROVED + ACTIVE + polling-enabled policy gates
- connector/source/run/correlation identity enforcement
- duplicate `dedupe_key` rejection inside one poll result
- checkpoint advances only after valid output and `checkpoint_safe=true`
- deterministic in-memory conformance tests
- shared-contract CI coverage
- no network, Production persistence or canonical write capability

### Delivered registry/run-state slice — PR #65

- validated `ApprovedSourceRegistry` runtime loader
- `REVIEW_REQUIRED`/`BLOCKED` sources excluded from runtime view
- duplicate source IDs rejected
- approved-but-paused/polling-disabled sources blocked from polling
- connector-key filtering returns only ACTIVE + poll-enabled approved sources
- persistence-neutral `CollectionRunState` using existing `AgentRun` contract
- schema-valid SOURCE_MONITORING run state
- poll request construction bound to run/correlation/source identity
- requested item/request limits capped by source registry policy
- connector execution metrics/output references recorded deterministically
- health/error terminal mapping to SUCCEEDED/PARTIAL/FAILED
- explicit contract-valid SOURCE_MONITORING failure path
- AgentRun -> AgentError `$ref` repaired to canonical 1.0.0 `$id`

Validation for PR #65:
- shared contract schema/example validation — PASS
- connector runner tests — PASS
- registry/run-state integration tests — PASS

### Current persistence slice — PR #66

Implemented:
- `IngestionPersistenceAdapter` and `IngestionTransaction` protocols
- `persist_poll_execution()` transaction boundary after validated connector output
- source/correlation identity rechecked at persistence boundary
- normalized item/evidence staging before checkpoint commit
- `(source_id, dedupe_key)` idempotency key
- exact replay does not duplicate stored item/evidence
- same dedupe key with different normalized payload is rejected instead of overwritten
- unsafe checkpoint may persist evidence while retaining the previous cursor
- stale expected cursor rejected before staging
- transaction begin is side-effect free
- any staging/checkpoint exception rolls back the full batch
- deterministic in-memory adapter models atomic semantics only for tests

Persistence invariants:
1. source item + evidence + checkpoint visibility is atomic
2. invalid/conflicting data never advances checkpoint
3. replay is idempotent only when normalized payload is identical
4. persistence layer has no canonical Bull/Match/history write operation
5. no Production adapter or migration is introduced in this slice

Required project-wide invariants:
1. normalized source output remains untrusted evidence/candidate input
2. connectors/orchestration/persistence never write canonical Bulls/Matches/history directly
3. conflicts remain unresolved until verification/review handles them
4. invalid output cannot commit cursor progress
5. source-specific secret values never enter shared contracts/logs/tests
6. test fixtures are deterministic and never persisted to Production
7. a real source connector requires a separate explicit source/compliance decision

### Exact next safe slices inside BMI-P2-001 after PR #66

1. persisted AgentRun/run-state adapter compatible with `CollectionRunState`
2. PostgreSQL/Supabase adapter mapping to existing private ingestion tables
3. rollback-only database conformance tests for source item/evidence/checkpoint atomicity
4. reusable connector conformance fixture helpers
5. orchestration wrapper connecting registry -> run state -> connector -> persistence without selecting a real source

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
