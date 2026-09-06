# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 1 — Core Verified Database**

Overall status: **MANUAL MATCH WORKFLOW APPLIED / REVIEW READY**

## Completed Gates

- Phase 0 Foundation & Architecture — COMPLETE
- BMI-P1-001 Shared Supabase Bootstrap — DONE via PR #16
- BMI-P1-002 Core Database — DONE via PR #18
- BMI-P1-004 Authorization Foundation — DONE via PR #20
- BMI-P1-005 Controlled Domain CRUD — DONE via PR #22

Selected shared Supabase host:

**`aodxx's Project`**

BullMatch owns only:
- `bullmatch`
- `bullmatch_private`

`freshmart` remains outside BullMatch scope.

## Current Work — BMI-P1-006

Status: **REVIEW**
Tracking: Issue #23
Branch: `agent/bmi-p1-006-manual-match`

### Applied migrations

- `20260906061040` — Event/Match controlled CRUD
- `20260906062919` — Participant/Result/Verification/Publication workflow

## Manual Workflow Now Available

Trusted ADMIN flow:

`Venue / Bulls -> Event -> Match -> Match Participants -> Match Result -> Verify -> Publish`

### Historical snapshots

Each participant stores match-time values independently of the Bull's current profile:
- display name
- camp
- owner
- weight
- estimated age

Changing a Bull's current canonical name does not rewrite past participant display snapshots.

### Result synchronization

A match result deterministically updates participant states:
- WIN -> winner WIN, others LOSS
- DRAW -> all DRAW
- NO_RESULT -> all NO_RESULT
- CANCELLED -> all CANCELLED

Result type also synchronizes the match status.

### Verification and publication

Publication requires:
- VERIFIED match
- at least two participants
- known result
- verified result timestamp
- status/result consistency
- participant result consistency

Published factual records must be unpublished before participant/result/match fact edits.

Editing participant facts after verification invalidates the previous verification and clears result verification.

## Security boundary

- browser roles still have zero direct table write grants
- every mutation uses the ACTIVE ADMIN boundary
- REVIEWER / VIEWER / non-member mutation attempts fail
- private audit data remains inaccessible to browser roles
- no fake ADMIN or production data was created

Important frontend rule:

**Do not expose `bullmatch` mutation functions directly through the Data API.** Current Supabase guidance recommends carefully restricting `SECURITY DEFINER` functions. Frontend work must use a controlled API/server boundary or another explicitly designed exposed surface.

## Verification

`supabase/tests/p1_006_manual_match.sql` passed against the real shared Supabase project using rollback-only fixtures.

Verified:
- full manual event/match workflow
- historical snapshot preservation
- WIN/DRAW synchronization
- publish-before-verify rejection
- published-edit rejection
- verification invalidation after edits
- cross-match winner rejection
- invalid non-WIN winner rejection
- REVIEWER/VIEWER/non-member denial
- private audit events

After rollback:
- leaked test Auth users: 0
- leaked test memberships: 0
- production Bulls: 0
- production Matches: 0

Verification artifact:
- `supabase/P1-006-VERIFICATION.md`

## Advisors

### Security

No WARN/ERROR findings introduced.

Remaining `RLS Enabled No Policy` INFO items are confined to `bullmatch_private`, which intentionally has no browser usage/grants.

### Performance

No actionable WARN findings introduced.

Remaining `unused_index` INFO is expected while the production dataset is empty.

## Next Gates

After P1-006 merge, two high-value tracks become available:

1. **BMI-APP-001 — Frontend Foundation & First Screens**
2. **BMI-P1-007 — Bull Profile & Basic Statistics**

Priority: start **BMI-APP-001** first so the project becomes visibly usable, while keeping the statistics work isolated for parallel contribution if another team joins.

## Frontend Direction

Initial frontend should be:
- mobile-first
- Thai-first
- installable/PWA-ready
- free-tier friendly
- GitHub-hosted source
- clear separation between public statistics and Admin/Review operations

First screens:
- Dashboard
- Bulls
- Bull Profile
- Matches
- Match Detail
- Manual Entry
- Review Queue
- Settings/Profile

## Still Deferred

- actual first production ADMIN activation (requires a real Auth account)
- final production hosting choice
- AI provider selection
- first production source selection/compliance approval

These do not block frontend foundation work.
