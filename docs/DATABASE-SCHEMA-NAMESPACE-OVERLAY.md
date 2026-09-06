# Database Schema Namespace Overlay — Shared Supabase

Task: `BMI-P0-009`
Status: **AUTHORITATIVE FOR PHASE 1 MIGRATIONS**

This document adapts `docs/DATABASE-SCHEMA.md` to the decision to run BullMatch Intelligence inside an existing shared Supabase project.

## Authoritative mapping

The earlier schema contract used generic conceptual schemas:

- `public` for canonical/review data
- `private` for ingestion/AI/provenance data

For every BullMatch Phase 1 migration and implementation, replace those conceptual names with:

```text
public   -> bullmatch
private  -> bullmatch_private
```

This replacement applies only to BullMatch-owned objects.

Supabase-owned references such as `auth.users` remain unchanged.

## Examples

```text
public.app_users                  -> bullmatch.app_users
public.bulls                      -> bullmatch.bulls
public.bull_aliases               -> bullmatch.bull_aliases
public.matches                    -> bullmatch.matches
public.match_participants         -> bullmatch.match_participants
public.match_results              -> bullmatch.match_results
public.review_cases               -> bullmatch.review_cases
public.review_actions             -> bullmatch.review_actions

private.sources                   -> bullmatch_private.sources
private.source_items              -> bullmatch_private.source_items
private.evidence                  -> bullmatch_private.evidence
private.agent_runs                -> bullmatch_private.agent_runs
private.extraction_runs           -> bullmatch_private.extraction_runs
private.claims                    -> bullmatch_private.claims
private.claim_evidence            -> bullmatch_private.claim_evidence
private.entity_match_candidates   -> bullmatch_private.entity_match_candidates
private.duplicate_candidates      -> bullmatch_private.duplicate_candidates
private.verification_results      -> bullmatch_private.verification_results
private.fact_provenance           -> bullmatch_private.fact_provenance
private.identity_events           -> bullmatch_private.identity_events
private.audit_log                 -> bullmatch_private.audit_log
private.source_runtime_state      -> bullmatch_private.source_runtime_state
```

## Foreign-key rewrite rule

All BullMatch-to-BullMatch foreign keys must use the mapped schema.

Example:

```text
references public.bulls(id)
```

becomes:

```text
references bullmatch.bulls(id)
```

and:

```text
references private.sources(id)
```

becomes:

```text
references bullmatch_private.sources(id)
```

References to `auth.users(id)` do not change.

## Shared Auth rule

`auth.users` is shared identity infrastructure across applications in the selected Supabase project.

BullMatch membership/roles live in:

`bullmatch.app_users`

An authenticated user without an active BullMatch membership row receives no BullMatch reviewer/admin privileges.

## Data API rule

Custom schema exposure is explicit.

- `bullmatch_private` must never be exposed to browser clients.
- `bullmatch` may be added to exposed schemas only when Phase 1 intentionally enables direct Data API reads/writes and RLS/grants have passed tests.
- privileged review, publish, merge and split operations should use controlled server-side operations.

## Migration rule

BullMatch migrations may create/alter only:

- `bullmatch.*`
- `bullmatch_private.*`
- explicitly approved BullMatch-scoped Storage/Edge Function/platform configuration

They may reference but never alter Supabase-managed `auth` objects.

No BullMatch migration may alter another application's tables.

## Selected host baseline

Selected shared host: `aodxx's Project`.

Initial inventory observed before DDL:
- no application tables in `public`
- no BullMatch schemas
- no application migration history reported
- no Edge Functions reported
- no current `auth.users` rows

The project was restoring from inactive state when this baseline was recorded. Inventory must be repeated after status becomes ACTIVE and immediately before migration.

## Conflict rule

If `docs/DATABASE-SCHEMA.md` names `public`/`private` and this overlay names `bullmatch`/`bullmatch_private`, this overlay wins for Phase 1 and later implementation.

The next full database-schema revision should fold these names into the main schema document so the overlay can eventually be retired.
