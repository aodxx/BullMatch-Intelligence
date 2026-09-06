# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database**

Overall status: **SUPABASE BOOTSTRAP APPLIED / REVIEW READY**

## Phase 0

Phase 0 — Foundation & Architecture is COMPLETE.

Key approved foundations:
- `PRD.md` v0.2
- `ARCHITECTURE.md` v0.2
- database contract + shared-Supabase namespace overlay
- AI/verification contracts
- Source Registry/Connector contract
- Entity Resolution strategy
- Human Review Queue UX
- multi-agent Task ID/branch/PR workflow

## Current Work

### BMI-P1-001 — Shared Supabase Bootstrap

Status: **REVIEW**
Tracking: Issue #15
Branch: `agent/bmi-p1-001-supabase-bootstrap`

Selected existing Supabase host:

**`aodxx's Project`**

BullMatch continues to avoid creating a third Supabase project.

Existing `freshmart` remains outside BullMatch scope.

## Applied Migration

Migration version:

`20260906052726`

Migration name:

`bootstrap_bullmatch_shared_tenancy`

Created:
- schema `bullmatch`
- schema `bullmatch_private`
- table `bullmatch.app_users`
- RLS policy `bullmatch_members_read_own_membership`
- private-by-default schema/table/function/sequence privilege baseline

No bull/match/source tables have been created yet.

## Verified Isolation Results

After DDL:

- `bullmatch` schema exists: PASS
- `bullmatch_private` schema exists: PASS
- unrelated `public` application table count remains 0: PASS
- RLS on `bullmatch.app_users`: PASS
- authenticated role has `USAGE` on `bullmatch`: PASS
- authenticated role has no `USAGE` on `bullmatch_private`: PASS
- anon role has no `USAGE` on `bullmatch_private`: PASS
- authenticated role may SELECT membership subject to RLS: PASS
- authenticated role has no direct INSERT on membership: PASS
- authenticated role has no direct UPDATE on membership: PASS
- own-membership policy exists exactly once: PASS

Supabase post-DDL advisors:
- Security Advisor: no findings
- Performance Advisor: no findings

## Membership Boundary

Shared `auth.users` provides project-wide identity only.

BullMatch authorization is app-scoped through:

`bullmatch.app_users`

A user does not receive BullMatch admin/reviewer/viewer membership merely by existing in shared Auth.

Browser authenticated users cannot create or edit their own BullMatch role directly.

## Private Boundary

`bullmatch_private` is reserved for:
- sources
- source items
- evidence metadata
- AI/extraction claims
- entity/duplicate/verification candidates
- provenance
- identity/audit history
- connector/agent runtime state

`anon` and `authenticated` have no schema usage there.

## Repository Evidence

- `supabase/migrations/20260906052726_bootstrap_bullmatch_shared_tenancy.sql`
- `supabase/tests/p1_001_shared_tenancy_isolation.sql`
- `supabase/P1-001-VERIFICATION.md`

## Next Integration Gate

Merge `BMI-P1-001`, then start:

### BMI-P1-002 — Core Database Migrations

It will create:
- owners/camps/bulls/venues/events + aliases
- matches/participants/results
- review cases/actions with concurrency/idempotency support
- source/evidence/agent/candidate/provenance/runtime tables
- integrity/index/RLS policies and tests

## Current Blockers

There is no blocker for core database migration work after BMI-P1-001 is merged.

Still intentionally deferred:
- production BullMatch users/seeds
- final web framework/hosting
- AI provider selection
- first production source selection/compliance validation

## Handoff Rule

Every new contributor must read the repository control/docs first, then claim one READY Task ID on an isolated branch. Shared Supabase migrations must remain strictly BullMatch-scoped.
