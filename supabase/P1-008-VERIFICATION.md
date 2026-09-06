# BMI-P1-008 Review Backend Foundation — Verification

Status: **FOUNDATION SLICE IMPLEMENTED / TASK REMAINS IN PROGRESS**

Production project: `kaanguobjhlusjvgbowt`

## Implemented in this slice

- claim lifecycle now includes `VERIFIED`, `SUPERSEDED`, and `WITHDRAWN` in addition to existing proposal/conflict states
- explicit `bullmatch_private.review_case_claims` linkage between review cases and atomic claims
- service-only `bullmatch_api_review_query` for:
  - reviewer queue
  - review case detail
  - atomic claims
  - supporting/contradicting/context evidence
  - entity-match and duplicate candidates
  - append-only decision history
- service-only `bullmatch_api_review_command`
- ACTIVE `ADMIN` / `REVIEWER` authorization enforced again inside PostgreSQL
- `command_id` idempotency
- optimistic `expected_case_status` + `expected_case_version` checks
- reviewer commands implemented for:
  - `CLAIM`
  - `UNCLAIM`
  - `COMMENT`
  - `APPROVE`
  - `REJECT`
  - `RESOLVE_CONFLICT`
  - `REOPEN`
- `MERGE` / `SPLIT` execution explicitly blocked in this foundation
- append-only `review_actions` + private `audit_log` for successful commands
- Edge Function reviewer routes for ACTIVE ADMIN/REVIEWER while preserving existing public read and ADMIN command paths

## Canonical-data boundary

`APPROVE` changes an atomic claim to `VERIFIED`; it does **not** directly update canonical Bull/Match/Event/Owner/Camp/Venue history.

Promotion from verified claim to canonical history remains a separate controlled operation that must preserve provenance and audit. This is intentional and prevents community review from becoming unrestricted canonical CRUD.

## Evidence boundary

Reviewer detail is server-mediated.

- `PUBLIC_REFERENCE`: public storage/reference may be returned
- `INTERNAL`: excerpt/source context may be returned to authorized reviewers but raw storage reference is withheld
- `RESTRICTED`: text excerpt, source title/URL, and storage reference are withheld in this API slice

Browser roles cannot call the review RPCs directly.

## Production migration

Applied migration:

`20260906211732_add_bullmatch_review_backend_foundation`

Repository migration filename is reconciled to the exact production migration version.

## Direct ACL validation

Confirmed:

- `anon` → `bullmatch_api_review_query`: **NO EXECUTE**
- `authenticated` → `bullmatch_api_review_query`: **NO EXECUTE**
- `service_role` → `bullmatch_api_review_query`: **EXECUTE**
- `anon` → `bullmatch_api_review_command`: **NO EXECUTE**
- `authenticated` → `bullmatch_api_review_command`: **NO EXECUTE**
- `service_role` → `bullmatch_api_review_command`: **EXECUTE**
- `bullmatch_private.review_case_claims` → RLS enabled

## Behavioral validation

A rollback-only production transaction verified:

1. an existing ACTIVE ADMIN/REVIEWER can `CLAIM` a temporary review case
2. case version increments from 1 to 2
3. replaying the same `command_id` returns the existing result without creating a second action
4. a stale command using expected `OPEN / version 1` after the claim is rejected with serialization/stale-state semantics
5. one review action is written for the command
6. one private audit event is written for the command
7. the entire validation fixture is rolled back

After rollback, Production still contains:

- `review_cases = 0`
- `review_actions = 0`

No fake Production review/Bull/Match data was retained.

## Advisor result

Supabase Security Advisor was run after the migration.

No new direct browser exposure of the review RPCs was reported. Existing informational `RLS enabled / no policy` notices remain on `bullmatch_private` tables by design because those tables are not browser-readable and are accessed through controlled server paths.

An existing project-level warning remains that Auth leaked-password protection is disabled; this is not introduced by BMI-P1-008.

Performance Advisor currently reports multiple unused indexes because the Production dataset is effectively empty. No index was removed based on zero-traffic development data.

## Automated regression test

`supabase/tests/p1_008_review_backend.sql` asserts:

- service-only RPC ACLs
- fixed `search_path` + SECURITY DEFINER boundary
- claim lifecycle constraint
- review-case mapping/RLS
- command idempotency
- optimistic stale-write rejection
- single action/audit record
- rollback-only fixture behavior

## Remaining BMI-P1-008 work

The task stays **IN PROGRESS**. Exact next implementation order:

1. controlled identity merge/split **impact preview** (read-only, no execution)
2. controlled verified-claim → canonical promotion operations for narrowly defined fact types, with `fact_provenance` and audit
3. implement safe `LINK_ENTITY`, `CREATE_ENTITY`, `CONFIRM_DUPLICATE`, `MARK_NOT_DUPLICATE`, and selected `EDIT` semantics against the approved domain contracts
4. wire the production Review Queue UI to the new reviewer API
5. only after impact preview/provenance rules are complete, design separately confirmed merge/split execution

Destructive identity operations remain blocked until those safeguards exist.
