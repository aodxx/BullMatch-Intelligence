# BMI-P1-005 Domain CRUD Verification

Date: 2026-09-06
Supabase host: `aodxx's Project`
Task: `BMI-P1-005`

## Applied migrations

- `20260906055912` — `add_bullmatch_admin_owner_camp_crud`
- `20260906060030` — `add_bullmatch_admin_bull_venue_alias_crud`

## Implemented operations

ADMIN-only controlled functions now support:

- Owner create / update
- Camp create / update
- Bull create / update
- Venue create / update
- generic soft archive for Owner/Camp/Bull/Venue
- explicit entity verification-state change
- alias upsert for Owner/Camp/Bull/Venue
- alias verification toggle

New canonical entities are created as `UNVERIFIED`. Verification is a separate explicit ADMIN action.

## Security model

Mutation functions are `SECURITY DEFINER` with `search_path = ''`, but they do not trust that elevation alone.

Every exposed mutation calls internal `bullmatch.require_admin()` which checks the current `auth.uid()` against an ACTIVE ADMIN row in `bullmatch.app_users`.

Internal helpers (`require_admin`, audit helper, JSON-key validator, normalizer) are not executable by `authenticated` or `anon`.

Browser roles still have zero direct INSERT/UPDATE/DELETE-style table grants in `bullmatch`.

`bullmatch_private` remains unavailable to browser roles at the schema boundary.

## Thai-safe normalization

`bullmatch.normalize_entity_name(text)`:

- trims leading/trailing whitespace
- collapses repeated whitespace to one space
- applies lowercase/case folding where applicable
- preserves Thai vowels, tone marks and semantic characters

It is used only for normalized search/matching fields and does not rewrite the displayed canonical name.

## Audit trail

Every successful domain mutation writes an internal row to `bullmatch_private.audit_log` with:

- actor type `USER`
- current Auth UUID as actor ID
- action name
- entity type / entity ID
- before/after or relevant operation metadata

Browser users cannot read this private audit table directly.

## Remote end-to-end test

The actual shared Supabase database was tested inside one transaction using rollback-only temporary Auth users/memberships:

- ADMIN successfully created Owner, Camp, Bull and Venue
- Thai whitespace normalization produced expected normalized names
- newly created entity remained UNVERIFIED
- ADMIN updated an Owner
- ADMIN explicitly verified the Owner
- ADMIN created and verified a Bull alias
- ADMIN archived a Venue using soft-delete fields
- audit records were produced for successful mutations
- REVIEWER mutation was rejected
- VIEWER mutation was rejected
- non-member mutation was rejected
- private audit table was inaccessible while impersonating browser role
- trusted context could verify audit rows
- transaction rollback removed all test data

Post-test checks confirmed:
- leaked temporary Auth users: 0
- leaked temporary BullMatch memberships: 0
- browser direct write grants: 0
- authenticated `bullmatch_private` schema usage: false

Regression test:
- `supabase/tests/p1_005_domain_crud.sql`

## Advisors

### Security

No WARN/ERROR security findings were introduced.

Remaining `RLS Enabled No Policy` INFO findings are in `bullmatch_private`, which intentionally has no browser schema access/grants.

### Performance

No new actionable WARN findings were introduced.

Remaining `unused_index` INFO findings are expected while production tables remain empty and have no representative workload. Index removal remains deferred until query statistics exist.

## Production data

This task does not insert production owners, camps, bulls, venues, aliases or users.

The next real records should come from trusted manual entry or a later verified ingestion workflow, not fabricated seed data.
