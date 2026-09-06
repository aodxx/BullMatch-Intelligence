# BMI-P1-013 — Community Contribution Intake V1

Status: **IMPLEMENTATION CONTRACT / FIRST SLICE SELECTED**
Policy ID: `BMI-P1-013-BULL-CORRECTION-V1`
Depends on: Database Schema v0.2, Contribution & Trust Architecture, BMI-P1-008 Review Foundation

## 1. First production contribution

The first contribution flow is deliberately narrow:

**Propose one correction/observation for an existing VERIFIED Bull profile, backed by a public HTTP(S) source reference.**

Examples:
- home province
- home district
- color description
- breed description

This is the safest useful first path because it exercises the complete community network loop without creating new Bull identities or requiring file-storage moderation in the same increment.

`Authenticated contributor -> Community submission -> Public-reference evidence -> Atomic claim -> Review case -> Human verification -> Separate policy-controlled canonical promotion`

## 2. Non-negotiable boundary

A contributor can never write directly to:
- `bullmatch.bulls`
- Bull aliases or identity links
- owner/camp affiliations
- lineage/media
- matches/events/results/history
- review decisions
- fact provenance

Submission acceptance does not mean the fact is true. Review `APPROVE` verifies an atomic claim only. Canonical promotion remains the separate ADMIN policy already established by BMI-P1-008.

## 3. Authentication and contributor identity

V1 requires a real Supabase Auth session.

Server rules:
- derive `submitter_user_id` from the validated access token
- never trust a user ID supplied in the request body
- contributor participation does not require `bullmatch.app_users` membership
- `app_users` remains privileged ADMIN/REVIEWER/VIEWER authorization only
- on first successful contribution, create a private `bullmatch.contributor_profiles` row if absent
- default contributor profile visibility is `PRIVATE`
- `SUSPENDED`, `BANNED`, or `LEFT` contributors cannot submit

Public signup policy remains a separate product/auth decision; this contract does not enable anonymous canonical writes.

## 4. V1 request contract

Operation: `submit_bull_profile_correction`

Request payload:

```json
{
  "schema_version": "1.0.0",
  "client_submission_key": "client-generated-stable-key",
  "bull_id": "canonical-bull-uuid",
  "field_key": "home_province",
  "proposed_value": "พัทลุง",
  "source_url": "https://example.org/reference",
  "note": "ข้อมูลจากประกาศ/เพจต้นทาง"
}
```

Required:
- `schema_version = 1.0.0`
- nonblank `client_submission_key`, max 120 chars
- `bull_id` references a VERIFIED, nonarchived Bull
- `field_key` in the V1 allowlist
- nonblank `proposed_value`, max 500 chars
- `source_url` is HTTP(S), max 2048 chars
- optional note max 1000 chars

V1 field allowlist:
- `home_province`
- `home_district`
- `color_description`
- `breed_description`

These match the first guarded canonical promotion policy from BMI-P1-008. This alignment prevents V1 from collecting facts that the current verified-data pipeline has no safe promotion semantics for.

Explicitly not accepted in V1:
- canonical name / alias
- Bull identity merge/split
- owner / camp relationship
- lineage
- media upload
- match result/history
- comparison/pairing/program facts
- financial/stake/betting information

## 5. Idempotency

`client_submission_key` is unique per authenticated contributor.

Retry of the same key:
- returns the same submission ID
- does not create another evidence row, claim, or review case
- does not increment review-case version

A reused key with materially different payload must be rejected as an idempotency conflict rather than silently reinterpreted.

The submission stores a deterministic request fingerprint for this check.

## 6. Community submission row

Create `bullmatch_private.community_submissions` according to Schema v0.2.

For this V1 route:
- `submission_type = 'CORRECTION'`
- initial successful status = `REVIEW_REQUIRED`
- `target_hint` contains only the canonical Bull ID and field key needed for routing; it is not canonical truth
- `source_url` stores the contributor-supplied public reference
- `dedupe_fingerprint` is a deterministic hash of normalized target/field/value/source reference
- raw secrets/tokens are never stored

## 7. Evidence row

V1 uses reference-only evidence so no object-storage upload is required yet.

Create one evidence row:
- `submission_id = community_submissions.id`
- `submitted_by_user_id = authenticated user`
- `source_item_id = null`
- `evidence_type = 'URL_REFERENCE'`
- `storage_ref = source_url`
- `access_class = 'PUBLIC_REFERENCE'`
- `moderation_status = 'PENDING'`
- metadata records the route/policy version only

The system does not scrape or claim ownership of the target URL in this slice.

`evidence.source_item_id` must become nullable and evidence origin must require at least one of `source_item_id` or `submission_id`.

## 8. Atomic claim row

Create exactly one claim:
- `submission_id = community_submissions.id`
- `created_by_user_id = authenticated user`
- `extraction_run_id = null`
- `origin_type = 'COMMUNITY_SUBMISSION'`
- `subject_type = 'BULL'`
- `subject_ref = {"bull_id":"..."}`
- `canonical_subject_id = bull_id`
- `field_key = allowlisted field`
- `value_json = {"value":"..."}`
- `basis = 'EXPLICIT'`
- `status = 'REVIEW_REQUIRED'`
- `confidence = null`
- deterministic `value_fingerprint`

No AI confidence is invented.

Link the evidence with `claim_evidence.relationship = 'SUPPORTS'`.

## 9. Review routing

Create one `bullmatch.review_cases` row for the submission/claim using an existing compatible case type after verifying the deployed constraint values.

Requirements:
- OPEN review case
- normal default priority unless a later risk router escalates it
- subject type/ref identify the claim/submission/Bull without changing canonical truth
- context records policy ID, submission ID and `risk_tier = 'STANDARD_CORRECTION'`
- link through `bullmatch_private.review_case_claims`
- claim `review_case_id` may also point to the case after the v0.2 column is added

Do not auto-approve based on contributor reputation or source URL.

## 10. Contributor self-service read

V1 must eventually expose a server-mediated `MY_SUBMISSIONS` projection containing only the authenticated contributor's rows:
- submission ID/type/status/timestamps
- Bull ID + safe public Bull name if resolvable
- field key + proposed value
- safe high-level review outcome

Do not expose:
- private reviewer identity unless policy explicitly allows it
- private review notes/audit logs
- other contributors' submissions
- restricted/internal evidence
- abuse/moderation metadata

## 11. Database migration slice

The first implementation migration should be additive and cover only what this route requires:

1. create `bullmatch_private.community_submissions`
2. create `bullmatch.contributor_profiles`
3. generalize `evidence` origin for community evidence
4. generalize `claims` origin for manual/community claims
5. leave extraction-run generalization for the AI/photo extraction slice unless a shared constraint migration is cleaner and fully tested now
6. add indexes needed by idempotency, contributor history, review routing and dedupe lookup
7. enable RLS/default-deny on new tables
8. revoke browser access and grant service-role access only; contributor operations remain Edge/server-mediated
9. preserve all existing source-origin evidence/claim rows through explicit backfill before validating new constraints

No existing evidence/claim IDs are rewritten or deleted.

## 12. Security rules

- browser roles do not directly read/write `bullmatch_private.community_submissions`, `evidence`, `claims`, `review_case_claims`, or private audit tables
- browser roles do not directly mutate `bullmatch.contributor_profiles`; V1 uses server-mediated self registration/update
- any public-schema `SECURITY DEFINER` bridge function is revoked from `PUBLIC`, `anon`, and `authenticated`, with execute granted only to `service_role`
- Edge Function validates Auth token before calling contribution RPCs
- database command receives the actor ID from the trusted Edge layer and rechecks contributor status
- no service-role key is sent to the browser
- request body cannot select reviewer/admin role or contributor identity

## 13. Abuse / duplicate baseline

V1 minimum safeguards:
- idempotency key
- deterministic request/dedupe fingerprint
- existing VERIFIED Bull target required
- field allowlist
- payload length limits
- URL protocol validation
- contributor account status check
- no self-approval path

Rate limits and coordinated-manipulation scoring can evolve after real traffic, but the schema should retain timestamps and policy metadata needed for that work.

## 14. Validation before launch

Required rollback-only tests:
- existing source-origin evidence still valid
- existing extraction-origin claims still valid
- first community correction creates one submission/evidence/claim/review case
- same idempotency key replay creates no duplicate rows
- same key with changed payload is rejected
- non-VERIFIED/archived Bull target rejected
- unsupported field rejected
- blank/oversize value rejected
- non-HTTP(S) source rejected
- contributor user ID cannot be forged via payload
- suspended/banned contributor rejected
- claim starts REVIEW_REQUIRED and cannot be contributor-promoted
- canonical Bull row is unchanged after submission
- anon/authenticated cannot directly access private contribution tables/RPCs
- service-role controlled route works
- rollback leaves no fixture rows
- current web build and Production public API smoke remain green
- Supabase security advisor adds no unintended browser-executable privileged function

## 15. Definition of done for the first P1-013 increment

The first increment is done when Production supports an authenticated contributor submitting an evidence-backed correction to an existing verified Bull through a controlled server route, the submission becomes a REVIEW_REQUIRED atomic claim visible to the reviewer workflow, the contributor can safely read their own submission state, and no canonical Bull field changes until the existing separate verification/promotion process is used.

## 16. Exact next implementation action

Implement the additive community-origin migration and rollback-only regression first. Do not expose the Edge submission operation until origin constraints, ACLs, idempotency and canonical-no-change tests pass.
