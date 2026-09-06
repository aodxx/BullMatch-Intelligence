# BMI-P1-007 Bull Profile & Basic Statistics Verification

Date: 2026-09-06
Supabase host: `aodxx's Project`
Task: `BMI-P1-007`
Migration: `20260906084340_add_bullmatch_verified_profile_statistics`

## Read models

- `bullmatch.published_bull_match_history`
- `bullmatch.published_bull_opponent_history`
- `bullmatch.bull_basic_stats`
- `bullmatch.bull_recent_form`

All views use `security_invoker = true` and are readable only by `service_role` at this stage. Browser roles (`anon`, `authenticated`) do not receive direct SELECT access.

## Inclusion rules

Authoritative history/statistics require:
- Match `verification_status = VERIFIED`
- `published_at IS NOT NULL`
- Match not archived
- Result has `verified_at`
- Known result type: WIN / DRAW / NO_RESULT / CANCELLED
- Participant result is synchronized and known
- Bull entity is VERIFIED and not archived

Unverified Event/Venue names are not surfaced through the history view; their labels remain null until verified.

## Win-rate rule

`win_rate_pct = wins / (wins + losses + draws) * 100`

- NO_RESULT excluded from denominator
- CANCELLED excluded from denominator
- null when denominator is zero

## Recent form

Latest five statistical results only:
- WIN
- LOSS
- DRAW

NO_RESULT/CANCELLED do not enter the recent-form array.

## Regression test

`supabase/tests/p1_007_bull_stats.sql` was executed against the real shared Supabase database using rollback-only fixtures.

Fixture expectation:
- Published matches: 5
- Statistical matches: 3
- Wins: 1
- Losses: 1
- Draws: 1
- No result: 1
- Cancelled: 1
- Win rate: 33.33%
- Recent form: LOSS, DRAW, WIN

Verified:
- unpublished verified-result match is excluded
- unverified Bull is excluded from profile/history
- opponent-normalized history is available for future H2H
- current canonical Bull rename does not rewrite `display_name_snapshot`
- anon/authenticated have no direct stats-view SELECT
- service_role can read stats views
- transaction rollback leaves no fixture data

## Advisors

Security:
- no WARN/ERROR introduced
- existing `RLS Enabled No Policy` INFO remains intentional in `bullmatch_private`
- reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

Performance:
- no actionable WARN introduced
- remaining `unused_index` INFO is expected before real workload statistics exist
- reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Gate unlocked

The verified statistics/read-model foundation is ready for a controlled application API. Do not expose these domain views directly through the browser Data API; APP-003 should access them through the approved API boundary.
