# BMI-P1-008 — Safe Review Metadata EDIT Verification

Task: `BMI-P1-008`
Policy: `BMI-P1-008-REVIEW-METADATA-EDIT-V1`
Production migration: `20260906225757_add_bullmatch_review_metadata_edit`
Production Edge Function: `bullmatch-api` v12
Status: **VERIFIED / DEPLOYED**

## Purpose

This slice defines the first supported `EDIT` semantics for the review system. It intentionally permits only review-case routing metadata changes that cannot alter canonical truth or bypass atomic-claim verification/promotion.

Editable fields:
- `priority`
- `summary`

Nothing else is accepted.

## Explicitly blocked

The EDIT RPC cannot modify:
- `subject_type` / `subject_ref`
- case type/status/assignment/resolution
- claim subject/value/basis/confidence/status
- evidence or evidence relationships
- entity-match candidates or duplicate candidates
- Bull canonical name/aliases/identity
- owner/camp affiliations
- lineage or media
- Match/Event/Venue history or results
- claim provenance or canonical promotion state

## Command contract

Requires:
- ACTIVE ADMIN or REVIEWER
- `schema_version = 1.0.0`
- globally unique `command_id`
- review case in `OPEN` or `IN_REVIEW`
- matching optimistic `expected_case_version`
- non-empty patch
- reviewer note

Priority is limited to `LOW`, `NORMAL`, `HIGH`, `URGENT`.
Summary must be a nonblank string of at most 500 characters.

A successful edit increments `case_version` exactly once, writes one `EDIT` review action with before/after routing metadata, and writes one `REVIEW_EDIT_METADATA` private audit event.

Same-command replay is idempotent and does not repeat the edit or increment version again.

## Security boundary

Direct Production RPC validation:
- `anon` EXECUTE: false
- `authenticated` EXECUTE: false
- `service_role` EXECUTE: true
- `SECURITY DEFINER`: true
- fixed empty `search_path`

Edge v12 exposes `operation = review_edit_metadata` only after real Auth validation and ACTIVE ADMIN/REVIEWER membership. The database repeats role enforcement independently.

## Rollback-only Production regression

`supabase/tests/p1_008_review_metadata_edit.sql` passed with transaction-scoped fixtures.

Verified:
- priority and summary update successfully
- `canonical_mutation = false`
- case version increments once
- same-command replay is idempotent
- replay does not increment case version
- attempted `subject_ref` edit is rejected as unsupported
- terminal/resolved review case edit is rejected
- exactly one `EDIT` review action is created
- exactly one `REVIEW_EDIT_METADATA` audit row is created
- Bull row count is unchanged by EDIT

Transaction rolled back; no test review cases were retained.

## Migration reconciliation

Supabase assigned migration version `20260906225757`. Repository migration filename was reconciled to that exact Production version.

## Advisors

Security Advisor was rerun after deployment. No new browser-executable review EDIT RPC exposure appeared.

Existing INFO findings for service-only `bullmatch_private` tables with RLS and no browser policies remain expected under the private-schema architecture. The existing Auth leaked-password-protection warning is unrelated to this slice.

## Product / legal boundary

This EDIT capability is workflow metadata management only. It introduces no odds, betting, wallet, stake, settlement, or payout functionality.

## Next BMI-P1-008 action

The backend safety slices required before UI wiring are now in place:
- review queue/detail/evidence
- claim decisions
- identity impact preview
- guarded claim promotion
- entity/duplicate decisions
- guarded Bull creation
- safe review metadata EDIT

The next non-blocked task is production **Review Queue UI wiring** to these existing safe APIs while preserving the real-bull sports-intelligence visual system and explicit evidence/trust states.
