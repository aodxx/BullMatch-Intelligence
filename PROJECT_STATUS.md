# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 0 — COMPLETE / Phase 1 Ready**

Overall status: **READY FOR SHARED SUPABASE BOOTSTRAP**

## Phase 0 Exit Criteria

All Phase 0 exit criteria are satisfied:

- [x] product scope and MVP documented
- [x] system architecture documented
- [x] database contract defined
- [x] shared Supabase tenancy/namespace model defined
- [x] source/evidence lifecycle defined
- [x] AI agent responsibilities/contracts defined
- [x] duplicate/conflict behavior defined
- [x] entity resolution strategy defined
- [x] human review workflow defined
- [x] team workflow operational
- [x] implementation backlog established

## Completed Phase 0 Work

| Task | Status | Tracking |
|---|---|---|
| BMI-P0-001 Repository/collaboration foundation | DONE | root docs + `.github/` |
| BMI-P0-002 Database schema | DONE | Issue #1 / PR #5 |
| BMI-P0-003 AI/verification contracts | DONE | Issue #2 / PR #6 |
| BMI-P0-004 PRD v0.2 | DONE | `PRD.md` |
| BMI-P0-005 Architecture v0.2 | DONE | `ARCHITECTURE.md` |
| BMI-P0-006 Source Registry/Connector contract | DONE | Issue #7 / PR #8 |
| BMI-P0-007 Entity Resolution | DONE | Issue #3 / PR #9 |
| BMI-P0-008 Review Queue UX | DONE | Issue #4 / PR #12 |
| BMI-P0-009 Shared Supabase tenancy | DONE | Issue #10 / PR #11 |
| BMI-P0-010 Phase 0 sign-off | REVIEW | Issue #13 |

## Locked Architecture Decisions

1. Verified/published data is the authoritative statistics source.
2. AI output remains candidate data until verification/publication policy succeeds.
3. Raw evidence/provenance survives rejection/conflict decisions.
4. Connectors use shared contracts and source-native idempotency keys.
5. Connector cursor advances only after safe persistence.
6. Entity resolution is conservative and evidence/context based.
7. Thai name normalization is retrieval assistance, not identity proof.
8. Entity merge/split is human-controlled, audited and reversible.
9. Review commands are idempotent and optimistic-concurrency safe.
10. External source content is untrusted input, never agent instruction.
11. Multiple contributors use Task IDs and isolated branches.

## Shared Supabase Decision

BullMatch will **not create a third Supabase project** at the current stage.

Selected host:

**`aodxx's Project`**

Existing `freshmart` project remains outside BullMatch scope.

BullMatch-owned namespaces:
- `bullmatch` — canonical application and review data
- `bullmatch_private` — source/AI/evidence/provenance/runtime/audit data

Shared infrastructure:
- `auth.users`
- platform-managed Supabase schemas/services

BullMatch authorization is app-scoped through `bullmatch.app_users`; existing shared authentication alone grants no BullMatch privileged access.

## Verified Shared Host Baseline

At Phase 0 sign-off:

- selected host: `ACTIVE_HEALTHY`
- no `bullmatch` schema exists yet
- no `bullmatch_private` schema exists yet
- no application tables observed in `public`
- no current `auth.users` rows observed
- no application migration history reported
- no Edge Functions reported
- Security Advisor: no current lint findings
- Performance Advisor: no current lint findings

This inventory must be repeated immediately before migration because the host is shared.

## Current Supabase Compatibility Notes

- do not pin extension versions in migration SQL
- do not modify the Supabase-managed `realtime` schema
- Data API exposure is explicit; never assume BullMatch custom schemas/tables are automatically browser-accessible
- `bullmatch_private` remains browser-inaccessible
- any exposed `bullmatch` table requires explicit grants + tested RLS

## Phase 1 Entry Gate

Next task:

### BMI-P1-001 — Shared Supabase Bootstrap

Before DDL:
1. repeat shared-host inventory
2. confirm host is healthy
3. confirm BullMatch namespaces remain unused
4. re-check relevant Supabase guidance

Then:
1. apply migration to create `bullmatch` and `bullmatch_private`
2. create minimal `bullmatch.app_users` membership foundation
3. establish initial grants/RLS isolation boundary
4. add database isolation tests
5. verify unrelated schemas unchanged
6. run security/performance advisors

No BullMatch migration may alter another application's objects.

## Current Blockers

There is no architectural blocker for Phase 1.

Still intentionally deferred:
- final web framework/hosting choice
- AI provider selection
- first production source selection/compliance validation

These do not block database bootstrap.

## Handoff Rule

A new contributor must read:
- `AGENTS.md`
- `PRD.md`
- `ARCHITECTURE.md`
- `PROJECT_STATUS.md`
- `TASKS.md`
- `docs/SHARED-SUPABASE-TENANCY.md`
- `docs/DATABASE-SCHEMA-NAMESPACE-OVERLAY.md`

Then claim only a READY Task ID and work on an isolated branch.
