# BMI-P1-002 Verification — Core Database

Date: 2026-09-06
Supabase host: `aodxx's Project`
Project ref: `kaanguobjhlusjvgbowt`

## Applied migration versions

- `20260906053239` — `create_bullmatch_canonical_entities`
- `20260906053302` — `create_bullmatch_matches_and_results`
- `20260906053321` — `create_bullmatch_review_workflow`
- `20260906053347` — `create_bullmatch_private_ingestion`
- `20260906053422` — `create_bullmatch_private_ai_and_provenance`
- `20260906053503` — `harden_bullmatch_publication_and_defaults`
- `20260906053620` — `add_bullmatch_missing_fk_indexes`

Bootstrap dependency:
- `20260906052726` — `bootstrap_bullmatch_shared_tenancy`

## Resulting table inventory

- `bullmatch`: 15 tables
- `bullmatch_private`: 17 tables

Core application tables include:
- app_users
- owners / owner_aliases
- camps / camp_aliases
- bulls / bull_aliases
- venues / venue_aliases
- events
- matches / match_participants / match_results
- review_cases / review_actions

Private subsystem includes:
- owner_private_details
- sources / source_runtime_state / source_items / evidence
- agent_runs / extraction_runs
- candidate_groups / claims / claim_evidence
- entity_match_candidates / entity_source_mappings
- duplicate_candidates / verification_results
- fact_provenance / identity_events / audit_log

## Integrity verification executed against Supabase

PASS:
- all BullMatch tables have RLS enabled
- browser roles have no table grants in `bullmatch_private`
- browser roles have no BullMatch domain grants other than authenticated own-membership SELECT on `app_users`
- canonical bull default verification state is `UNVERIFIED`
- `review_cases.case_version` exists for optimistic concurrency
- `review_actions.command_id` is unique for idempotency
- winner participant from another match is rejected by database trigger
- valid same-match winner is accepted
- unverified match publication is rejected
- verified match with >=2 participants and a result can be published
- duplicate `(source_id, dedupe_key)` source item is rejected
- integration test rows were deleted after verification

Key production rows after verification:
- bulls: 0
- matches: 0
- sources: 0
- review_cases: 0

## Security Advisor

No ERROR/WARN findings were observed.

INFO findings: `RLS Enabled No Policy` on newly created tables. This is intentional at this stage:
- browser grants are withheld from domain tables
- `bullmatch_private` has no `anon`/`authenticated` schema usage
- RLS therefore operates as an additional default-deny layer
- application-specific viewer/reviewer policies are deferred to BMI-P1-004 / relevant API tasks

Do not add permissive placeholder policies merely to silence this INFO lint.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

## Performance Advisor

The actionable `unindexed_foreign_keys` findings were fixed by migration `20260906053620`.

Remaining INFO findings are `unused_index`, expected because the database is new and intentionally has no production data/query workload yet. Do not remove planned lookup/FK/search indexes based on zero-use statistics before real workload exists.

Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

## Shared-project isolation

- BullMatch objects remain inside `bullmatch` and `bullmatch_private`
- unrelated `public` application table inventory was unchanged
- no change was made to `freshmart`
- no production Auth users were created
- no Edge Functions were added
- no Data API exposed-schema settings were changed

## Next gate

After this task merges:
- BMI-P1-003 can add only safe reference/seed data if needed
- BMI-P1-004 can implement BullMatch admin/reviewer auth/role operations and intentional RLS/API policies
- BMI-P1-005/BMI-P1-006 can then implement domain CRUD and verified manual match workflow
