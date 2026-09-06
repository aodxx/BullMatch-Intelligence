# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database + Frontend Integration**

Overall status: **VERIFIED STATISTICS APPLIED / AUTH NEXT**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24
- BMI-APP-001 Frontend Foundation & First Screens — DONE via PR #26

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Current Work — BMI-P1-007

Status: **REVIEW**
Tracking: Issue #28
Branch: `agent/bmi-p1-007-bull-stats`
Applied migration: `20260906084340_add_bullmatch_verified_profile_statistics`

## Verified Statistics Foundation

Read models:
- `bullmatch.published_bull_match_history`
- `bullmatch.published_bull_opponent_history`
- `bullmatch.bull_basic_stats`
- `bullmatch.bull_recent_form`

Authoritative statistics include only:
- VERIFIED matches
- published matches
- non-archived matches
- verified known results
- verified, non-archived Bull entities

### Win rate

`wins / (wins + losses + draws) * 100`

NO_RESULT and CANCELLED remain visible as separate counts/history but do not affect win rate.

### Recent form

Latest five W/L/D results only. NO_RESULT and CANCELLED are excluded.

### Historical integrity

Statistics history uses the match-time participant snapshot. Editing a Bull's current canonical name does not rewrite historical `display_name_snapshot` values.

## Security Boundary

- browser roles have zero direct table write grants
- all state-changing commands enforce ACTIVE ADMIN membership
- REVIEWER / VIEWER / non-member mutation attempts fail
- private audit data remains inaccessible to browser roles
- frontend contains no service-role secret
- BullMatch mutation functions are not wired directly to the browser
- statistics views currently grant SELECT only to `service_role`
- all statistics views use `security_invoker = true`

## Verification

Remote rollback-only P1-007 regression test passed on the real shared Supabase project.

Fixture result:
- published matches: 5
- statistical matches: 3
- W/L/D: 1/1/1
- no-result: 1
- cancelled: 1
- win rate: 33.33%
- recent form: LOSS, DRAW, WIN

Also verified:
- unpublished match excluded
- unverified Bull excluded
- opponent history available for future H2H
- historical snapshot survives current-name edits
- anon/authenticated cannot directly SELECT stats views
- rollback leaves no fixture data

Artifact:
- `supabase/P1-007-VERIFICATION.md`

## Advisors

Security: no WARN/ERROR introduced. Existing private-schema `RLS Enabled No Policy` INFO remains intentional.
Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

Performance: no actionable WARN introduced. Remaining `unused_index` INFO is expected before real workload statistics exist.
Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Frontend

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

Current app shell includes Dashboard, Bulls, Bull Profile, Matches, Match Detail, Manual Entry, Review Queue and Settings/Profile.

Real-data surfaces intentionally remain empty until secure Auth/API wiring is implemented.

## Next Gates

1. Merge **BMI-P1-007**
2. **BMI-APP-002 — Supabase Auth Login UI**
3. Define/implement controlled API boundary
4. **BMI-APP-003 — Wire verified read data and ADMIN actions**

## Still Deferred

- actual first production ADMIN activation using a real Auth account
- AI provider selection
- first production source selection/compliance approval
