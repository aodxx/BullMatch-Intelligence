# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database + Frontend Foundation**

Overall status: **APP FOUNDATION DEPLOYED / READY FOR AUTH + DATA WIRING**

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

## Manual Workflow Available

Trusted ADMIN flow:

`Venue / Bulls -> Event -> Match -> Match Participants -> Match Result -> Verify -> Publish`

Historical participant snapshots preserve match-time display name, camp, owner, weight and estimated age independently of current Bull profile values.

Publication requires a VERIFIED match, at least two participants, a known verified result, consistent match status, and synchronized participant result states.

## Security Boundary

- browser roles have zero direct table write grants
- all state-changing commands enforce ACTIVE ADMIN membership
- REVIEWER / VIEWER / non-member mutation attempts fail
- private audit data remains inaccessible to browser roles
- no fake production ADMIN or production bull/match data has been created
- frontend contains no service-role secret
- BullMatch mutation functions are not wired directly to the browser

## Frontend

Stack:
- React 19
- TypeScript
- Vite 8
- mobile-first / Thai-first
- responsive desktop sidebar + mobile bottom navigation
- PWA manifest and app icon

Screens:
- Dashboard
- Bulls
- Bull Profile
- Matches
- Match Detail
- Manual Entry
- Review Queue
- Settings/Profile

Real-data surfaces intentionally show empty states until secure data wiring is implemented.

## Deployment

GitHub Pages deployment is ACTIVE.

Production URL:
`https://aodxx.github.io/BullMatch-Intelligence/`

Verified on GitHub Actions run #10 attempt 2:
- locked dependency install — PASS
- TypeScript — PASS
- Vite production build — PASS
- Configure Pages — PASS
- Upload Pages artifact — PASS
- Deploy GitHub Pages — PASS

## Next Gates

1. **BMI-P1-007 — Bull Profile & Basic Statistics**
2. **BMI-APP-002 — Supabase Auth Login UI**
3. **BMI-APP-003 — Secure Domain Data & Admin Action Wiring**

The next frontend integration must preserve the existing API/security boundary and must not expose privileged `bullmatch` mutation functions directly.

## Still Deferred

- actual first production ADMIN activation using a real Auth account
- AI provider selection
- first production source selection/compliance approval

These no longer block opening and reviewing the deployed frontend shell.
