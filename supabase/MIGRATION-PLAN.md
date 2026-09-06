# Supabase Migration Plan — Phase 1

Task dependencies: `BMI-P0-002`, `BMI-P0-006`
Status: design only; no Supabase project has been modified.

## Goal

Turn `docs/DATABASE-SCHEMA.md` plus the source-runtime requirements in `docs/SOURCE-REGISTRY-CONTRACT.md` into reproducible, reviewable migrations after the BullMatch Intelligence Supabase project is selected/created.

## Migration sequence

1. bootstrap schemas/extensions
2. auth-facing `app_users`
3. canonical owner/camp/bull/venue/event tables + aliases
4. matches + participants + results
5. review workflow
6. private source registry/evidence ingestion
7. `private.source_runtime_state` for connector cursor/health/cooldown state
8. private agent/extraction/claim layer
9. matching/duplicate/verification layer
10. provenance/identity/audit layer
11. indexes and cross-table integrity helpers
12. explicit grants and RLS
13. database policy/integrity tests

## Source Runtime State Addition

`BMI-P0-006` established that rapidly changing connector cursor/health data should be separated from source policy/configuration.

Recommended table:

`private.source_runtime_state`

- `source_id uuid primary key references private.sources(id)`
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

## Required Supabase checks before first DDL

- review current Supabase changelog and database/API security docs
- inspect project Data API exposed-schema settings
- confirm project Postgres version/features
- confirm available extension names; do not pin extension versions
- decide whether frontend needs direct Data API access or server-mediated operations for each table

## Security baseline

- `private` schema is not exposed to public clients
- every exposed table has RLS enabled
- grants are explicit and least-privilege
- browser code uses only publishable credentials
- service-role/secret credentials remain backend-only
- reviewer/admin authority is derived from server-controlled role data, never user-editable metadata
- exposed views use `security_invoker = true` when used
- source runtime state and connector credentials are not exposed to public clients

## Test baseline

Create SQL tests under `supabase/tests/` for at least:

- anon cannot write canonical tables
- anon cannot reach private ingestion/evidence/runtime-state tables
- public statistics cannot include unverified/conflict matches
- reviewer cannot arbitrarily update canonical matches
- admin/reviewer actions are constrained by intended role
- winner participant must belong to the same match
- duplicate ingestion key is idempotent
- source evidence survives candidate rejection
- connector cursor does not advance on failed ingestion transaction/checkpoint
- repeated poll with the same `(source_id, dedupe_key)` does not create duplicate source items

Run security and performance advisors after DDL and resolve actionable findings before release.

## Migration file rule

When implementation starts, create migration files using the current Supabase CLI workflow rather than inventing timestamps/file names manually. Keep one logical migration concern per file where practical.

## Out of scope for this design task

- creating the Supabase project
- applying production DDL
- inserting production data
- storing secrets
- choosing the first source connector
