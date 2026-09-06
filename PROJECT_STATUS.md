# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database + Frontend Integration**

Overall status: **VERIFIED STATISTICS DONE / AUTH UI REVIEW READY**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE via PR #29
- BMI-APP-001 Frontend Foundation & First Screens — DONE via PR #26

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Verified Statistics Foundation

Applied migration:
`20260906084340_add_bullmatch_verified_profile_statistics`

Read models:
- `bullmatch.published_bull_match_history`
- `bullmatch.published_bull_opponent_history`
- `bullmatch.bull_basic_stats`
- `bullmatch.bull_recent_form`

Authoritative statistics include only VERIFIED/PUBLISHED facts with verified results. Win rate is `wins / (wins + losses + draws)` and excludes NO_RESULT/CANCELLED. Recent form is latest five W/L/D.

P1-007 rollback regression passed on shared Supabase with expected result 5 published matches, 1W/1L/1D, 1 no-result, 1 cancelled, 33.33% win rate, recent form LOSS/DRAW/WIN.

## Current Work — BMI-APP-002

Status: **REVIEW**
Tracking: Issue #30
Branch: `agent/bmi-app-002-auth-ui`

Implemented:
- Supabase Auth email/password login for pre-existing accounts
- project publishable key only in browser
- persistent local session
- access-token validation
- refresh-token renewal near expiry
- local logout
- Public mode for Dashboard/Bulls/Matches
- Login gate for Manual Entry and Review Queue
- return to intended protected screen after successful sign-in
- Thai loading/error states
- Settings shows actual signed-in email/session state
- no public sign-up UI

## Authorization Rule

Authentication is identity only.

**SIGNED IN does not mean ADMIN.**

APP-002 does not infer role from user metadata and does not grant data mutations. BullMatch role remains authoritative in `bullmatch.app_users` and must be resolved at the controlled server/API boundary in APP-003 before protected reads or writes become operational.

## Security Boundary

- frontend contains no service-role/secret key
- only Supabase publishable key is browser-visible
- browser has zero direct domain table writes
- `bullmatch_private` remains inaccessible to browser roles
- privileged BullMatch RPCs are not wired directly to browser
- statistics views remain service-role-only until controlled API wiring
- authentication does not elevate application role

## APP-002 Verification

Current branch Web App workflow passed:
- locked dependency install — PASS
- TypeScript — PASS
- Vite production build — PASS

Shared Supabase currently contains 0 production Auth users. No fake login/admin account was created just to make APP-002 pass.

## Frontend Deployment

Current production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

APP-002 will deploy automatically after merge to `main` through the existing GitHub Pages workflow.

## Next Gates

1. Merge **BMI-APP-002** and verify Pages deployment
2. Define/implement the controlled server/API boundary
3. **BMI-APP-003 — Wire verified read data and ADMIN actions**
4. Bootstrap the first real Auth account + BullMatch membership when operational access is required

## Still Deferred

- first real production ADMIN activation
- AI provider selection
- first production source selection/compliance approval
