# Shared Supabase Tenancy Strategy v0.2

Task: `BMI-P0-009`
Status: **DESIGN LOCK / HOST SELECTED**

## Goal
Run BullMatch Intelligence inside an existing Supabase free-plan project without creating a third Supabase project, while isolating BullMatch data, permissions, migrations, and operational state from other applications sharing the same Supabase organization/project.

## Selected host

Primary shared host:

`aodxx's Project`

Secondary existing project:

`freshmart`

Do not use or modify `freshmart` for BullMatch unless a later capacity/isolation decision explicitly moves the app.

## Observed host inventory

Initial inspection of `aodxx's Project` found:

- no application tables in `public`
- no BullMatch schemas
- no rows in `auth.users`
- no application migration history reported
- no Edge Functions reported
- Postgres 17 family
- project was being restored from inactive state at inspection time

This makes it a suitable shared-main candidate, but this inventory is not permanent. Re-run it immediately before the first migration because another app/team may change the shared project.

## Namespace model
BullMatch uses dedicated PostgreSQL schemas:

- `bullmatch` — application-facing canonical data and review workflow
- `bullmatch_private` — ingestion, AI candidates, evidence metadata, provenance, runtime state, audit data

Do not create generic BullMatch-owned tables directly in `public`.

Supabase system schemas such as `auth`, `storage`, `extensions`, `realtime`, and other platform-managed schemas remain shared infrastructure and must not be modified except through supported Supabase configuration.

## Authentication model
`auth.users` is shared at the Supabase-project level. BullMatch authorization is therefore app-scoped, not project-global.

BullMatch creates its own membership/profile table:

`bullmatch.app_users`

Minimum fields:
- `user_id uuid primary key references auth.users(id)`
- `role text` (`ADMIN`, `REVIEWER`, `VIEWER`)
- `status text`
- timestamps

A person existing in `auth.users` does not automatically become a BullMatch user. Access requires a matching active row in `bullmatch.app_users`.

Never use user-editable auth metadata for BullMatch authorization.

## RLS boundary
All browser-reachable BullMatch tables must use RLS.

Policies must check BullMatch-specific membership/role records. `TO authenticated` alone is not sufficient authorization.

`bullmatch_private` must remain inaccessible to anonymous/browser clients. Backend workers use trusted server-side credentials and controlled interfaces.

## Data API boundary
BullMatch uses custom schemas, so API exposure is an explicit deployment choice.

Rules:
- never expose `bullmatch_private` to browser clients
- expose `bullmatch` only if the application needs direct Data API access
- test grants + RLS before exposure
- prefer server-mediated operations for privileged review/publish/merge/split workflows
- do not assume a newly created table is automatically available through the Data API

## Migration ownership
BullMatch migration files remain in the BullMatch GitHub repository and may modify only:

- `bullmatch.*`
- `bullmatch_private.*`
- explicitly approved BullMatch-scoped Storage/Edge Function/platform configuration

A BullMatch migration must not rename/drop/change tables belonging to another application.

BullMatch may reference `auth.users` but must not alter Supabase-managed Auth tables.

Every migration must be review/impact aware and include rollback or recovery notes where relevant.

## Naming
Inside dedicated schemas, use clean domain names such as:
- `bullmatch.bulls`
- `bullmatch.camps`
- `bullmatch.matches`
- `bullmatch.review_cases`
- `bullmatch_private.sources`
- `bullmatch_private.source_items`
- `bullmatch_private.evidence`
- `bullmatch_private.agent_runs`

Do not combine schema isolation with redundant table prefixes unless a platform constraint later requires it.

## Storage
If Supabase Storage is used, buckets or object paths must be BullMatch-scoped, for example:
- bucket `bullmatch-evidence-private`
- bucket `bullmatch-public-media`

Google Drive remains the project workspace for project documents, handoffs, and selected bulky/manual evidence.

## Edge Functions / Cron / workers
Function names must use a BullMatch prefix or namespace convention, e.g.:
- `bullmatch-ingest`
- `bullmatch-review-action`
- `bullmatch-daily-report`

Scheduled jobs must not assume they are the only workload in the Supabase project.

BullMatch code must not modify the Supabase-managed `realtime` schema.

## Resource-awareness rule
Because multiple applications share one free Supabase project, BullMatch must monitor and control:
- database growth
- storage growth
- scheduled job frequency
- AI/external API usage
- query/index cost
- log volume

Heavy source evidence should prefer external/Drive/object storage with hashes and references rather than storing large blobs in PostgreSQL.

## Current Supabase compatibility notes

Before implementation, account for current platform behavior:
- extension version pinning is deprecated; create required extensions without explicit version clauses
- the Supabase-managed `realtime` schema is locked down against modifications
- Data API exposure is increasingly explicit rather than something BullMatch should assume automatically

These points are deployment guidance; the latest Supabase changelog and security documentation must be checked again before DDL/release.

## Deployment guard
Before applying the first BullMatch migration:
1. confirm the selected Supabase project is `ACTIVE`
2. re-inventory existing non-system schemas/tables
3. verify `bullmatch` and `bullmatch_private` do not already exist with unrelated ownership
4. inspect Data API exposed-schema settings
5. inspect current RLS/security advisors
6. inspect current migrations/functions/storage use
7. create BullMatch schemas first
8. apply only BullMatch-scoped migrations
9. run isolation tests proving existing app tables are unchanged and inaccessible through BullMatch policies
10. run Supabase security and performance advisors after DDL

## Isolation acceptance tests
Phase 1 must prove:
- BullMatch anon users cannot write canonical data
- BullMatch reviewers cannot access another app's tables through BullMatch APIs
- another app/shared authenticated user without `bullmatch.app_users` membership has no BullMatch privileged access
- BullMatch workers cannot accidentally publish raw AI candidate data
- BullMatch migrations do not alter unrelated schemas
- BullMatch private ingestion data is not exposed through the browser Data API
- migration before/after inventory confirms unrelated objects are unchanged

## Capacity / future split
Shared tenancy is an optimization for the current free-plan stage, not a permanent architectural requirement.

The BullMatch application uses app-owned schemas and repository-managed migrations so it can later be moved to a dedicated Supabase project with minimal domain changes if usage, security, or operational load requires isolation.
