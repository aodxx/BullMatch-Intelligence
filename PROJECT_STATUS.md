# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database + Frontend Integration**

Overall status: **PRODUCTION READ API WIRED / APP-003 REVIEW**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24
- BMI-P1-007 Bull Profile & Basic Statistics — DONE via PR #29
- BMI-APP-001 Frontend Foundation & First Screens — DONE via PR #26
- BMI-APP-002 Supabase Auth Login UI — DONE via PR #31

Selected shared Supabase host: **`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Current Work — BMI-APP-003

Status: **REVIEW**
Tracking: Issue #32
Branch: `agent/bmi-app-003-api-data`

Applied migration:
`20260906092707_add_bullmatch_controlled_api_bridge`

Deployed Edge Function:
- `bullmatch-api`
- version 1
- status ACTIVE

## API Boundary

The browser does not receive a service-role key and does not execute BullMatch database functions directly.

Flow:

`GitHub Pages React app → bullmatch-api Edge Function → service-only public RPC bridge → bullmatch/bullmatch_private domain`

The three bridge RPCs are:
- `public.bullmatch_api_public_query`
- `public.bullmatch_api_member`
- `public.bullmatch_api_admin_command`

`PUBLIC`, `anon`, and `authenticated` have no EXECUTE permission on these functions. Only `service_role` may execute them.

Public API returns only verified/published read data. Protected requests validate the user's access token against Supabase Auth before resolving membership or accepting a command.

ADMIN mutations are protected twice:
1. Edge Function requires ACTIVE ADMIN membership.
2. Existing BullMatch domain functions independently call `require_admin()` and write the private audit trail.

The actor ID supplied to the database bridge is derived from the validated user token, never from browser JSON.

## Production Data Wiring

The deployed React application source now reads real API state for:
- Dashboard counts
- Bull list/search
- Bull Profile
- P1-007 statistics
- recent form
- Bull match history/opponents
- published Matches list
- Match Detail

Signed-in role is resolved from `/me` using `bullmatch.app_users`.

UI gates:
- Manual Entry: ACTIVE ADMIN
- Review shell: ACTIVE ADMIN or REVIEWER
- authenticated alone grants no BullMatch application role

Current Production records intentionally remain empty. The app therefore shows real zero/empty states rather than fabricated sample Bulls or Matches.

## Verification

### Database bridge
Rollback-only test passed:
- browser cannot invoke bridge RPC directly
- service role can invoke bridge
- membership lookup is server-owned
- ACTIVE ADMIN command succeeds
- REVIEWER mutation fails
- audit actor/entity linkage is preserved
- rollback leaves no fixture data

Test: `supabase/tests/app_003_api_bridge.sql`

### Production-network smoke test
GitHub Actions Web App run #23 passed:
- locked dependency install — PASS
- TypeScript/Vite production build — PASS
- Production Dashboard API — HTTP 200
- expected Dashboard keys — PASS
- `/me` without user token — HTTP 401

This proves the deployed Edge Function is reachable from external infrastructure and enforces the signed-out protected-route boundary.

### Advisors
Security: no WARN/ERROR introduced. Existing private-schema `RLS Enabled No Policy` INFO is intentional default deny.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

Performance: no actionable WARN introduced. Existing `unused_index` INFO is expected before real workload accumulates.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Frontend Deployment

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

APP-003 will deploy through the existing GitHub Pages workflow after merge to `main`.

## Next Gates

1. Merge/deploy **BMI-APP-003**
2. Bootstrap the first real Auth user and add that exact UUID to `bullmatch.app_users` as ACTIVE ADMIN
3. Add atomic operational forms for real data entry without partial multi-command writes
4. **BMI-P1-008 — Review Backend Foundation**
5. Phase 2 first permitted automated source connector

## Still Deferred

- first real production ADMIN activation
- AI provider selection
- first production source selection/compliance approval
