# BMI-P1-008 — Verified Claim Promotion Verification

Status: **IMPLEMENTED / NARROW ALLOWLIST / ADMIN-ONLY**

Production migration:
`20260906214802_add_bullmatch_verified_claim_promotion`

Production Edge Function:
`bullmatch-api` version 9

## Purpose

Create the first controlled bridge from a reviewed `VERIFIED` atomic claim into existing canonical data without turning community submissions into direct CRUD.

This slice deliberately supports only low-risk descriptive fields on an already-existing, active, `VERIFIED` Bull.

## Promotion command

Edge POST operation:
`promote_verified_claim`

Payload contract:

```json
{
  "schema_version": "1.0.0",
  "command_id": "uuid",
  "review_case_id": "uuid",
  "claim_id": "uuid",
  "expected_case_status": "RESOLVED",
  "expected_case_version": 2
}
```

The linked Bull claim must use:

```json
{
  "canonical_subject_id": "bull-uuid"
}
```

in `claim.subject_ref`.

## First allowlist

Only these `bullmatch.bulls` fields may be promoted:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

Explicitly excluded:
- `canonical_name` / aliases / Bull identity
- owner/camp relationships
- lineage
- images/media
- status/lifecycle
- participants and opponents
- match result, duration, date, venue or event history
- merge/split

Those require their own domain-specific promotion semantics.

## Required gates

Promotion requires all of the following:
- ACTIVE `ADMIN`; REVIEWER verification alone cannot mutate canonical data
- review case is already `RESOLVED`
- optimistic `expected_case_version` matches current case version
- claim belongs to that review case
- claim status is `VERIFIED`
- claim `basis = EXPLICIT`
- claim `subject_type = BULL`
- target Bull exists, is not archived and is `VERIFIED`
- field is in the low-risk allowlist
- value is a nonblank JSON string within conservative length limits
- at least one `SUPPORTS` evidence link exists
- same claim has not already created provenance for that Bull/field

## Idempotency and concurrency

`command_id` reuses the global unique review-action command ledger.

A replay of the same command ID returns the original `PROMOTE_CLAIM` result without applying a second mutation or incrementing case version.

A different command with a stale case version is rejected with the existing stale-review concurrency boundary.

## Provenance / audit

Successful promotion is one database transaction and writes:
- canonical Bull field update
- review case version increment
- `review_actions.action = PROMOTE_CLAIM`
- one claim-level `fact_provenance` row
- provenance rows for linked SUPPORTS / CONTRADICTS evidence
- private audit event `REVIEW_PROMOTE_CLAIM`

Audit metadata records the claim, field, before/after value, supporting evidence count, review action and promotion policy identifier.

The claim remains `VERIFIED`; it is not deleted or rewritten after promotion.

## Security validation

Direct RPC ACL:
- anon EXECUTE: false
- authenticated EXECUTE: false
- service_role EXECUTE: true

RPC is `SECURITY DEFINER` with fixed empty `search_path` and independently requires ACTIVE ADMIN through the BullMatch app membership table.

The Edge route validates the real authenticated user and ACTIVE ADMIN membership before calling the service-only RPC. Service-role credentials remain server-side.

## Rollback-only Production validation

A temporary transaction created:
- one source/source-item/evidence chain
- one extraction run/candidate group
- one temporary VERIFIED Bull
- one allowed VERIFIED/EXPLICIT `home_province` claim
- one disallowed `canonical_name` claim
- one resolved review case linking both claims

Validation confirmed:
- `home_province` was promoted to `พัทลุง`
- case version advanced 2 -> 3
- exactly one `PROMOTE_CLAIM` review action existed
- exactly one promotion audit record existed
- claim-level + evidence-level provenance existed
- same command ID replayed idempotently without version change
- `canonical_name` promotion was rejected by the allowlist

The transaction was rolled back. Follow-up checks confirmed no test Bull, review case, or source remained.

## Advisor result

Supabase Security Advisor was rerun after DDL. No direct promotion-RPC browser exposure was reported.

Remaining advisor notices are pre-existing:
- INFO: RLS enabled with no browser policy on intentionally service-only `bullmatch_private` tables
- WARN: leaked-password protection disabled in Supabase Auth

## Boundary

`VERIFIED` claim still does not mean automatic publication. Promotion is an explicit, ADMIN-only, idempotent operation with a strict field policy and provenance.

This is not a general canonical update endpoint. New canonical subject types and high-risk fields must receive separate reviewed allowlists and domain rules.
