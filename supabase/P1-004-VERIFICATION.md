# BMI-P1-004 Authorization Verification

Date: 2026-09-06
Supabase host: `aodxx's Project`
Task: `BMI-P1-004`

## Applied migrations

- `20260906054956` — `add_bullmatch_role_authorization`
- `20260906055150` — `consolidate_bullmatch_read_policies`

## Verified controls

- `bullmatch.has_active_role(text[])` is `SECURITY INVOKER`
- `authenticated` can execute the role helper
- `anon` cannot execute the role helper
- no BullMatch RLS policy references user-editable `user_metadata`
- `authenticated` has only `SELECT` table privileges in `bullmatch`
- browser roles have no INSERT/UPDATE/DELETE table privileges in BullMatch
- `authenticated` and `anon` have no `USAGE` on `bullmatch_private`
- non-member authenticated request resolves to no BullMatch role/membership
- one consolidated authenticated SELECT policy exists per canonical domain table
- Review Queue tables are readable only for active ADMIN/REVIEWER through RLS
- VIEWER policies do not expose Review Queue rows
- VIEWER canonical visibility is limited to VERIFIED/non-archived data
- VIEWER match visibility requires VERIFIED + `published_at is not null`

Remote assertions from `supabase/tests/p1_004_authorization.sql` passed.

## Auth state

At verification time:
- shared `auth.users`: 0 observed before this task
- `bullmatch.app_users`: 0

No production Auth user or BullMatch membership was fabricated.

## Advisor review

### Security Advisor

No security WARN/ERROR findings were introduced.

Remaining `RLS Enabled No Policy` INFO findings are confined to `bullmatch_private`, which intentionally has no browser schema usage and no browser grants.

Reference:
https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

### Performance Advisor

Initial policies produced `multiple_permissive_policies` WARN findings because staff and viewer reads were separate permissive policies.

Migration `20260906055150` consolidated them to one policy per canonical table. The WARN findings were cleared.

Remaining findings are `unused_index` INFO, expected while the database has no workload/production rows.

Reference:
https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Current Data API decision

This task does not modify the Supabase Data API exposed-schema configuration.

RLS/grants are ready if `bullmatch` is intentionally exposed later. If the application chooses server-mediated database access instead, the browser does not need direct table access.

`bullmatch_private` must never be added to browser-exposed schemas.

## First admin

See `docs/AUTHORIZATION-RUNBOOK.md`.

The first ADMIN is bootstrapped only after a real Auth account exists and a trusted operator verifies its exact `auth.users.id`.
