# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database**

Overall status: **CORE DATABASE APPLIED / REVIEW READY**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch continues to use only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Current Work — BMI-P1-002

Status: **REVIEW**
Tracking: Issue #17
Branch: `agent/bmi-p1-002-core-database`

### Applied migrations

- `20260906053239` — canonical entities
- `20260906053302` — matches and results
- `20260906053321` — review workflow
- `20260906053347` — private ingestion/evidence/runtime
- `20260906053422` — AI candidates/provenance/audit
- `20260906053503` — publication/default hardening
- `20260906053620` — missing FK indexes

Bootstrap dependency:
- `20260906052726` — shared tenancy bootstrap

## Database Inventory

`bullmatch`: **15 tables**

Includes:
- app_users
- owners / aliases
- camps / aliases
- bulls / aliases
- venues / aliases
- events
- matches / participants / results
- review_cases / review_actions

`bullmatch_private`: **17 tables**

Includes:
- private owner details
- sources/runtime/source_items/evidence
- agent/extraction runs
- candidate groups/claims/evidence links
- entity matching/source mappings
- duplicate candidates/verification results
- provenance/identity/audit history

## Integrity Rules Now Enforced

- canonical entities default to `UNVERIFIED`
- winner participant must belong to the same match
- published match must be VERIFIED
- published match requires at least two participants
- published match requires a result
- event match numbers are unique when known
- source `(source_id,dedupe_key)` is unique/idempotent
- review cases include optimistic `case_version`
- review actions use unique `command_id`
- all BullMatch tables have RLS enabled
- browser roles have no table access to `bullmatch_private`
- browser roles have no domain-table access yet; only authenticated own-membership SELECT remains

## Verification

Remote integration assertions passed against the actual Supabase database.

Temporary test records were removed. Key production rows remain:
- bulls: 0
- matches: 0
- sources: 0
- review_cases: 0

Verification artifacts:
- `supabase/tests/p1_002_core_integrity.sql`
- `supabase/P1-002-VERIFICATION.md`

## Advisor Review

### Security

No WARN/ERROR security findings.

INFO `RLS Enabled No Policy` is expected for domain/private tables at this stage because:
- RLS is enabled as defense in depth
- browser grants are intentionally withheld
- `bullmatch_private` has no browser schema usage
- intentional application policies are deferred to Auth/API work

### Performance

Actionable unindexed foreign-key findings were fixed in migration `20260906053620`.

Remaining INFO findings are unused indexes, expected on a newly created empty database. Index removal is deferred until real workload/query statistics exist.

## Next Integration Gate

Merge BMI-P1-002, then two non-overlapping tasks become available:

1. **BMI-P1-003 Seed / Reference Data**
2. **BMI-P1-004 Admin Authentication & Roles**

P1-004 is the critical dependency before domain CRUD, manual verified match entry, and review backend APIs.

## Current Deferred Decisions

- final frontend framework/hosting
- AI provider selection
- first production source selection/compliance approval

None block database/auth foundation work.

## Handoff Rule

Every new contributor must read the project control/docs before taking one READY Task ID. Shared Supabase changes must remain strictly BullMatch-scoped.
