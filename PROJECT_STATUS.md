# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database**

Overall status: **AUTHORIZATION FOUNDATION APPLIED / REVIEW READY**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Database Baseline

- `bullmatch`: 15 tables
- `bullmatch_private`: 17 tables
- production bull/match/source/review datasets remain intentionally empty
- canonical facts default unverified
- publication guard requires verified match + participants + result
- source ingestion has deterministic idempotency boundary
- review workflow supports version/idempotent command fields

## Current Work — BMI-P1-004

Status: **REVIEW**
Tracking: Issue #19
Branch: `agent/bmi-p1-004-auth-roles`

### Applied migrations

- `20260906054956` — BullMatch role authorization/read policies
- `20260906055150` — consolidate read policies after advisor finding

## Authorization Model

Identity:
- Supabase `auth.users` is shared project identity only

BullMatch membership source of truth:
- `bullmatch.app_users`

Roles:
- `ADMIN`
- `REVIEWER`
- `VIEWER`

Status:
- `ACTIVE`
- `SUSPENDED`

`bullmatch.has_active_role(text[])`:
- uses current `auth.uid()`
- reads current BullMatch membership
- requires ACTIVE status
- is `SECURITY INVOKER`
- does not use `user_metadata`

## Browser Access Boundary

Authenticated browser grants on `bullmatch` are SELECT-only.

RLS behavior:
- ADMIN / REVIEWER: canonical + Review Queue read access
- VIEWER: verified/non-archived entities and verified/published matches only
- non-member: no BullMatch domain/review rows
- suspended member: no role access

No browser role can directly INSERT/UPDATE/DELETE canonical/review data.

`bullmatch_private` remains unavailable to `anon` and `authenticated` at the schema boundary.

## First Administrator

At implementation time, shared Auth had no real user accounts and `bullmatch.app_users` remains empty.

No administrator was fabricated and no “first signup becomes admin” path exists.

The trusted bootstrap process is documented in:
- `docs/AUTHORIZATION-RUNBOOK.md`

Once a real Auth account exists, a trusted operator verifies its exact UUID and adds the ADMIN membership from a trusted server/database context.

## Verification

Remote authorization assertions passed:
- authenticated has no BullMatch non-SELECT table grants
- helper is SECURITY INVOKER
- anon cannot execute role helper
- browser roles cannot use `bullmatch_private`
- no policy references user-editable metadata
- non-member simulated JWT resolves to no role/membership
- canonical domain tables use one authenticated SELECT policy each

Artifacts:
- `supabase/tests/p1_004_authorization.sql`
- `supabase/P1-004-VERIFICATION.md`

## Advisor Review

### Security

No WARN/ERROR security findings introduced.

Remaining private-schema `RLS Enabled No Policy` INFO findings are intentional because the schema has no browser usage/grants.

### Performance

Initial role migration generated `multiple_permissive_policies` WARN findings. These were fixed by migration `20260906055150`.

Current remaining findings are unused-index INFO on the empty database. Do not remove indexes before real query/workload evidence exists.

## Data API

This task does not alter Supabase Data API exposed-schema settings.

If direct browser queries are selected later, `bullmatch` exposure must be intentional and tested. `bullmatch_private` must not be browser-exposed.

## Next Integration Gate

Merge BMI-P1-004, then begin **BMI-P1-005 — Bull/Camp/Owner/Venue CRUD**.

P1-005 should implement controlled ADMIN domain operations rather than grant unrestricted table writes to browser clients.

Parallel after P1-004:
- BMI-P1-006 Manual Match Entry & Verification
- BMI-P1-008 Review Backend Foundation

## Deferred

- actual first ADMIN activation (requires a real Auth account)
- final frontend framework/hosting
- AI provider selection
- first production source selection/compliance approval

These do not block server/domain operation implementation.
