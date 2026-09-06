# BMI-APP-003 Verification

Date: 2026-09-06

## Applied database migration

- `20260906092707_add_bullmatch_controlled_api_bridge`

The migration creates three `public` RPC bridge functions solely so the Supabase Edge Function can call them through PostgREST:

- `bullmatch_api_public_query`
- `bullmatch_api_member`
- `bullmatch_api_admin_command`

`PUBLIC`, `anon`, and `authenticated` have no EXECUTE privilege on these functions. `service_role` is the only API role granted EXECUTE.

## Edge Function

- name: `bullmatch-api`
- deployed version: 1
- status: ACTIVE
- JWT gateway verification: disabled intentionally because signed-out public reads are required
- protected routes perform custom Auth token validation against `/auth/v1/user`
- service role exists only in the Edge runtime environment

Public resources are limited to verified/published read models:

- DASHBOARD
- BULLS
- BULL
- MATCHES
- MATCH
- VENUES

`ME` requires a valid user access token. POST commands require a valid user token and ACTIVE ADMIN membership; the database domain functions independently re-check ADMIN membership and preserve the audit trail.

## Database regression test

Rollback-only fixtures proved:

- browser roles cannot directly execute bridge RPCs
- service role can execute bridge RPCs
- member lookup returns server-owned role/status
- ADMIN command succeeds for ACTIVE ADMIN
- REVIEWER admin command is rejected
- audit actor/entity information survives the bridge
- rollback leaves no fixtures

Test: `supabase/tests/app_003_api_bridge.sql`

## Production network smoke test

GitHub Actions Web App run #23 passed:

- locked dependency install: PASS
- TypeScript + Vite build: PASS
- production `bullmatch-api?resource=dashboard`: HTTP 200
- dashboard response contains bulls/published_matches/venues/last_published_at
- production `bullmatch-api?resource=me` without user token: HTTP 401

This test runs from GitHub-hosted infrastructure, so it verifies the deployed public network path rather than only database-local behavior.

## Web wiring

The React app now reads real production API state for:

- Dashboard
- Bulls/search
- Bull Profile/statistics/recent form/history
- Matches
- Match Detail

Signed-in role is resolved through `/me`; the client never infers BullMatch role from user metadata. Manual Entry requires ACTIVE ADMIN, while Review Queue requires ACTIVE ADMIN or REVIEWER. Review operations themselves remain deferred to BMI-P1-008.

Current production data intentionally remains empty until real records are entered; no seed/fake Bull or Match data was created.

## Advisors

Security Advisor: no WARN/ERROR introduced. Existing `RLS Enabled No Policy` INFO in `bullmatch_private` is intentional default-deny behavior.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

Performance Advisor: no actionable WARN introduced. `unused_index` INFO is expected before real workload accumulates.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index
