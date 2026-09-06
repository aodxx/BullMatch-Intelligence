# Database Schema Namespace Overlay — Shared Supabase

Task: `BMI-P0-009`
Status: **HISTORICAL / FOLDED INTO DATABASE SCHEMA v0.2**
Last updated: 2026-09-07

This document originally adapted the Phase 0 conceptual schema names to the decision to run BullMatch Intelligence inside an existing shared Supabase project.

## Current authoritative rule

`docs/DATABASE-SCHEMA.md` v0.2 now uses the production schema names directly and is authoritative for all new BullMatch schema work:

```text
bullmatch         — canonical application/domain/review data
bullmatch_private — contribution intake, evidence, AI, provenance and runtime data
```

The old conceptual mapping remains recorded for historical context only:

```text
public  -> bullmatch
private -> bullmatch_private
```

Supabase-managed schemas such as `auth` are never renamed or altered by BullMatch migrations.

## Shared Auth rule

`auth.users` is shared project identity infrastructure.

BullMatch privileged membership/authorization remains app-scoped in:

`bullmatch.app_users`

Schema v0.2 may add contributor participation profiles, but contributor status/reputation does not imply ADMIN or REVIEWER permission.

## Data/API boundary

- `bullmatch_private` must never be exposed directly to browser clients.
- new `bullmatch` tables start default-deny until explicit grants/RLS/API projections are implemented and tested.
- community contribution writes must be server-mediated and must not directly mutate canonical history.
- privileged review/publish/merge/split/promotion operations remain controlled server-side operations.
- service-role credentials never enter browser code.

## Migration isolation

BullMatch migrations may create or alter only:

- `bullmatch.*`
- `bullmatch_private.*`
- explicitly approved BullMatch-scoped Storage/Edge Function/platform objects

They may reference, but must never alter, Supabase-managed `auth` objects.

They must never modify unrelated application schemas/tables in the shared project.

## Production compatibility

The deployed production API continues to read existing verified/published canonical tables. Schema v0.2 is additive and does not rename/drop those tables or change their IDs.

The authoritative compatibility, migration order and rollback plan now live in `docs/DATABASE-SCHEMA.md` v0.2.

## Conflict rule

For all work after BMI-P1-011, if this historical overlay conflicts with `docs/DATABASE-SCHEMA.md` v0.2, **Database Schema v0.2 wins**.