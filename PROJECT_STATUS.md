# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database**

Overall status: **CONTROLLED DOMAIN CRUD APPLIED / REVIEW READY**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Current Work — BMI-P1-005

Status: **REVIEW**
Tracking: Issue #21
Branch: `agent/bmi-p1-005-domain-crud`

### Applied migrations

- `20260906055912` — Owner/Camp CRUD + security/validation/audit helpers
- `20260906060030` — Bull/Venue CRUD + archive/verification/alias operations

## Controlled Mutation Model

Browser roles still have **zero direct table write grants** in `bullmatch`.

State changes occur only through ADMIN mutation functions.

Each exposed mutation:
- is `SECURITY DEFINER`
- uses `search_path = ''`
- immediately verifies current `auth.uid()` through internal `bullmatch.require_admin()`
- requires ACTIVE ADMIN membership in `bullmatch.app_users`
- validates allowed input fields
- writes an audit event to `bullmatch_private.audit_log`

Internal helpers are not executable by browser roles.

## Domain Operations Available

### Owner
- create
- update
- archive
- verification state
- alias upsert / alias verification

### Camp
- create
- update
- archive
- verification state
- alias upsert / alias verification

### Bull
- create
- update
- archive
- verification state
- alias upsert / alias verification

### Venue
- create
- update
- archive
- verification state
- alias upsert / alias verification

New canonical entities start `UNVERIFIED`. An ADMIN must explicitly choose a verification transition.

## Normalization

`bullmatch.normalize_entity_name` preserves Thai semantic marks.

It only:
- trims outer whitespace
- collapses repeated whitespace
- applies lowercase/case folding where applicable

Displayed canonical names remain unchanged except for explicit ADMIN edits.

## Audit

All successful mutations write private audit records containing:
- Auth actor UUID
- action
- entity type / entity ID
- before/after or operation metadata

The browser cannot read `bullmatch_private.audit_log` directly.

## Verification

Remote rollback-only integration tests passed on the actual shared Supabase database.

Verified:
- ADMIN creates Owner/Camp/Bull/Venue
- Owner/Camp references validate active linked records
- new entity defaults UNVERIFIED
- Thai whitespace normalization works
- update works
- explicit entity verification works
- alias create/verification works
- soft archive works
- audit events are created
- REVIEWER mutation rejected
- VIEWER mutation rejected
- non-member mutation rejected
- private audit read blocked while impersonating browser role
- trusted context can inspect audit trail
- rollback leaves no test users/memberships/domain rows

Post-test:
- leaked temporary Auth users: 0
- leaked temporary memberships: 0
- browser direct write grants: 0
- authenticated private-schema usage: false

Artifacts:
- `supabase/tests/p1_005_domain_crud.sql`
- `supabase/P1-005-VERIFICATION.md`

## Advisor Review

### Security

No WARN/ERROR security findings introduced.

Private-schema `RLS Enabled No Policy` INFO remains intentional because `bullmatch_private` has no browser schema access/grants.

### Performance

No new actionable WARN findings.

Remaining `unused_index` INFO is expected on the empty/new database; defer removal until real query statistics exist.

## Production Data

No production BullMatch entities or users were added.

This project intentionally avoids fabricated seed data. Real records should originate from trusted manual entry or later verified collection.

## Next Integration Gate

Merge BMI-P1-005, then start:

### BMI-P1-006 — Manual Match Entry & Verification

This will provide controlled event/match creation, participant historical snapshots, result entry, verification and publication operations while preserving existing database integrity guards.

After P1-006, **BMI-P1-007 Bull Profile & Basic Statistics** can use real verified match structure.

## Still Deferred

- actual first ADMIN activation (requires a real Auth account)
- frontend/login UI and hosting choice
- AI provider selection
- first production source selection/compliance approval

These do not block the database/domain workflow implementation.
