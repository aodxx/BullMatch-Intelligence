# Supabase Migration Plan — Phase 1

Task dependencies: `BMI-P0-002`, `BMI-P0-006`, `BMI-P0-009`
Status: design only; no BullMatch production DDL has been applied.

## Goal

Turn the BullMatch database contract into reproducible, reviewable migrations inside the existing shared Supabase project while preserving strict application isolation.

Selected shared host:
- `aodxx's Project`

BullMatch-owned schemas:
- `bullmatch`
- `bullmatch_private`

Shared infrastructure:
- `auth.users`
- Supabase Storage/platform schemas where explicitly used

`freshmart` is not part of BullMatch migration scope.

## Migration sequence

1. inventory/check shared project state
2. bootstrap `bullmatch` and `bullmatch_private`
3. enable required extensions without explicit version pinning
4. create `bullmatch.app_users` linked to shared `auth.users`
5. canonical owner/camp/bull/venue/event tables + aliases in `bullmatch`
6. matches + participants + results in `bullmatch`
7. review workflow in `bullmatch`
8. source registry/evidence ingestion in `bullmatch_private`
9. `bullmatch_private.source_runtime_state`
10. agent/extraction/claim layer in `bullmatch_private`
11. matching/duplicate/verification layer in `bullmatch_private`
12. provenance/identity/audit layer in `bullmatch_private`
13. indexes and cross-table integrity helpers
14. explicit grants, RLS and Data API exposure decisions
15. database policy/integrity/isolation tests
16. security/performance advisor review

## Shared Host Inventory Baseline

Observed before the first BullMatch DDL:
- existing Supabase projects: `aodxx's Project` and `freshmart`
- `aodxx's Project` selected as BullMatch shared-main
- no application tables observed in `public`
- no BullMatch schemas observed
- no user rows observed in shared `auth.users`
- no application migrations reported for the selected host
- no Edge Functions reported for the selected host
- host is being restored from inactive state and must be ACTIVE before DDL

Re-run this inventory immediately before migration because shared projects can change.

## Namespace Overlay

The original Phase 0 schema document used conceptual names `public` and `private` before the shared-project decision.

For Phase 1 migration generation, use this authoritative mapping:

```text
public.<bullmatch-owned-table>  -> bullmatch.<table>
private.<bullmatch-owned-table> -> bullmatch_private.<table>
```

Examples:
- `public.bulls` -> `bullmatch.bulls`
- `public.matches` -> `bullmatch.matches`
- `public.review_cases` -> `bullmatch.review_cases`
- `private.sources` -> `bullmatch_private.sources`
- `private.evidence` -> `bullmatch_private.evidence`
- `private.agent_runs` -> `bullmatch_private.agent_runs`

References to Supabase system schemas such as `auth.users` remain unchanged.

No generated migration may create BullMatch-owned application tables in generic `public`.

## Source Runtime State

Recommended table:

`bullmatch_private.source_runtime_state`

- `source_id uuid primary key references bullmatch_private.sources(id)`
- `cursor_strategy text not null default 'NONE'`
- `cursor jsonb null`
- `last_attempt_at timestamptz null`
- `last_success_at timestamptz null`
- `consecutive_failures integer not null default 0`
- `cooldown_until timestamptz null`
- `last_health text null`
- `last_error_code text null`
- `state jsonb not null default '{}'::jsonb`
- `updated_at timestamptz not null default now()`

Critical transaction rule: a connector-proposed cursor is persisted only after the corresponding source item/evidence ingestion reaches a safe committed checkpoint.

## Auth and Membership Boundary

Shared `auth.users` is identity infrastructure only.

BullMatch authorization uses:

`bullmatch.app_users`

A row in `auth.users` without an active BullMatch membership row grants no BullMatch privileged access.

Do not use user-editable metadata for authorization.

## Required Supabase checks before first DDL

- selected host status is ACTIVE
- re-inventory all non-system schemas/tables
- confirm `bullmatch` and `bullmatch_private` are unused
- inspect current Supabase changelog and security guidance
- inspect Data API exposed-schema settings
- confirm Postgres version/features
- confirm available extension names; do not pin extension versions
- inspect current migrations/functions/storage buckets if accessible
- decide direct Data API versus server-mediated access for `bullmatch`
- guarantee `bullmatch_private` is not browser-exposed

## Security baseline

- `bullmatch_private` is not exposed to public/browser clients
- every exposed `bullmatch` table has RLS enabled
- grants are explicit and least-privilege
- browser code uses only publishable credentials
- service-role/secret credentials remain backend-only
- reviewer/admin authority comes from `bullmatch.app_users`
- `TO authenticated` alone is never sufficient authorization
- exposed views use `security_invoker = true` where supported/appropriate
- connector runtime state and credentials are not exposed to public clients
- migrations cannot modify unrelated application schemas

## Data API rule

Do not assume a new table is automatically available through the Supabase Data API.

For BullMatch:
- custom schema exposure is an explicit deployment decision
- `bullmatch_private` is never exposed
- `bullmatch` may be exposed only after RLS/grants are tested
- privileged review/publish/merge/split operations should be server-mediated even if read tables are exposed

## Test baseline

Create SQL/integration tests under `supabase/tests/` for at least:

- anon cannot write `bullmatch` canonical tables
- browser roles cannot access `bullmatch_private`
- shared authenticated user without BullMatch membership has no privileged BullMatch access
- BullMatch reviewer cannot access unrelated app schemas through BullMatch operations
- public statistics cannot include unverified/conflict matches
- reviewer cannot arbitrarily update canonical matches
- admin/reviewer actions follow intended roles
- winner participant belongs to the same match
- duplicate ingestion key is idempotent
- source evidence survives candidate rejection
- connector cursor does not advance on failed ingestion checkpoint
- repeated `(source_id, dedupe_key)` polling does not create duplicates
- BullMatch migration inventory before/after shows unrelated schemas unchanged

Run security and performance advisors after DDL and resolve actionable findings before release.

## Migration ownership rule

BullMatch migration files live only in this repository and may modify:
- `bullmatch.*`
- `bullmatch_private.*`
- explicitly approved BullMatch Storage/Edge Function/platform configuration

They may reference `auth.users`, but they must not alter Supabase-managed auth tables.

They may not rename, drop or alter another application's objects.

## Migration file rule

When implementation starts, use the current Supabase migration workflow rather than inventing filenames/version assumptions. Keep one logical migration concern per file where practical.

## Rollback / portability

Keep domain objects fully qualified and BullMatch-owned so a future move to a dedicated Supabase project can export/import `bullmatch` and `bullmatch_private` with minimal application-domain change.

## Out of scope until host is ACTIVE

- applying BullMatch DDL
- inserting production data
- creating production users
- storing secrets
- selecting/activating the first production source connector
