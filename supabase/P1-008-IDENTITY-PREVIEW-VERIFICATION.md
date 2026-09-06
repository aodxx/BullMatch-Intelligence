# BMI-P1-008 — Bull Identity Impact Preview Verification

Status: **IMPLEMENTED / READ-ONLY / EXECUTION DISABLED**

Production migration:
`20260906212825_add_bullmatch_identity_impact_preview`

Production Edge Function:
`bullmatch-api` version 7

## Purpose

Provide deterministic impact information before any Bull identity merge/split decision. This implements the Entity Resolution Strategy requirement that merge/split must have a side-by-side impact preview and must never be authorized by name similarity alone.

## Review-case contract

A `MERGE_SPLIT` review case uses `subject_ref`:

```json
{
  "entity_type": "BULL",
  "operation": "MERGE",
  "source_entity_ids": ["uuid", "uuid"],
  "target_entity_ids": ["surviving-uuid"]
}
```

For `SPLIT`, exactly one source Bull is required. Target IDs are optional at this preview stage because a later assignment plan may create/select resulting canonical identities.

## Preview output

The service-only preview returns:
- source/target canonical Bull summaries
- current verified statistics where available
- alias rows affected
- match participant rows affected
- distinct matches affected
- VERIFIED/PUBLISHED matches affected
- source-entity mappings affected
- fact-provenance rows affected
- prior identity-event count
- unverified/archived source counts
- deterministic `impact_preview_fingerprint`
- `execution_enabled: false`

## Hard conflict

For a proposed MERGE, if more than one source Bull ID occurs as different participants in the same match, the preview reports:

- `hard_conflict_match_count > 0`
- `merge_blocked_by_hard_conflict: true`

This is a strong identity contradiction. A high name similarity score cannot override it.

## Security

Direct function ACL check:
- anon EXECUTE: false
- authenticated EXECUTE: false
- service_role EXECUTE: true

The Edge route `IDENTITY_IMPACT_PREVIEW` first validates the user token and ACTIVE ADMIN/REVIEWER membership, then calls the service-only RPC.

## Rollback-only Production validation

A temporary transaction created two VERIFIED Bull fixtures, one Match where both Bulls were separate participants, and one MERGE_SPLIT review case. Validation confirmed:
- affected match count = 1
- hard conflict match count = 1
- merge blocked = true
- execution enabled = false
- fingerprint present

The transaction was rolled back. Follow-up checks confirmed:
- no test Bulls remained
- no test review case remained

## Advisor result

Supabase Security Advisor was rerun after the migration. No direct browser exposure for the preview RPC was reported. Existing private-schema RLS INFO notices and the pre-existing Auth leaked-password warning remain unchanged.

## Boundary

This slice does **not** perform MERGE or SPLIT, reassign match participants, change aliases, rewrite provenance, archive Bulls, or recompute statistics. Those operations remain blocked until a separately reviewed execution design consumes an unchanged preview fingerprint and explicit assignment/provenance plan.
