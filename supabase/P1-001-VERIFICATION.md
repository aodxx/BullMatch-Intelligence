# BMI-P1-001 Verification — Shared Supabase Bootstrap

Date: 2026-09-06
Host: `aodxx's Project`
Supabase project ref: `kaanguobjhlusjvgbowt`
Migration version: `20260906052726`
Migration name: `bootstrap_bullmatch_shared_tenancy`

## Applied objects

- schema `bullmatch`
- schema `bullmatch_private`
- table `bullmatch.app_users`
- RLS policy `bullmatch_members_read_own_membership`
- default privilege boundary for future BullMatch objects

## Verified after migration

- `bullmatch` exists: PASS
- `bullmatch_private` exists: PASS
- pre-existing `public` application table count remains 0: PASS
- RLS enabled on `bullmatch.app_users`: PASS
- `authenticated` has `USAGE` on `bullmatch`: PASS
- `authenticated` has no `USAGE` on `bullmatch_private`: PASS
- `anon` has no `USAGE` on `bullmatch_private`: PASS
- `authenticated` may `SELECT` `bullmatch.app_users` subject to RLS: PASS
- `authenticated` has no direct `INSERT`: PASS
- `authenticated` has no direct `UPDATE`: PASS
- expected own-membership policy exists exactly once: PASS

## Advisor checks after DDL

- Supabase Security Advisor: no lint findings
- Supabase Performance Advisor: no lint findings

## Important behavior

The shared Supabase `auth.users` table is identity infrastructure only. A user gains BullMatch membership/role only by having an active row in `bullmatch.app_users`.

The browser-facing authenticated role cannot create or change its own membership/role directly.

`bullmatch_private` remains inaccessible to `anon` and `authenticated` roles.

## Scope intentionally not included

- no bull/camp/venue/match tables yet
- no production users or seed data
- no BullMatch Edge Functions
- no Data API exposed-schema configuration change
- no changes to `freshmart`

## Next gate

`BMI-P1-002` can create the core BullMatch domain and private ingestion/review tables using the locked `bullmatch` / `bullmatch_private` namespace model.
