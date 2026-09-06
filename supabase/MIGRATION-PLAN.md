# Supabase Migration Plan — Phase 1

Task dependency: `BMI-P0-002`
Status: design only; no Supabase project has been modified.

## Goal

Turn `docs/DATABASE-SCHEMA.md` into reproducible, reviewable migrations after the BullMatch Intelligence Supabase project is selected/created.

## Migration sequence

1. bootstrap schemas/extensions
2. auth-facing `app_users`
3. canonical owner/camp/bull/venue/event tables + aliases
4. matches + participants + results
5. review workflow
6. private source/evidence ingestion
7. private agent/extraction/claim layer
8. matching/duplicate/verification layer
9. provenance/identity/audit layer
10. indexes and cross-table integrity helpers
11. explicit grants and RLS
12. database policy/integrity tests

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

## Test baseline

Create SQL tests under `supabase/tests/` for at least:

- anon cannot write canonical tables
- anon cannot reach private ingestion/evidence tables
- public statistics cannot include unverified/conflict matches
- reviewer cannot arbitrarily update canonical matches
- admin/reviewer actions are constrained by intended role
- winner participant must belong to the same match
- duplicate ingestion key is idempotent
- source evidence survives candidate rejection

Run security and performance advisors after DDL and resolve actionable findings before release.

## Migration file rule

When implementation starts, create migration files using the current Supabase CLI workflow rather than inventing timestamps/file names manually. Keep one logical migration concern per file where practical.

## Out of scope for this design task

- creating the Supabase project
- applying production DDL
- inserting production data
- storing secrets
- choosing the first source connector
