# BMI-P1-008 — Guarded CREATE_ENTITY Verification

Task: `BMI-P1-008`
Policy: `BMI-P1-008-BULL-CREATE-V1`
Production migration: `20260906224832_add_bullmatch_guarded_review_create_entity`
Production Edge Function: `bullmatch-api` v11
Status: **VERIFIED / DEPLOYED**

## Purpose

This slice introduces the first controlled path for creating a new canonical Bull identity from reviewed candidate data. It is intentionally narrower than generic ADMIN CRUD.

A successful command creates only an **UNVERIFIED Bull identity row**. It does not verify, publish, enrich, or attach history to the Bull.

## Preconditions

`review_create_entity` is ADMIN-only and requires:

- `schema_version = 1.0.0`
- globally unique `command_id`
- review case status `OPEN` or `IN_REVIEW`
- optimistic `expected_case_version`
- review case type `NEW_ENTITY` or `ENTITY_MATCH`
- review-case subject `BULL`
- candidate attached to that review case
- candidate entity type `BULL`
- candidate decision `NEW_ENTITY_CANDIDATE`
- no existing `proposed_entity_id`
- `candidate_search_completed = true`
- `duplicate_search_completed = true`
- nonblank `search_policy_version`
- reviewer note
- strong reviewed creation basis

Allowed creation bases in V1:
- `VISUAL_IDENTITY`
- `EXTERNAL_IDENTIFIER`
- `OFFICIAL_RECORD`
- `MATCH_HISTORY_CONTEXT`
- `MULTI_SIGNAL`

`NAME_ONLY` is rejected.

## Duplicate / identity guards

Creation is blocked when:

- an active Bull already has the same normalized name
- the candidate group already has a confirmed Bull link
- a duplicate candidate in the group is `CANDIDATE`, `REVIEW_REQUIRED`, or `CONFIRMED_DUPLICATE`
- candidate/duplicate search completion was not recorded

The exact normalized-name rule is deliberately conservative in V1. Two legitimately distinct Bulls can share or normalize to the same name, so such cases require a future explicit distinct-identity escalation design rather than silently creating a second canonical animal.

## Created data boundary

The reviewed command reuses the existing audited ADMIN Bull creation primitive but passes only `canonical_name`.

The new Bull remains:
- `verification_status = UNVERIFIED`
- no current owner
- no current camp
- no lineage notes
- no primary image
- no color/breed description
- no match history or participant reassignment

Those facts require their own evidence-backed claims and promotion policies.

After successful creation, the reviewed candidate becomes `CONFIRMED_LINK` to the new Bull and records creation policy/basis context.

## Audit / concurrency

Successful creation atomically records:
- one Bull identity row
- candidate -> canonical Bull link
- one review-case version increment
- one `CREATE_ENTITY` review action with before/after candidate state
- one `REVIEW_CREATE_ENTITY` private audit event
- the existing `BULL_CREATED` domain audit from the canonical ADMIN primitive

Same-command replay is idempotent and returns the original Bull without another insert or version increment.

## Security

Direct Production RPC validation:
- `anon` EXECUTE: false
- `authenticated` EXECUTE: false
- `service_role` EXECUTE: true
- `SECURITY DEFINER`: true
- fixed empty `search_path`

Edge v11 exposes `operation = review_create_entity` only after real Auth validation and ACTIVE ADMIN membership. The database repeats the ADMIN requirement independently.

## Rollback-only Production regression

`supabase/tests/p1_008_guarded_create_entity.sql` passed against Production using transaction-scoped fixtures.

Verified:
- valid reviewed candidate creates one UNVERIFIED Bull
- identity-only creation does not write owner/camp/lineage/media/descriptive fields
- candidate links to the new Bull
- replay returns the same Bull idempotently
- replay does not increment case version
- exactly one `CREATE_ENTITY` review action
- exactly one `REVIEW_CREATE_ENTITY` audit row
- incomplete duplicate-search evidence blocks creation
- unresolved duplicate candidate blocks creation
- exact normalized-name collision blocks creation
- `NAME_ONLY` creation basis blocks creation

Transaction rolled back. Post-validation checks found zero rollback review cases and zero rollback Bulls.

## Migration reconciliation

Supabase assigned migration version `20260906224832`. Repository migration filename was reconciled to that exact Production version to avoid migration drift.

## Advisors

Security Advisor was rerun after DDL. No new direct browser-executable CREATE_ENTITY RPC warning appeared.

Existing INFO findings for RLS-enabled service-only `bullmatch_private` tables remain expected under the private-schema boundary. The existing project warning for leaked-password protection is unrelated to this slice.

## Canonical truth boundary

This command creates an identity container only. `UNVERIFIED` identity creation is not public verification and does not authorize canonical factual enrichment.

Community submissions, AI extraction, names, or matching scores alone cannot create a published/verified Bull.

## Next BMI-P1-008 slice

Define selected `EDIT` semantics only where they cannot bypass atomic-claim verification and policy-controlled canonical promotion. High-risk identity, lineage, affiliation, media, and match-history edits remain outside any generic edit command.

After selected EDIT semantics, wire the production Review Queue UI to existing safe read/command APIs. Destructive merge/split remains separately deferred.
