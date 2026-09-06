# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database + Frontend Integration**

Overall status: **PRODUCTION API ACTIVE / FIRST REAL ADMIN ACTIVE**

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
- BMI-APP-003 Controlled API + Production Data Wiring — DONE via PR #33
- BMI-OPS-002 First Production ADMIN Bootstrap — DONE

Selected shared Supabase host: **`aodxx's Project`** (`kaanguobjhlusjvgbowt`)

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Production API Boundary

Applied migration:
`20260906092707_add_bullmatch_controlled_api_bridge`

Deployed Edge Function:
- `bullmatch-api`
- version 1
- status ACTIVE

Flow:

`GitHub Pages React app → bullmatch-api Edge Function → service-only public RPC bridge → bullmatch/bullmatch_private domain`

The browser never receives a service-role key and cannot execute the three bridge RPCs directly. `PUBLIC`, `anon`, and `authenticated` have no EXECUTE permission on them; only `service_role` does.

Public API returns verified/published data only. Protected requests validate the Supabase Auth user before resolving BullMatch membership or accepting commands.

ADMIN mutations remain protected twice:
1. Edge Function requires ACTIVE ADMIN membership.
2. Existing BullMatch domain functions independently enforce `require_admin()` and write the private audit trail.

## Production Web App

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

Live data surfaces:
- Dashboard counts
- Bull list/search
- Bull Profile
- W/L/D statistics and win rate
- recent form
- Bull match history/opponents
- published Matches list
- Match Detail

Signed-in role comes from `/me` using `bullmatch.app_users`.

UI authorization:
- Manual Entry: ACTIVE ADMIN
- Review shell: ACTIVE ADMIN or REVIEWER
- authenticated alone grants no BullMatch application role

Current Production Bull/Match records intentionally remain empty. Visible zero/empty states are real Production state, not fabricated sample data.

## First Production ADMIN

The first intended real Supabase Auth account has now been bootstrapped as BullMatch `ADMIN / ACTIVE`.

Verified:
- Auth identity exists in project `kaanguobjhlusjvgbowt`
- email is confirmed
- exact Auth UUID is linked to `bullmatch.app_users`
- `bullmatch_api_member` reports `member=true`, `role=ADMIN`, `status=ACTIVE`, `active=true`
- an authenticated database role check reports ADMIN authorized

For privacy and security, the public repository does not contain the owner's email, password, tokens, or Auth UUID.

Runbook: `docs/FIRST-ADMIN-BOOTSTRAP.md`

## Verification

PR #33 passed its Web App CI on the merged head.

Main GitHub Actions run #26 passed:
- locked dependency install — PASS
- TypeScript/Vite production build — PASS
- Production Dashboard API smoke test — PASS (HTTP 200)
- `/me` without user token — PASS (HTTP 401)
- Configure Pages — PASS
- Upload Pages artifact — PASS
- Deploy GitHub Pages — PASS

Database rollback tests also proved:
- browser roles cannot invoke service bridge RPCs
- ACTIVE ADMIN command succeeds
- REVIEWER mutation is rejected
- audit actor/entity linkage survives the bridge
- no test fixtures remain

Security Advisor: no WARN/ERROR introduced. Existing private-schema `RLS Enabled No Policy` INFO is intentional default deny.
Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

Performance Advisor: no actionable WARN introduced. Existing `unused_index` INFO is expected before real workload accumulates.
Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Next Engineering Gates

1. Verify owner sign-in shows `ADMIN / ACTIVE` in the production app
2. Atomic operational form/command for real match entry without partial writes
3. **BMI-P1-008 — Review Backend Foundation**
4. Phase 2 first permitted automated source connector

## Still Deferred

- AI provider selection
- first production source selection/compliance approval
