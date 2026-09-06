# Database Schema v0.1 — Final Phase 0 Contract

Status: **REVIEW READY**
Task: `BMI-P0-002`
Primary datastore: PostgreSQL / Supabase

This document is the migration-ready data contract for Phase 1. It intentionally separates authoritative sports data from untrusted source material and AI-generated candidates.

## 1. Design Principles

1. UUIDs are canonical identifiers; names are never foreign keys.
2. Historical match-time facts are immutable snapshots attached to the match.
3. Raw evidence, AI candidates, review state, and verified domain data are separate layers.
4. Every published historical fact must be traceable to evidence and/or an explicit human action.
5. Automated workers may create candidates and review cases but may not silently publish historical facts.
6. Entity merges/splits are auditable and reversible at the decision layer.
7. Source ingestion is idempotent.
8. Hard delete is not used for referenced historical records.
9. Workflow/status values use `text + check constraints` in v0.1 rather than PostgreSQL enums so states can evolve without enum migration friction.
10. Database constraints protect integrity; AI confidence is metadata, never an integrity rule.

## 2. Schema Boundaries

### `public`
Contains application-facing authoritative data and user/reviewer workflow records that may be reached through the Supabase Data API when explicitly granted and protected by RLS.

Initial tables:
- `app_users`
- `owners`
- `owner_aliases`
- `camps`
- `camp_aliases`
- `bulls`
- `bull_aliases`
- `venues`
- `venue_aliases`
- `events`
- `matches`
- `match_participants`
- `match_results`
- `review_cases`
- `review_actions`

### `private`
Contains ingestion, raw evidence metadata, AI output, provenance, operational history, and identity-audit records. This schema must not be exposed to public clients.

Initial tables:
- `sources`
- `source_items`
- `evidence`
- `agent_runs`
- `extraction_runs`
- `claims`
- `claim_evidence`
- `entity_match_candidates`
- `duplicate_candidates`
- `verification_results`
- `fact_provenance`
- `identity_events`
- `audit_log`

### Object storage
Binary evidence such as screenshots, uploaded images, PDFs, or derived artifacts should live in object storage/Google Drive as appropriate. Database rows store stable references, hashes, metadata, and access classification rather than large binary blobs.

## 3. Authentication and Roles

### `public.app_users`
Application identity/role record linked to Supabase Auth.

Fields:
- `id uuid primary key references auth.users(id) on delete cascade`
- `display_name text null`
- `role text not null check (role in ('ADMIN','REVIEWER','VIEWER'))`
- `status text not null default 'ACTIVE' check (status in ('ACTIVE','SUSPENDED'))`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Rules:
- Role changes are privileged operations.
- Do not use user-editable auth metadata for authorization.
- `VIEWER` has no write privileges to historical records.
- `REVIEWER` may act on review workflows but may not change system configuration/source credentials.
- `ADMIN` controls canonical data, source registry, and reviewer access.

## 4. Canonical Domain Tables

All canonical domain tables should use:
- `id uuid primary key default gen_random_uuid()`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `archived_at timestamptz null` where applicable
- `archive_reason text null` where applicable

### `public.owners`

Fields:
- `id uuid pk`
- `name text not null`
- `normalized_name text not null`
- `province text null`
- `district text null`
- `contact_private jsonb null`
- `notes text null`
- `verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED'))`
- lifecycle timestamps

Indexes:
- btree on `normalized_name`
- optional trigram index in Phase 1 for fuzzy matching

### `public.owner_aliases`

Fields:
- `id uuid pk`
- `owner_id uuid not null references public.owners(id)`
- `alias text not null`
- `normalized_alias text not null`
- `alias_type text null`
- `verified boolean not null default false`
- timestamps

Constraints/indexes:
- unique `(owner_id, normalized_alias)`
- index `normalized_alias`

### `public.camps`

Fields:
- `id uuid pk`
- `name text not null`
- `normalized_name text not null`
- `owner_id uuid null references public.owners(id)`
- `province text null`
- `district text null`
- `notes text null`
- `verification_status text not null default 'VERIFIED'`
- lifecycle timestamps

### `public.camp_aliases`
Same structural pattern as owner aliases, referencing `public.camps(id)`.

### `public.bulls`

Fields:
- `id uuid pk`
- `canonical_name text not null`
- `normalized_name text not null`
- `birth_date date null`
- `birth_date_precision text null check (birth_date_precision in ('DAY','MONTH','YEAR','ESTIMATED','UNKNOWN'))`
- `sex text not null default 'MALE' check (sex in ('MALE','UNKNOWN'))`
- `color_description text null`
- `breed_description text null`
- `lineage_notes text null`
- `current_camp_id uuid null references public.camps(id)`
- `current_owner_id uuid null references public.owners(id)`
- `home_province text null`
- `home_district text null`
- `status text not null default 'ACTIVE' check (status in ('ACTIVE','RESTING','RETIRED','DECEASED','UNKNOWN'))`
- `primary_image_ref text null`
- `notes text null`
- `verification_status text not null default 'VERIFIED'`
- lifecycle timestamps

Important rule: current camp/owner are convenience attributes only. Historical camp/owner at match time lives on `match_participants`.

### `public.bull_aliases`

Fields:
- `id uuid pk`
- `bull_id uuid not null references public.bulls(id)`
- `alias text not null`
- `normalized_alias text not null`
- `alias_type text null check (alias_type is null or alias_type in ('ALTERNATE_NAME','SPELLING','TITLE_PREFIX','SOURCE_LABEL','FORMER_NAME','OTHER'))`
- `verified boolean not null default false`
- `first_seen_at timestamptz null`
- timestamps

Constraints/indexes:
- unique `(bull_id, normalized_alias)`
- btree on `normalized_alias`
- optional trigram index on `normalized_alias` after `pg_trgm` is enabled without explicit extension version pinning

Do not make `normalized_alias` globally unique because different bulls can legitimately share the same display name.

### `public.venues`

Fields:
- `id uuid pk`
- `name text not null`
- `normalized_name text not null`
- `province text null`
- `district text null`
- `address text null`
- `latitude numeric(9,6) null check (latitude between -90 and 90)`
- `longitude numeric(9,6) null check (longitude between -180 and 180)`
- `status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE','UNKNOWN'))`
- `verification_status text not null default 'VERIFIED'`
- lifecycle timestamps

### `public.venue_aliases`
Same structural pattern as owner/camp aliases, referencing `public.venues(id)`.

### `public.events`

Fields:
- `id uuid pk`
- `venue_id uuid null references public.venues(id)`
- `name text null`
- `event_date date null`
- `start_time timestamptz null`
- `date_precision text not null default 'UNKNOWN' check (date_precision in ('EXACT','DATE_ONLY','MONTH_ONLY','YEAR_ONLY','ESTIMATED','UNKNOWN'))`
- `status text not null default 'SCHEDULED' check (status in ('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED','UNKNOWN'))`
- `notes text null`
- `verification_status text not null default 'VERIFIED'`
- lifecycle timestamps

Indexes:
- `(venue_id, event_date)`
- `event_date`

### `public.matches`

Fields:
- `id uuid pk`
- `event_id uuid null references public.events(id)`
- `venue_id uuid null references public.venues(id)`
- `match_date timestamptz null`
- `date_precision text not null default 'UNKNOWN' check (date_precision in ('EXACT','DATE_ONLY','ESTIMATED','UNKNOWN'))`
- `match_number integer null check (match_number is null or match_number > 0)`
- `status text not null default 'SCHEDULED' check (status in ('SCHEDULED','COMPLETED','CANCELLED','NO_RESULT','UNKNOWN'))`
- `duration_seconds integer null check (duration_seconds is null or duration_seconds >= 0)`
- `result_detail text null`
- `verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED'))`
- `published_at timestamptz null`
- lifecycle timestamps

Rules:
- `published_at` is not set until publishing policy is satisfied.
- venue may be duplicated from event intentionally to preserve convenient match-level historical attribution; application validation keeps it consistent when event is known.

Indexes:
- `match_date`
- `(venue_id, match_date)`
- `(event_id, match_number)`
- partial index on `published_at where published_at is not null`

### `public.match_participants`
Historical snapshot for one bull in one match.

Fields:
- `id uuid pk`
- `match_id uuid not null references public.matches(id)`
- `bull_id uuid not null references public.bulls(id)`
- `side text null check (side is null or side in ('A','B','OTHER'))`
- `camp_id_snapshot uuid null references public.camps(id)`
- `owner_id_snapshot uuid null references public.owners(id)`
- `weight_kg numeric(7,2) null check (weight_kg is null or weight_kg > 0)`
- `age_months_estimate integer null check (age_months_estimate is null or age_months_estimate >= 0)`
- `display_name_snapshot text not null`
- `participant_result text null check (participant_result is null or participant_result in ('WIN','LOSS','DRAW','NO_RESULT','CANCELLED','UNKNOWN'))`
- `notes text null`
- timestamps

Constraints/indexes:
- unique `(match_id, bull_id)`
- unique `(match_id, side)` where side in `A/B` can be enforced by partial unique index
- index `bull_id`
- index `(bull_id, match_id)`

Historical rule: snapshot values are not recomputed when current bull/camp/owner data later changes.

### `public.match_results`
Separating match result from `matches` avoids a cyclic winner FK.

Fields:
- `id uuid pk`
- `match_id uuid not null unique references public.matches(id)`
- `result_type text not null check (result_type in ('WIN','DRAW','NO_RESULT','CANCELLED','UNKNOWN'))`
- `winner_participant_id uuid null references public.match_participants(id)`
- `result_reason text null`
- `verified_at timestamptz null`
- timestamps

Integrity rules:
- `WIN` requires `winner_participant_id`.
- non-`WIN` results require `winner_participant_id is null`.
- a database trigger or validated domain function must ensure the winner participant belongs to the same `match_id`.

## 5. Source Registry and Ingestion (`private`)

### `private.sources`

Fields:
- `id uuid pk`
- `name text not null`
- `source_type text not null check (source_type in ('WEBSITE','RSS','SITEMAP','API','YOUTUBE','OPERATOR_UPLOAD','SEARCH_DISCOVERY','OTHER'))`
- `base_url text null`
- `connector_key text not null`
- `access_method text not null`
- `reliability_tier text not null default 'UNKNOWN' check (reliability_tier in ('OFFICIAL','HIGH','MEDIUM','LOW','UNKNOWN'))`
- `polling_enabled boolean not null default false`
- `poll_interval_minutes integer null check (poll_interval_minutes is null or poll_interval_minutes >= 60)`
- `policy_status text not null default 'REVIEW_REQUIRED' check (policy_status in ('APPROVED','REVIEW_REQUIRED','BLOCKED'))`
- `policy_notes text null`
- `status text not null default 'ACTIVE' check (status in ('ACTIVE','PAUSED','ERROR','RETIRED'))`
- `last_success_at timestamptz null`
- `last_error_at timestamptz null`
- timestamps

No connector credential is stored in this table. Secrets stay in platform secret stores.

### `private.source_items`
One normalized discovered post/page/video/feed item.

Fields:
- `id uuid pk`
- `source_id uuid not null references private.sources(id)`
- `external_id text null`
- `canonical_url text null`
- `dedupe_key text not null`
- `published_at timestamptz null`
- `retrieved_at timestamptz not null`
- `content_hash text null`
- `title text null`
- `normalized_text text null`
- `raw_metadata jsonb not null default '{}'::jsonb`
- `connector_name text not null`
- `connector_version text not null`
- `ingestion_status text not null default 'DISCOVERED' check (ingestion_status in ('DISCOVERED','EXTRACTED','REVIEW_REQUIRED','PROCESSED','FAILED','IGNORED'))`
- timestamps

Constraints/indexes:
- unique `(source_id, dedupe_key)` — canonical idempotency constraint
- partial unique `(source_id, external_id)` where `external_id is not null`
- index `(source_id, published_at desc)`
- index `content_hash`

`dedupe_key` is computed by the connector from the strongest stable source identity available; it must not depend only on AI output.

### `private.evidence`

Fields:
- `id uuid pk`
- `source_item_id uuid not null references private.source_items(id)`
- `evidence_type text not null check (evidence_type in ('TEXT','IMAGE','VIDEO_SEGMENT','AUDIO_SEGMENT','PDF','METADATA','OPERATOR_NOTE','OTHER'))`
- `storage_ref text null`
- `content_sha256 text null`
- `text_excerpt text null`
- `timestamp_start_seconds numeric null`
- `timestamp_end_seconds numeric null`
- `metadata jsonb not null default '{}'::jsonb`
- `access_class text not null default 'INTERNAL' check (access_class in ('PUBLIC_REFERENCE','INTERNAL','RESTRICTED'))`
- `created_at timestamptz not null default now()`

Rules:
- Evidence remains even if extraction is rejected.
- Long copyrighted source content should not be copied into `text_excerpt`; store only the minimum excerpt/reference necessary for verification.

## 6. Agent and Extraction Tables (`private`)

### `private.agent_runs`

Fields:
- `id uuid pk`
- `agent_type text not null`
- `agent_version text not null`
- `source_id uuid null references private.sources(id)`
- `correlation_id uuid null`
- `started_at timestamptz not null`
- `completed_at timestamptz null`
- `status text not null check (status in ('RUNNING','SUCCEEDED','FAILED','PARTIAL','CANCELLED'))`
- `items_scanned integer not null default 0`
- `items_created integer not null default 0`
- `review_cases_created integer not null default 0`
- `error_count integer not null default 0`
- `metrics jsonb not null default '{}'::jsonb`
- `errors jsonb not null default '[]'::jsonb`

Indexes:
- `(agent_type, started_at desc)`
- `(source_id, started_at desc)`

### `private.extraction_runs`

Fields:
- `id uuid pk`
- `source_item_id uuid not null references private.source_items(id)`
- `agent_run_id uuid null references private.agent_runs(id)`
- `model_provider text not null`
- `model_name text not null`
- `contract_version text not null`
- `prompt_version text null`
- `input_hash text not null`
- `started_at timestamptz not null`
- `completed_at timestamptz null`
- `status text not null check (status in ('RUNNING','SUCCEEDED','FAILED','PARTIAL'))`
- `usage_metadata jsonb not null default '{}'::jsonb`
- `error jsonb null`

Idempotency:
- unique `(source_item_id, model_provider, model_name, contract_version, input_hash)` for successful-equivalent extraction identity, or enforce equivalent application-side upsert semantics if retries need multiple run rows.

### `private.claims`
Atomic extracted factual assertions.

Fields:
- `id uuid pk`
- `extraction_run_id uuid not null references private.extraction_runs(id)`
- `candidate_group_id uuid not null`
- `subject_type text not null check (subject_type in ('BULL','OWNER','CAMP','VENUE','EVENT','MATCH','MATCH_PARTICIPANT'))`
- `subject_candidate_key text not null`
- `field_key text not null`
- `value_jsonb jsonb null`
- `basis text not null check (basis in ('EXPLICIT','INFERRED','UNKNOWN'))`
- `confidence numeric(5,4) null check (confidence is null or (confidence >= 0 and confidence <= 1))`
- `status text not null default 'CANDIDATE' check (status in ('CANDIDATE','SUPPORTED','CONFLICT','REJECTED','VERIFIED'))`
- `created_at timestamptz not null default now()`

Important: `UNKNOWN` may have `value_jsonb = null`; the extractor should represent missing facts explicitly rather than fabricate values.

### `private.claim_evidence`
Many-to-many evidence attachment.

Fields:
- `claim_id uuid references private.claims(id) on delete cascade`
- `evidence_id uuid references private.evidence(id)`
- `relationship text not null default 'SUPPORTS' check (relationship in ('SUPPORTS','CONTRADICTS','CONTEXT'))`
- `created_at timestamptz not null default now()`

Primary key: `(claim_id, evidence_id, relationship)`.

### `private.entity_match_candidates`

Fields:
- `id uuid pk`
- `candidate_group_id uuid not null`
- `entity_type text not null check (entity_type in ('BULL','OWNER','CAMP','VENUE','EVENT'))`
- `candidate_key text not null`
- `proposed_entity_id uuid null`
- `match_score numeric(5,4) not null check (match_score between 0 and 1)`
- `signals jsonb not null default '{}'::jsonb`
- `recommendation text not null check (recommendation in ('AUTO_LINK','REVIEW','NO_MATCH'))`
- `decision text null check (decision is null or decision in ('LINKED','REJECTED','NEW_ENTITY','MERGED'))`
- `review_case_id uuid null references public.review_cases(id)`
- timestamps

No generic FK is possible for `proposed_entity_id`; application validation must confirm the ID belongs to the declared entity type before a decision is committed.

### `private.duplicate_candidates`

Fields:
- `id uuid pk`
- `candidate_group_id uuid not null`
- `candidate_type text not null check (candidate_type in ('MATCH','EVENT','ENTITY'))`
- `proposed_existing_id uuid null`
- `score numeric(5,4) not null check (score between 0 and 1)`
- `signals jsonb not null default '{}'::jsonb`
- `differing_fields jsonb not null default '{}'::jsonb`
- `status text not null default 'CANDIDATE' check (status in ('CANDIDATE','REVIEW_REQUIRED','CONFIRMED_DUPLICATE','NOT_DUPLICATE'))`
- `review_case_id uuid null references public.review_cases(id)`
- timestamps

### `private.verification_results`

Fields:
- `id uuid pk`
- `candidate_group_id uuid not null`
- `verification_version text not null`
- `status text not null check (status in ('CORROBORATED','CONFLICT','INSUFFICIENT_EVIDENCE','REVIEW_REQUIRED','REJECTED'))`
- `confidence_summary numeric(5,4) null check (confidence_summary is null or confidence_summary between 0 and 1)`
- `summary jsonb not null default '{}'::jsonb`
- `review_case_id uuid null references public.review_cases(id)`
- `created_at timestamptz not null default now()`

A `CONFLICT` result must preserve competing claims; confidence averaging must not collapse the conflict.

## 7. Review Workflow (`public`)

### `public.review_cases`

Fields:
- `id uuid pk`
- `case_type text not null check (case_type in ('NEW_ENTITY','ENTITY_MATCH','DUPLICATE_MATCH','CONFLICTING_RESULT','CONFLICTING_DATE','LOW_CONFIDENCE','SOURCE_APPROVAL','MERGE_SPLIT','DATA_QUALITY','OTHER'))`
- `status text not null default 'OPEN' check (status in ('OPEN','IN_REVIEW','RESOLVED','REJECTED','CANCELLED'))`
- `priority text not null default 'NORMAL' check (priority in ('LOW','NORMAL','HIGH','URGENT'))`
- `subject_type text not null`
- `subject_ref jsonb not null`
- `summary text not null`
- `context jsonb not null default '{}'::jsonb`
- `assigned_to uuid null references public.app_users(id)`
- `created_at timestamptz not null default now()`
- `resolved_at timestamptz null`
- `resolved_by uuid null references public.app_users(id)`

`subject_ref` is intentionally JSON because review cases can target unpersisted candidates as well as canonical records. Required structure is versioned by the AI/review contract.

Indexes:
- `(status, priority, created_at)`
- `assigned_to`
- GIN on `subject_ref` only if query profiling later justifies it

### `public.review_actions`
Append-only review history.

Fields:
- `id uuid pk`
- `review_case_id uuid not null references public.review_cases(id)`
- `actor_id uuid not null references public.app_users(id)`
- `action text not null check (action in ('CLAIM','UNCLAIM','APPROVE','REJECT','EDIT','LINK_ENTITY','CREATE_ENTITY','CONFIRM_DUPLICATE','MARK_NOT_DUPLICATE','RESOLVE_CONFLICT','MERGE','SPLIT','COMMENT','REOPEN'))`
- `before_value jsonb null`
- `after_value jsonb null`
- `notes text null`
- `created_at timestamptz not null default now()`

Review actions are never updated/deleted in normal application flow.

## 8. Provenance and Audit (`private`)

### `private.fact_provenance`
Links a canonical fact to candidate claims/evidence/reviewer decision.

Fields:
- `id uuid pk`
- `subject_type text not null`
- `subject_id uuid not null`
- `field_key text not null`
- `value_fingerprint text null`
- `claim_id uuid null references private.claims(id)`
- `evidence_id uuid null references private.evidence(id)`
- `review_action_id uuid null references public.review_actions(id)`
- `relationship text not null check (relationship in ('SUPPORTS','CONTRADICTS','DERIVED_FROM','MANUAL_ENTRY'))`
- `created_at timestamptz not null default now()`

Rules:
- At least one of claim/evidence/review action must be present.
- Generic subject references are audit metadata; application/domain services validate subject type/ID consistency.

### `private.identity_events`
Append-only identity decision log.

Fields:
- `id uuid pk`
- `entity_type text not null check (entity_type in ('BULL','OWNER','CAMP','VENUE','EVENT'))`
- `event_type text not null check (event_type in ('MERGE','SPLIT','ALIAS_VERIFIED','ALIAS_REVOKED','CANONICAL_RENAMED'))`
- `source_entity_ids uuid[] not null default '{}'`
- `target_entity_ids uuid[] not null default '{}'`
- `review_case_id uuid null references public.review_cases(id)`
- `review_action_id uuid null references public.review_actions(id)`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`

This records the decision history even if the application later changes canonical pointers.

### `private.audit_log`

Fields:
- `id uuid pk`
- `actor_type text not null check (actor_type in ('USER','AGENT','SYSTEM'))`
- `actor_id text null`
- `action text not null`
- `entity_type text null`
- `entity_id uuid null`
- `correlation_id uuid null`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`

Audit rows are append-only.

## 9. Canonical Relationships

```text
auth.users
   -> public.app_users

owners -> camps -> bulls
   \        \      \
    aliases aliases aliases

venues -> events -> matches -> match_participants -> bulls
   \                   \
    aliases              -> match_results

private.sources
   -> private.source_items
      -> private.evidence
      -> private.extraction_runs
         -> private.claims
            -> private.claim_evidence -> evidence

candidate groups
   -> entity_match_candidates
   -> duplicate_candidates
   -> verification_results
   -> public.review_cases
      -> public.review_actions

verified facts
   -> private.fact_provenance

merge/split/name identity decisions
   -> private.identity_events
```

## 10. Publication and Statistics Rules

Authoritative statistics use only matches satisfying all of:
- `matches.verification_status = 'VERIFIED'`
- `matches.published_at is not null`
- match result exists
- referenced participants are valid
- result integrity checks pass

Rejected, unverified, review-required, or conflict records are excluded from public win/loss statistics by default.

Derived statistics must be reproducible from canonical tables; they should not be manually stored as source-of-truth counters on `bulls`.

## 11. RLS and Data API Model

Supabase exposure is **opt-in** for this project.

### Public read
Anonymous/public clients may eventually receive `SELECT` only for records that are explicitly published and not archived. Exact public policies are created in Phase 1 together with tests.

### Authenticated viewer
Same authoritative reads as public, plus self-profile where applicable.

### Reviewer
Can read review cases assigned/available to reviewers and append allowed review actions. Reviewers do not get unrestricted direct writes to canonical domain tables; review decisions go through controlled domain operations.

### Admin
Can manage canonical/reference data and source configuration through authenticated application operations.

### Private schema
`private` is not exposed to anonymous/public Data API clients. Workers/backend use trusted credentials or direct server-side database access.

Security requirements for Phase 1:
- RLS enabled on every exposed table
- grants explicitly reviewed; do not rely on platform defaults
- policies use `TO anon` / `TO authenticated` and explicit predicates
- no service-role/secret key in browser code
- views exposed to clients must use `security_invoker = true` where applicable
- `supabase test db` coverage for allow/deny behavior
- security/performance advisors run after DDL

## 12. Soft Delete / Archive Policy

Canonical domain records use archive semantics after they are referenced.

- `archived_at` + `archive_reason` hide inactive records while preserving historical references.
- Matches with evidence/history are not hard-deleted through ordinary application actions.
- Source items/evidence are retained even when rejected unless legal/policy requirements require deletion.
- Candidate rows may be lifecycle-pruned only under an explicit retention policy; provenance referenced by verified facts cannot be silently removed.

## 13. Search and Index Strategy

Phase 1 baseline indexes:
- normalized names and aliases
- bull match history (`match_participants.bull_id`)
- match date / venue date
- source id + publication time
- source dedupe key unique index
- review queue status/priority
- agent run type/start time

Fuzzy search:
- enable `pg_trgm` only if needed after baseline exact-normalized search
- do not pin an explicit extension version
- add GIN/GiST trigram indexes only to fields measured as useful

## 14. Migration Ordering

Proposed order:

1. required extensions (`pgcrypto`; optional `pg_trgm` without version pinning)
2. create `private` schema
3. `public.app_users`
4. owners + owner aliases
5. camps + camp aliases
6. bulls + bull aliases
7. venues + venue aliases
8. events
9. matches
10. match participants
11. match results
12. review cases + review actions
13. private source/evidence tables
14. private agent/extraction/claim tables
15. matching/duplicate/verification tables
16. provenance/identity/audit tables
17. indexes
18. integrity triggers/functions required for cross-table checks
19. grants/RLS/policies
20. database tests
21. advisors and performance review

No production data migration is part of `BMI-P0-002`.

## 15. Cross-Table Integrity Requiring Trigger/Domain Service

PostgreSQL CHECK constraints cannot express every cross-table rule. Phase 1 must explicitly test:

- `match_results.winner_participant_id` belongs to the same match
- a winner exists only for `result_type='WIN'`
- participant results are consistent with the match result
- reviewer resolution timestamps/actors match terminal status
- canonical publication occurs only from verified state
- generic entity references in identity/provenance records point to the declared type when written through domain services

## 16. Schema Acceptance Criteria

`BMI-P0-002` is accepted when:

- canonical and untrusted data zones are separate
- historical match snapshots are preserved
- result modeling avoids cyclic schema dependencies
- source item ingestion has a deterministic idempotency key
- claim-level evidence linkage exists
- review subject references can point to both candidates and canonical records
- identity merge/split decisions are auditable
- publication rules exclude unverified/conflicted data from statistics
- RLS/exposure assumptions are explicit
- migration order is unambiguous
- downstream AI/API contracts can reference stable table concepts

## 17. Phase 1 Implementation Notes

Before implementing migrations, confirm current Supabase behavior/documentation. In particular, project code must explicitly handle grants/RLS because new tables are no longer assumed to be automatically exposed to the Data API. Do not use platform behavior as an authorization strategy.
