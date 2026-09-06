# Shared Supabase Tenancy Strategy v0.1

Task: BMI-P0-009
Status: DESIGN LOCK

## Goal
Run BullMatch Intelligence inside an existing Supabase free-plan project without creating a third Supabase project, while isolating BullMatch data, permissions, migrations, and operational state from other applications sharing the same Supabase organization/project.

## Selected host
Primary candidate host: `aodxx's Project` (`kaanguobjhlusjvgbowt`).

Do not use `freshmart` for BullMatch unless a later capacity or isolation decision explicitly moves the app.

## Namespace model
BullMatch uses dedicated PostgreSQL schemas:

- `bullmatch` — application-facing canonical data and review workflow
- `bullmatch_private` — ingestion, AI candidates, evidence metadata, provenance, runtime state, audit data

Do not create generic BullMatch-owned tables directly in `public`.

Supabase system schemas such as `auth`, `storage`, `extensions`, and other platform-managed schemas remain shared infrastructure.

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

## Migration ownership
BullMatch migration files remain in the BullMatch GitHub repository and may modify only:

- `bullmatch.*`
- `bullmatch_private.*`
- explicitly approved shared platform configuration

A BullMatch migration must not rename/drop/change tables belonging to another application.

Every migration must be idempotency/review aware and must include rollback/impact notes where relevant.

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

## Resource-awareness rule
Because multiple applications share one free Supabase project, BullMatch must record and control:
- database growth
- storage growth
- scheduled job frequency
- AI/external API usage
- query/index cost
- log volume

Heavy source evidence should prefer external/Drive/object storage with hashes and references rather than storing large blobs in PostgreSQL.

## Deployment guard
Before applying the first BullMatch migration:
1. confirm the selected Supabase project is ACTIVE
2. inventory existing non-system schemas/tables
3. verify `bullmatch` and `bullmatch_private` do not already exist with unrelated ownership
4. inspect Data API exposed-schema settings
5. inspect current RLS/security advisors
6. create BullMatch schemas first
7. apply only BullMatch-scoped migrations
8. run isolation tests proving existing app tables are unchanged and inaccessible through BullMatch policies

## Isolation acceptance tests
Phase 1 must prove:
- BullMatch anon users cannot write canonical data
- BullMatch reviewers cannot access another app's tables through BullMatch APIs
- another app's authenticated user without `bullmatch.app_users` membership has no BullMatch privileged access
- BullMatch workers cannot accidentally publish raw AI candidate data
- BullMatch migrations do not alter unrelated schemas
- BullMatch private ingestion data is not exposed through the browser Data API

## Capacity / future split
Shared tenancy is an optimization for the current free-plan stage, not a permanent architectural requirement.

The BullMatch application must use app-owned schemas and repository-managed migrations so it can later be moved to a dedicated Supabase project with minimal domain changes if usage, security, or operational load requires isolation.
