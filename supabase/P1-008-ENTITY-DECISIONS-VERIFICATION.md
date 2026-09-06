# BMI-P1-008 — Reviewed Entity Decisions Verification

Task: `BMI-P1-008`
Slice: `LINK_ENTITY` / `CONFIRM_DUPLICATE` / `MARK_NOT_DUPLICATE`
Production migration: `20260906215917_add_bullmatch_reviewed_entity_decisions`
Production Edge Function: `bullmatch-api` v10
Status: **VERIFIED IN PRODUCTION BOUNDARY**

## Purpose

This slice resolves entity-match and duplicate candidates inside the review workflow without creating, merging, archiving, publishing, or rewriting canonical BullMatch entities/history.

It preserves the core rule:

`community/source evidence -> atomic claims/candidates -> review decision -> separately controlled canonical promotion`

A reviewed candidate decision is metadata about resolution. It is not a canonical-history write.

## Implemented semantics

### LINK_ENTITY

- requires ACTIVE `ADMIN` or `REVIEWER`
- candidate must belong to the supplied review case
- target canonical entity must exist, be `VERIFIED`, and not archived
- supports Bull, Owner, Camp, Venue and Event candidate types
- Bull links require an explicit reviewed identity basis
- Bull `NAME_ONLY` identity basis is rejected
- candidate becomes `CONFIRMED_LINK`
- records the reviewed identity basis and review timestamp in candidate signals
- does not mutate the canonical target entity

Allowed reviewed Bull identity-basis labels in this first slice:
- `VISUAL_IDENTITY`
- `OWNER_CAMP_CONTEXT`
- `EXTERNAL_IDENTIFIER`
- `MATCH_HISTORY_CONTEXT`
- `OFFICIAL_RECORD`
- `MULTI_SIGNAL`

These labels are reviewer-decision context, not automated proof. Name similarity alone remains insufficient.

### CONFIRM_DUPLICATE

- requires a duplicate candidate attached to the review case
- requires reviewer note
- sets candidate status to `CONFIRMED_DUPLICATE`
- does not merge, archive, or reassign canonical records

### MARK_NOT_DUPLICATE

- requires a duplicate candidate attached to the review case
- requires reviewer note
- sets candidate status to `NOT_DUPLICATE`
- does not create or rewrite canonical records

## Concurrency / idempotency

All three operations use the existing review command contract:
- `schema_version = 1.0.0`
- globally unique `command_id`
- expected review-case status
- expected `case_version`
- row lock on the review case

A successful decision increments `case_version` exactly once.

Replaying the same `command_id` returns the prior review action and does not increment the case version or repeat candidate mutation.

A stale expected status/version is rejected by the review concurrency boundary.

## Audit trail

Every non-replayed successful decision writes:
- one append-only `bullmatch.review_actions` row
- one `bullmatch_private.audit_log` row
- before/after candidate snapshots in the review action
- command correlation ID
- review-case version transition

The returned result explicitly reports `canonical_mutation: false`.

## Security boundary

Production ACL regression passed:
- `anon` direct RPC execute: **DENIED**
- `authenticated` direct RPC execute: **DENIED**
- `service_role` direct RPC execute: **ALLOWED**

The function is `SECURITY DEFINER` with fixed empty `search_path` and independently calls the database review-role gate.

Production Edge Function v10 exposes `operation = review_entity_decision` only after validating the authenticated user and ACTIVE `ADMIN`/`REVIEWER` membership. Service-role credentials remain server-side.

## Rollback-only Production regression

Executed `supabase/tests/p1_008_reviewed_entity_decisions.sql` against the production database boundary using transaction-scoped fixtures.

Passed assertions:
- service-only RPC ACL
- Bull `LINK_ENTITY` -> `CONFIRMED_LINK`
- `CONFIRM_DUPLICATE` -> `CONFIRMED_DUPLICATE`
- `MARK_NOT_DUPLICATE` -> `NOT_DUPLICATE`
- same-command replay is idempotent
- replay does not increment case version
- Bull `NAME_ONLY` identity basis is blocked
- canonical Bull name remains unchanged
- exactly three review actions produced
- exactly three corresponding private audit rows produced

The transaction was rolled back. No test Bull, candidate, duplicate candidate, review case, or review action was intentionally retained.

## Advisors

Supabase Security Advisor was rerun after the deployed migration.

No new direct browser-executable entity-decision RPC warning was reported. Existing INFO findings for RLS-enabled service-only `bullmatch_private` tables without browser policies remain expected under the current private-schema boundary.

A pre-existing project-level warning remains: leaked-password protection is disabled in Supabase Auth. This is unrelated to this migration and should be handled as a separate auth-hardening task rather than changing review semantics.

Performance Advisor reports unused-index INFO findings on the current empty/nearly-empty production dataset. No index was removed merely to silence low-signal early-stage usage statistics.

## Canonical truth boundary

This slice does **not**:
- create a new Bull/Owner/Camp/Venue/Event
- merge or split Bull identities
- reassign match participants
- change Bull canonical name or aliases
- overwrite owner/camp relationships
- update match result/history
- publish claims
- promote claims into canonical data
- infer Bull identity from name similarity alone

## Next BMI-P1-008 slice

Design and implement guarded `CREATE_ENTITY` semantics only after mandatory candidate/duplicate checks. A new Bull identity must not be created merely because a submitted name differs or because candidate matching is uncertain.

After guarded entity creation:
1. selected `EDIT` semantics that cannot bypass verified-claim promotion
2. production Review Queue UI wiring
3. destructive merge/split remains separately deferred until an explicit fingerprint-bound reassignment/provenance design is reviewed.
