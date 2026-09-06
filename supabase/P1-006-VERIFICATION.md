# BMI-P1-006 Manual Match Workflow Verification

Date: 2026-09-06
Supabase host: `aodxx's Project`
Task: `BMI-P1-006`

## Applied migrations

- `20260906061040` — `add_bullmatch_admin_event_match_crud`
- `20260906062919` — `add_bullmatch_manual_participant_result_workflow`

## Implemented

### Event
- ADMIN create/update
- explicit verification transition
- soft archive
- event venue cannot be silently changed after active matches exist

### Match
- ADMIN create/update/archive
- event/venue consistency checks
- published matches must be unpublished before factual edits
- participant add/update/remove
- immutable-by-default historical snapshots separated from current Bull profile
- result set/update
- participant WIN/LOSS/DRAW/NO_RESULT/CANCELLED synchronization
- explicit match verification
- explicit publish/unpublish

## Historical integrity

A match participant stores match-time values independently of current Bull state:
- `display_name_snapshot`
- `camp_id_snapshot`
- `owner_id_snapshot`
- `weight_kg`
- `age_months_estimate`

Regression test changed a Bull canonical name after participant creation and confirmed the participant display snapshot remained unchanged.

## Publication guard

Publication now requires all of the following:
- match is `VERIFIED`
- at least two participants
- known result (not `UNKNOWN`)
- result has `verified_at`
- match status agrees with result type
- all participant result states agree with the match result

Winner integrity still requires the winning participant to belong to the same match.

## Security

- all state-changing commands independently use the existing ACTIVE ADMIN authorization boundary
- REVIEWER, VIEWER and non-members cannot mutate
- browser roles still have zero direct table write grants
- private audit data remains outside browser schema access
- no production ADMIN or fake Auth account was created

`bullmatch` remains unexposed as an intentional backend/domain schema decision. Before frontend wiring, do not expose these `SECURITY DEFINER` mutation functions directly through the Data API; use a controlled server/API boundary or a separately designed exposed surface.

## Remote integration test

`supabase/tests/p1_006_manual_match.sql` passed against the real shared Supabase project using rollback-only temporary fixtures.

Verified:
- full event -> match -> participants -> result -> verify -> publish path
- historical snapshot preservation
- WIN result synchronization
- DRAW result synchronization
- publish-before-verification rejection
- edit-while-published rejection
- participant edit invalidates prior verification
- cross-match winner rejection
- DRAW-with-winner rejection
- REVIEWER mutation rejection
- VIEWER mutation rejection
- non-member mutation rejection
- private audit events present in trusted context

After rollback:
- leaked test Auth users: 0
- leaked test memberships: 0
- production Bulls: 0
- production Matches: 0

## Advisors

Security:
- no WARN/ERROR findings introduced
- private-schema `RLS Enabled No Policy` INFO remains intentional because browser roles have no schema usage/grants

Performance:
- no new actionable WARN findings
- remaining `unused_index` INFO is expected on a new/empty database and should not be acted on until real workload statistics exist

## Gate unlocked

`BMI-P1-007 — Bull Profile & Basic Statistics` is now technically unblocked after P1-006 merge.

Frontend/App UI work can also begin because the core manual domain workflow is now complete enough to define real screens and actions.
