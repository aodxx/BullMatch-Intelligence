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

Status: **IN PROGRESS**  
Owner: Primary Maintainer (ChatGPT autonomous run)  
Latest merged PR: **#68 — PostgreSQL ingestion + persisted run-state adapters**  
Current branch: `agent/bmi-p2-001-db-conformance`  
Current slice: **rollback-only real-schema conformance harness**  
Priority: highest current non-blocked engineering task.  
Contract: `docs/COLLECTION-PIPELINE-FOUNDATION.md`

Goal: make the existing source/connector/normalized-ingestion contracts executable, persistence-ready and conformance-tested before any real Production source is selected.

### Merged slices

**PR #64 — connector execution baseline**
- shared connector schemas reused
- source-agnostic validated poll runner
- APPROVED + ACTIVE + polling-enabled gates
- connector/source/run/correlation identity checks
- duplicate-key rejection and safe checkpoint advancement

**PR #65 — registry/run-state**
- approved-only runtime registry
- persistence-neutral `CollectionRunState`
- SOURCE_MONITORING AgentRun contract reuse
- source-policy poll limits
- deterministic run metrics/terminal states

**PR #66 — atomic persistence contract**
- `IngestionPersistenceAdapter` / `IngestionTransaction`
- item + evidence + checkpoint atomic boundary
- exact replay idempotency
- conflicting replay rejection
- unsafe/stale checkpoint protection
- deterministic in-memory conformance adapter

**PR #68 — PostgreSQL + persisted run-state mapping**
- `PostgresIngestionPersistence` over existing BullMatch-private source/runtime/item/evidence tables
- `PostgresCollectionRunStore` over existing `agent_runs`
- persistence-time policy recheck and source/runtime locking
- normalized-envelope fingerprint in private raw metadata
- `content_hash` preserved for actual source-content hashing
- evidence remains PENDING/unverified
- no migration and no canonical write path
- full shared-contract + connector + PostgreSQL fake-DB CI PASS

### Current rollback-only DB conformance slice

File: `supabase/tests/p2_001_collection_persistence_rollback.sql`

Executed against the active BullMatch PostgreSQL schema with synthetic UUIDs and `.invalid` URLs only.

Validated:

- intended source/runtime/item/evidence/AgentRun storage shape matches deployed constraints
- intentionally failed inner transaction restores item + evidence + checkpoint together
- successful staging shape is schema-valid
- SOURCE_MONITORING AgentRun mapping is schema-valid
- outer transaction rolls back all fixtures
- retained fixture counts after rollback: sources=0, source_items=0, evidence=0, agent_runs=0

No schema change, Production canonical data, real source access, secret, grant or policy change occurred.

### Required project-wide invariants

1. normalized source output remains untrusted evidence/candidate input
2. collection runtime cannot write canonical Bulls/Matches/history directly
3. conflicts stay unresolved until review/verification
4. invalid output cannot commit cursor progress
5. source secrets never enter contracts/logs/tests
6. deterministic fixtures never remain in Production
7. a real source connector requires a separate explicit source/compliance decision

### Exact next safe slices after DB harness integration

1. reusable connector fixture/conformance helpers
2. operational orchestration wrapper: approved registry -> checkpoint -> persisted run state -> connector -> atomic persistence
3. persisted source-registry provider if required
4. BMI-P2-001 foundation sign-off after deterministic end-to-end synthetic orchestration passes

Explicitly not authorized in BMI-P2-001:

- selecting/scraping/polling the first real Production source
- bypassing source compliance review
- choosing an AI provider merely to finish foundation work
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
5. destructive identity operations only after separate safety approval

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
