# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Frontend Foundation + Core Verified Database**

Overall status: **FIRST APP UI IN PROGRESS**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22
- BMI-P1-006 Manual Match Entry & Verification — DONE via PR #24

## Backend baseline

Shared Supabase host: **`aodxx's Project`**

BullMatch-owned schemas only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

Manual trusted workflow is available at the database/domain layer:

`Venue / Bulls -> Event -> Match -> Participants -> Result -> Verify -> Publish`

Historical participant snapshots, result synchronization, publication guards, ADMIN-only mutation rules and audit trail are tested against the real Supabase project.

Production Bulls/Matches remain intentionally empty; no fabricated data or fake ADMIN has been created.

## Current Work — BMI-APP-001

Status: **IN PROGRESS**
Tracking: Issue #25
Branch: `agent/bmi-app-001-frontend-foundation`

### Frontend stack

- React 19
- TypeScript
- Vite 8
- dependency-light CSS
- Node 24 in CI
- static/hash navigation compatible with GitHub Pages

### First screens implemented in the branch

- Dashboard
- Bulls list
- Bull Profile shell
- Matches list
- Match Detail shell
- Manual Match Entry shell
- Review Queue shell
- Profile / Settings shell

### UX direction

- Thai-first
- mobile-first
- desktop sidebar + mobile bottom navigation
- large readable typography and tap targets
- sports intelligence / statistics tone
- PWA-ready manifest/icon
- no fake production records
- explicit empty states until real data wiring exists

### Security boundary

The frontend currently contains **no Supabase secret and no data mutation wiring**.

Do not expose the existing `bullmatch` SECURITY DEFINER mutation functions directly through the Data API just to connect the UI. APP-003 must use a controlled API/server boundary or separately designed exposed surface.

## Build / deployment

`.github/workflows/web.yml`:
- installs pinned web dependencies
- typechecks
- builds the Vite production bundle
- prepares GitHub Pages deployment on `main`

Vite base path is `/BullMatch-Intelligence/`.

The first CI run was created before the CSS commit and correctly failed on the missing stylesheet. A current-head PR build is required before APP-001 can merge.

## Parallel-ready backend tasks

- BMI-P1-007 — Bull Profile & Basic Statistics
- BMI-P1-008 — Review Backend Foundation

These remain isolated so another contributor can take one without editing APP-001 files.

## Next after APP-001

1. BMI-APP-002 — Supabase Auth Login UI
2. Define secure API/read boundary
3. BMI-APP-003 — Wire real BullMatch data/actions
4. BMI-P1-007 — expose verified statistics through the chosen safe read boundary

## Deferred

- first production ADMIN activation (requires a real Auth account)
- AI provider selection
- first production source selection/compliance approval

None block completing the visible app foundation.
