# Database Schema v0.2 — Community Claims + Thai Bullfighting Temporal Domain

Status: **IMPLEMENTATION CONTRACT / MIGRATION NOT YET APPLIED**  
Task: `BMI-P1-011`  
Primary datastore: PostgreSQL / Supabase  
Schemas: `bullmatch` + `bullmatch_private`  
Last updated: 2026-09-07

## 1. Purpose

Schema v0.2 expands the deployed Phase 1 database from an operator-centric historical sports database into the approved BullMatch Community Data Network + Verified Big Data model.

The deployed v0.1 production foundation remains valid. v0.2 is deliberately **additive**: existing public API queries, admin CRUD functions, bull profiles, match statistics, matches and results continue to use the current canonical tables until new verified facts are promoted into them or future APIs intentionally expose new domain surfaces.

The central flow is:

`Community/source input -> Evidence -> Atomic claims -> Entity resolution / duplicate checks -> Corroboration / review -> Canonical verified domain -> Publication -> Analytics`

A community submission never writes directly over canonical history.

## 2. Non-negotiable design rules

1. Stable UUIDs identify canonical entities; display names never serve as identity keys.
2. Community input and external-source input are untrusted until verified.
3. Evidence survives claim rejection where retention policy permits.
4. Claims are atomic. Result, duration, date, identity, venue and affiliation can have different verification states.
5. Current owner/camp/profile convenience columns never replace historical time-bound relationships.
6. `วันเปรียบ`, pairing, program publication and actual match are separate domain records.
7. Program amendments are versioned; old program versions are not overwritten.
8. Physical traits, horn/yod and `ทางชน` are observations with evidence, not permanent unquestionable labels.
9. Unresolved lineage remains a claim; only resolved/verified relationships enter canonical lineage tables.
10. Contributor reputation is multidimensional and derived from verified outcomes, not submission volume.
11. Reputation/credit is never a substitute for evidence or a database integrity constraint.
12. Financial labels appearing in programs are archival source metadata only. The schema does not model stake collection, wallets, settlement or payouts.
13. `bullmatch_private` remains inaccessible to browser clients.
14. All privileged promotion/review operations remain server-mediated and auditable.
15. Existing production API and canonical tables must remain backward compatible during migration.

## 3. Deployed baseline retained from v0.1

The following existing canonical tables remain authoritative and are not renamed or destructively rebuilt:

### `bullmatch`

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
- existing statistics/views/functions and controlled API support objects

### `bullmatch_private`

- `sources`
- `source_runtime_state`
- `source_items`
- `evidence`
- `agent_runs`
- `extraction_runs`
- `candidate_groups`
- `claims`
- `claim_evidence`
- `entity_match_candidates`
- `entity_source_mappings`
- `duplicate_candidates`
- `verification_results`
- `fact_provenance`
- `identity_events`
- `audit_log`
- private owner details and other already-deployed support objects

Canonical `bulls.current_owner_id`, `bulls.current_camp_id`, `color_description`, `lineage_notes` and similar v0.1 fields remain for compatibility. v0.2 treats them as **legacy/current-summary conveniences**, not the sole historical model.

## 4. Identity and account separation

### 4.1 Privileged application role stays separate

`bullmatch.app_users` remains the authorization table for privileged BullMatch roles currently used by production:

- `ADMIN`
- `REVIEWER`
- `VIEWER`

Do not overload this role column with contributor reputation or topic expertise.

A user can participate as a contributor without being granted reviewer/admin authority.

### 4.2 New `bullmatch.contributor_profiles`

Purpose: application-level participation profile linked to shared `auth.users` while remaining independent from privileged roles.

Fields:

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `handle text null`
- `display_name text null`
- `profile_visibility text not null default 'PRIVATE' check (... in ('PRIVATE','PUBLIC'))`
- `status text not null default 'ACTIVE' check (... in ('ACTIVE','SUSPENDED','BANNED','LEFT'))`
- `contribution_started_at timestamptz null`
- `public_bio text null`
- `home_region_code text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Rules:

- no email/phone is copied into the public contributor profile
- public visibility is opt-in
- contributor status does not grant canonical write permission
- browser writes should go through controlled API, not direct table mutation

## 5. Community submission layer

### 5.1 New `bullmatch_private.community_submissions`

One user intent/action: upload a program image, report a result, propose a correction, identify a bull, submit lineage information, submit a URL, etc.

Fields:

- `id uuid primary key default gen_random_uuid()`
- `submitter_user_id uuid not null references auth.users(id)`
- `submission_type text not null check (... in ('PROGRAM','RESULT','BULL_IDENTITY','BULL_PROFILE','AFFILIATION','LINEAGE','PHYSICAL_OBSERVATION','STYLE_OBSERVATION','COMPARISON','PAIRING','CORRECTION','URL','OTHER'))`
- `client_submission_key text null`
- `status text not null default 'RECEIVED' check (... in ('RECEIVED','PARSING','CLAIMS_READY','REVIEW_REQUIRED','PARTIALLY_ACCEPTED','ACCEPTED','REJECTED','WITHDRAWN','DUPLICATE','FAILED'))`
- `target_hint jsonb not null default '{}'::jsonb`
- `user_note text null`
- `source_url text null`
- `dedupe_fingerprint text null`
- `submitted_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `resolved_at timestamptz null`
- `moderation_metadata jsonb not null default '{}'::jsonb`

Constraints/indexes:

- optional unique `(submitter_user_id, client_submission_key)` where key is not null for retry/idempotency
- index `(submitter_user_id, submitted_at desc)`
- index `(status, submitted_at)`
- index `dedupe_fingerprint`

The raw form payload must not become a canonical record. Structured candidate data belongs in claims.

### 5.2 Generalize `bullmatch_private.evidence`

Current production evidence requires a `source_item_id`. v0.2 must support community-origin evidence without inventing fake external source records.

Add:

- `submission_id uuid null references bullmatch_private.community_submissions(id) on delete set null`
- `submitted_by_user_id uuid null references auth.users(id) on delete set null`
- `captured_at timestamptz null`
- `original_filename text null`
- `mime_type text null`
- `rights_basis text null`
- `moderation_status text not null default 'PENDING' check (... in ('PENDING','ALLOWED','RESTRICTED','REJECTED'))`

Change:

- `source_item_id` becomes nullable
- its FK should use `on delete set null` rather than making evidence disappear with a source item

Origin constraint:

`num_nonnulls(source_item_id, submission_id) >= 1`

Evidence may have both when a community-submitted URL/file is later associated with a registered source item.

Retain:

- content hashes
- timestamps/video ranges
- `access_class`
- storage reference
- minimal excerpt policy

Binary media remains in object storage/approved file storage, not PostgreSQL blobs.

### 5.3 Generalize `bullmatch_private.extraction_runs`

AI/deterministic extraction must accept either external source material or a community submission.

Add:

- `submission_id uuid null references bullmatch_private.community_submissions(id) on delete set null`
- `input_evidence_id uuid null references bullmatch_private.evidence(id) on delete set null`

Change:

- `source_item_id` becomes nullable

Constraint:

At least one of `source_item_id`, `submission_id`, `input_evidence_id` is non-null.

Do not require a community contribution to use AI. Manual confirmed claims can exist without an extraction run.

## 6. Atomic claim model v0.2

### 6.1 Generalize `bullmatch_private.claims`

The existing claim representation is retained because `subject_type + subject_ref + field_key + value_json` is intentionally language/domain neutral.

Changes:

- make `extraction_run_id` nullable
- add `submission_id uuid null references bullmatch_private.community_submissions(id) on delete set null`
- add `created_by_user_id uuid null references auth.users(id) on delete set null`
- add `origin_type text not null default 'SOURCE_EXTRACTION' check (... in ('SOURCE_EXTRACTION','COMMUNITY_SUBMISSION','OPERATOR_MANUAL','SYSTEM_DERIVED'))`
- add `canonical_subject_id uuid null`
- add `value_fingerprint text null`
- add `supersedes_claim_id uuid null references bullmatch_private.claims(id) on delete set null`
- add `review_case_id uuid null references bullmatch.review_cases(id) on delete set null`
- add `updated_at timestamptz not null default now()`

Replace status check with:

- `PROPOSED`
- `REVIEW_REQUIRED`
- `CORROBORATED`
- `VERIFIED`
- `CONFLICT`
- `REJECTED`
- `SUPERSEDED`
- `WITHDRAWN`

Origin integrity:

- `SOURCE_EXTRACTION` requires `extraction_run_id`
- `COMMUNITY_SUBMISSION` requires `submission_id`
- manual/system claims must retain an audit actor/correlation reference through review/audit operations

Important: `VERIFIED` means the claim itself has passed policy. It does not automatically mean a canonical table was already mutated. Promotion is a separate auditable operation.

### 6.2 Existing `claim_evidence` remains the common evidence edge

Relationships remain:

- `SUPPORTS`
- `CONTRADICTS`
- `CONTEXT`

v0.2 may additionally allow:

- `IDENTIFIES`
- `DATES`
- `ATTRIBUTES`

only if implementation proves those labels useful. The minimal three-value model is sufficient for first migration.

### 6.3 Claim granularity examples

A submitted statement:

> วัว A ชนะวัว B ที่สนาม X ใช้เวลา 25 นาที

must become separate claims, e.g.:

- participant identity A
- participant identity B
- match occurrence
- venue identity
- match date if supplied
- result = A wins
- duration = 1500 seconds

Verification can accept the result while leaving duration in `CONFLICT`.

## 7. Canonical people and temporal bull affiliations

### 7.1 New `bullmatch.people`

Purpose: represent publicly relevant human actors who are not adequately modeled as an `owner` entity, such as keeper/handler, trainer, breeder contact identity, referee or domain expert when needed by product scope.

Fields:

- `id uuid primary key default gen_random_uuid()`
- `display_name text not null`
- `normalized_name text not null`
- `person_type text not null default 'OTHER' check (... in ('KEEPER','HANDLER','TRAINER','BREEDER','REFEREE','EXPERT','VENUE_STAFF','OTHER'))`
- `province text null`
- `district text null`
- `notes text null`
- `verification_status text not null default 'UNVERIFIED' check (... in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED'))`
- `archived_at timestamptz null`
- `archive_reason text null`
- timestamps

No private contact details belong in this table.

### 7.2 New `bullmatch.bull_affiliations`

Time-bound association of a bull with owner/camp/person.

Fields:

- `id uuid primary key default gen_random_uuid()`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `relationship_type text not null check (... in ('OWNER','CO_OWNER','BREEDER','CAMP','KEEPER','HANDLER','TRAINER','OTHER'))`
- `owner_id uuid null references bullmatch.owners(id) on delete set null`
- `camp_id uuid null references bullmatch.camps(id) on delete set null`
- `person_id uuid null references bullmatch.people(id) on delete set null`
- `valid_from date null`
- `valid_from_precision text not null default 'UNKNOWN' check (... in ('DAY','MONTH','YEAR','ESTIMATED','UNKNOWN'))`
- `valid_to date null`
- `valid_to_precision text not null default 'UNKNOWN'`
- `is_current boolean not null default false`
- `verification_status text not null default 'VERIFIED' check (... in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED'))`
- `notes text null`
- timestamps

Constraint:

`num_nonnulls(owner_id, camp_id, person_id) = 1`

Application/domain validation maps relationship type to sensible target kinds but does not force ambiguous historical evidence into the wrong entity type.

No global no-overlap constraint is imposed because co-owners, multiple caretakers and uncertain dates can legitimately overlap.

### 7.3 Compatibility with `bulls.current_owner_id/current_camp_id`

Current columns remain.

After v0.2 implementation, controlled promotion may update current summary columns when a verified open-ended affiliation is authoritative. The temporal table remains the history of record; the current columns remain optimized compatibility/read conveniences.

## 8. Bull identity, imagery and external identifiers

### 8.1 New `bullmatch.bull_media`

Fields:

- `id uuid pk`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `evidence_id uuid null references bullmatch_private.evidence(id) on delete set null`
- `media_role text not null check (... in ('PRIMARY','IDENTITY','PROFILE','MATCH','COMPARISON','GALLERY','OTHER'))`
- `storage_ref text null`
- `captured_at timestamptz null`
- `is_public boolean not null default false`
- `verification_status text not null default 'UNVERIFIED'`
- timestamps

This supports the real-bull visual mandate while keeping rights/access policy explicit.

### 8.2 New private `bullmatch_private.bull_external_identifiers`

Potentially sensitive/durable identifiers stay private by default.

Fields:

- `id uuid pk`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `identifier_type text not null`
- `issuer text null`
- `identifier_value text not null`
- `normalized_value text not null`
- `valid_from date null`
- `valid_to date null`
- `verification_status text not null default 'UNVERIFIED'`
- `evidence_id uuid null references bullmatch_private.evidence(id) on delete set null`
- timestamps

Do not expose identifiers through the public API merely because they exist.

## 9. Physical, marking, horn and fighting-style observations

### 9.1 New `bullmatch.bull_trait_observations`

Fields:

- `id uuid pk`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `trait_family text not null check (... in ('COLOR','MARKING','BODY','HORN','YOD','OTHER'))`
- `normalized_term text null`
- `raw_term text not null`
- `body_region text null`
- `observed_value jsonb not null default '{}'::jsonb`
- `observed_at date null`
- `date_precision text not null default 'UNKNOWN'`
- `match_id uuid null references bullmatch.matches(id) on delete set null`
- `comparison_session_id uuid null` (FK added after comparison table creation)
- `evidence_id uuid null references bullmatch_private.evidence(id) on delete set null`
- `verification_status text not null default 'UNVERIFIED' check (... in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED'))`
- timestamps

Raw local terminology is preserved even when no normalized vocabulary exists.

### 9.2 New `bullmatch.bull_style_observations`

Fields:

- `id uuid pk`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `normalized_style_term text null`
- `raw_description text not null`
- `observation_context text not null check (... in ('MATCH','SPARRING','COMPARISON','EXPERT_REPORT','VIDEO','OTHER'))`
- `match_id uuid null references bullmatch.matches(id) on delete set null`
- `comparison_session_id uuid null`
- `observed_at date null`
- `date_precision text not null default 'UNKNOWN'`
- `evidence_id uuid null references bullmatch_private.evidence(id) on delete set null`
- `verification_status text not null default 'UNVERIFIED' check (... in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED'))`
- timestamps

Do not collapse all observations into one permanent `style` field on the bull.

## 10. Verified lineage graph

### New `bullmatch.bull_parentage`

This table stores resolved canonical parentage only. Unresolved community lineage statements remain atomic claims.

Fields:

- `id uuid pk`
- `child_bull_id uuid not null references bullmatch.bulls(id)`
- `parent_bull_id uuid not null references bullmatch.bulls(id)`
- `parent_role text not null check (... in ('SIRE','DAM'))`
- `verification_status text not null default 'VERIFIED' check (... in ('VERIFIED','CONFLICT','REVOKED'))`
- `verified_at timestamptz null`
- timestamps

Constraints:

- child cannot equal parent
- unique active `(child_bull_id, parent_role)` should **not** be blindly enforced if conflicting historical claims must temporarily coexist; canonical promotion policy should allow `CONFLICT` rows and require one authoritative `VERIFIED` row per role before public lineage views choose a parent
- cycles must be prevented by a controlled promotion function, not only by a trivial row check

Breeder/farm-of-origin relationships belong in `bull_affiliations` or claims, not in parentage.

## 11. Comparison day / `วันเปรียบ`

### 11.1 New `bullmatch.comparison_sessions`

Fields:

- `id uuid pk`
- `venue_id uuid null references bullmatch.venues(id) on delete set null`
- `session_date date null`
- `date_precision text not null default 'UNKNOWN'`
- `name text null`
- `status text not null default 'PLANNED' check (... in ('PLANNED','IN_PROGRESS','COMPLETED','CANCELLED','UNKNOWN'))`
- `verification_status text not null default 'UNVERIFIED' check (... in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED'))`
- `notes text null`
- timestamps / archive fields

### 11.2 New `bullmatch.comparison_entries`

One bull presented/recorded in a comparison session.

Fields:

- `id uuid pk`
- `comparison_session_id uuid not null references bullmatch.comparison_sessions(id) on delete cascade`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `display_name_snapshot text not null`
- `owner_id_snapshot uuid null references bullmatch.owners(id) on delete set null`
- `camp_id_snapshot uuid null references bullmatch.camps(id) on delete set null`
- `weight_kg numeric(7,2) null`
- `age_months_estimate integer null`
- `appearance_snapshot jsonb not null default '{}'::jsonb`
- `verification_status text not null default 'UNVERIFIED'`
- timestamps

Unique `(comparison_session_id, bull_id)` unless evidence shows the session itself is duplicated, in which case duplicate resolution occurs at session/entity level before canonical insertion.

## 12. Pairing lifecycle

### 12.1 New `bullmatch.pairings`

A pairing is distinct from a program row and distinct from the actual match.

Fields:

- `id uuid pk`
- `comparison_session_id uuid null references bullmatch.comparison_sessions(id) on delete set null`
- `venue_id uuid null references bullmatch.venues(id) on delete set null`
- `proposed_match_date date null`
- `date_precision text not null default 'UNKNOWN'`
- `status text not null default 'PROPOSED' check (... in ('PROPOSED','REJECTED','ACCEPTED','CANCELLED','SUPERSEDED','UNKNOWN'))`
- `accepted_at timestamptz null`
- `cancelled_at timestamptz null`
- `cancellation_reason text null`
- `archival_terms jsonb not null default '{}'::jsonb`
- `verification_status text not null default 'UNVERIFIED'`
- timestamps / archive fields

`archival_terms` may preserve source labels such as published prize/financial wording, deposits or conditions only as provenance-bearing historical metadata. It is never a wallet, bet or settlement ledger.

### 12.2 New `bullmatch.pairing_participants`

Fields:

- `id uuid pk`
- `pairing_id uuid not null references bullmatch.pairings(id) on delete cascade`
- `bull_id uuid not null references bullmatch.bulls(id)`
- `position smallint not null check (position in (1,2))`
- `display_name_snapshot text not null`
- `owner_id_snapshot uuid null references bullmatch.owners(id) on delete set null`
- `camp_id_snapshot uuid null references bullmatch.camps(id) on delete set null`
- `weight_kg_snapshot numeric(7,2) null`
- `published_side_label text null`
- timestamps

Constraints:

- unique `(pairing_id, bull_id)`
- unique `(pairing_id, position)`
- a controlled acceptance operation requires exactly two participants before status can become `ACCEPTED`

### 12.3 Add optional pairing link to `bullmatch.matches`

Add:

- `pairing_id uuid null references bullmatch.pairings(id) on delete set null`

Existing matches remain valid with null pairing.

## 13. Versioned event programs

### 13.1 New `bullmatch.event_programs`

Stable identity for one program/card concept.

Fields:

- `id uuid pk`
- `event_id uuid null references bullmatch.events(id) on delete set null`
- `venue_id uuid null references bullmatch.venues(id) on delete set null`
- `program_date date null`
- `name text null`
- `verification_status text not null default 'UNVERIFIED'`
- timestamps / archive fields

### 13.2 New `bullmatch.event_program_versions`

Fields:

- `id uuid pk`
- `program_id uuid not null references bullmatch.event_programs(id) on delete cascade`
- `version_no integer not null check (version_no > 0)`
- `supersedes_version_id uuid null references bullmatch.event_program_versions(id) on delete set null`
- `published_at timestamptz null`
- `effective_at timestamptz null`
- `status text not null default 'PUBLISHED' check (... in ('DRAFT','PUBLISHED','SUPERSEDED','RETRACTED'))`
- `source_label text null`
- `verification_status text not null default 'UNVERIFIED'`
- timestamps

Unique `(program_id, version_no)`.

Published versions are immutable except controlled correction metadata; amendments create a new version.

### 13.3 New `bullmatch.event_program_entries`

Fields:

- `id uuid pk`
- `program_version_id uuid not null references bullmatch.event_program_versions(id) on delete cascade`
- `entry_order integer null`
- `pairing_id uuid null references bullmatch.pairings(id) on delete set null`
- `match_id uuid null references bullmatch.matches(id) on delete set null`
- `entry_status text not null default 'SCHEDULED' check (... in ('SCHEDULED','CANCELLED','REPLACED','COMPLETED','UNKNOWN'))`
- `display_label text null`
- `feature_label text null`
- `archival_financial_labels jsonb not null default '{}'::jsonb`
- `raw_text text null`
- timestamps

Program entries retain what was actually published in that version even when the eventual match differs.

## 14. Rule version readiness

Venue/event rules must not be hard-coded globally.

### 14.1 New `bullmatch.rule_profiles`

- stable rule profile identity
- name
- venue scope when appropriate
- status
- timestamps

### 14.2 New `bullmatch.rule_profile_versions`

- `rule_profile_id`
- `version_no`
- effective date range
- structured `rules_json`
- exact/source wording reference
- verification state
- provenance

### 14.3 Add nullable rule links

Future additive columns:

- `events.rule_profile_version_id`
- `comparison_sessions.rule_profile_version_id`
- `matches.rule_profile_version_id`

Null remains valid until field validation establishes a verified rule version.

## 15. Contributor reputation model

### 15.1 New `bullmatch_private.contributor_reputation_events`

Append-only events generated from verified review outcomes.

Fields:

- `id uuid pk`
- `user_id uuid not null references auth.users(id)`
- `dimension text not null check (... in ('BULL_IDENTITY','MATCH_RESULT','PROGRAM','LINEAGE','PHYSICAL_STYLE','EVIDENCE_QUALITY','REVIEW_QUALITY'))`
- `venue_id uuid null references bullmatch.venues(id) on delete set null`
- `region_code text null`
- `claim_id uuid null references bullmatch_private.claims(id) on delete set null`
- `review_action_id uuid null references bullmatch.review_actions(id) on delete set null`
- `outcome text not null check (... in ('ACCURATE','PARTIAL','INACCURATE','DUPLICATE','ABUSIVE','REVIEW_AGREEMENT','REVIEW_OVERTURNED'))`
- `weight numeric(8,4) not null default 1`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`

Reputation events are never directly inserted by a browser client.

### 15.2 New `bullmatch.contributor_reputation`

Materialized/current aggregate per dimension and optional locality scope.

Fields:

- `user_id uuid not null references auth.users(id)`
- `dimension text not null`
- `venue_id uuid null references bullmatch.venues(id) on delete cascade`
- `region_code text null`
- `verified_count integer not null default 0`
- `rejected_count integer not null default 0`
- `duplicate_count integer not null default 0`
- `quality_score numeric(6,3) null`
- `confidence_band text not null default 'INSUFFICIENT_DATA' check (... in ('INSUFFICIENT_DATA','LOW','MEDIUM','HIGH'))`
- `last_event_at timestamptz null`
- `updated_at timestamptz not null default now()`

Use a synthetic `scope_key` generated from venue/region/global scope to support deterministic uniqueness rather than relying on nullable unique-column semantics.

No client can self-edit these rows.

### 15.3 Credits remain separate from reputation

`Contribute to Unlock` economics are intentionally deferred to BMI-P1-012.

If credits are implemented, use an append-only credit ledger derived from verified contribution value. Never place credit balance/points inside `claims` or use it to decide factual truth.

## 16. Entity resolution and duplicate compatibility

Existing candidate tables remain useful but their type constraints need expansion.

### `bullmatch_private.entity_match_candidates.entity_type`

Extend supported canonical types toward:

- `BULL`
- `OWNER`
- `CAMP`
- `PERSON`
- `VENUE`
- `EVENT`
- `COMPARISON_SESSION`
- `PAIRING`
- `PROGRAM`

### `bullmatch_private.duplicate_candidates.candidate_type`

Extend toward:

- `MATCH`
- `EVENT`
- `ENTITY`
- `COMPARISON_SESSION`
- `PAIRING`
- `PROGRAM_VERSION`
- `SUBMISSION`

New contributions must search likely existing bulls/pairings/programs before canonical entity creation.

Name normalization remains candidate-retrieval input, never identity proof.

## 17. Review workflow compatibility

Existing `bullmatch.review_cases` and `review_actions` remain the review shell.

P1-011 does not redesign their full API because BMI-P1-008 resumes after P1-012.

Schema v0.2 requires review cases to be able to reference:

- submission
- claim
- evidence
- candidate group
- entity match candidate
- duplicate candidate
- conflict set

Where the existing review table has generic subject metadata, reuse it. If it cannot express these links strongly enough, the later P1-008 migration should add nullable reference columns or a normalized `review_case_links` table rather than replacing review history.

## 18. Promotion from verified claims into canonical facts

Canonical mutation is a controlled server-side action.

A promotion operation must:

1. verify claim state/policy
2. resolve the canonical subject/entity
3. use optimistic/stale-write checks where an existing fact is being changed
4. update/insert the canonical table or temporal relationship
5. write `fact_provenance`
6. write review/audit action
7. never delete contradicting evidence
8. invalidate/recompute affected derived statistics if necessary

Examples:

- verified current owner claim -> insert temporal `bull_affiliations`; optionally update `bulls.current_owner_id`
- verified style observation -> insert `bull_style_observations`
- verified sire claim -> insert/resolve `bull_parentage`
- verified comparison record -> insert `comparison_sessions` + entries
- verified result claim -> update/create existing match result through controlled match functions

## 19. Publication and analytics boundary

Authoritative public surfaces use only verified/published canonical data.

Community submissions, raw claims, private evidence and reputation-event internals remain private unless a specific safe projection is intentionally exposed.

Future analytics should receive data-quality fields such as:

- evidence count/diversity
- unresolved conflicts
- observation recency
- sample size
- identity confidence
- contributor-locality corroboration

These are analytical metadata, not betting odds or guarantees.

## 20. Security / RLS contract

### `bullmatch_private`

- schema not browser-exposed
- `PUBLIC`, `anon`, `authenticated` receive no direct table/function privileges
- service-side operations only
- source text, restricted evidence, moderation metadata, external identifiers and reputation-event details remain private

### `bullmatch`

- new tables start RLS-enabled and default-deny
- current production controlled Edge API remains the preferred mutation boundary
- public data is projected only from verified/published rows
- contributor self-service uses authenticated server-mediated endpoints that derive the user from validated auth, never from an arbitrary submitted `user_id`

### Storage

- uploads use non-public/private buckets by default
- public bull/profile media requires explicit allowed/public state
- storage object path must not grant canonical verification status
- hashes/references stored in PostgreSQL

## 21. Indexing and scale principles

Initial indexes should cover:

- all foreign keys used in joins
- submission `(submitter_user_id, submitted_at desc)`
- submission `(status, submitted_at)`
- evidence hashes
- claim `(canonical_subject_id, field_key, status)`
- claim `(submission_id, created_at)`
- affiliations `(bull_id, relationship_type, valid_from)`
- trait/style observations `(bull_id, observed_at desc)`
- comparison `(venue_id, session_date)`
- pairing `(status, proposed_match_date)` and participants `bull_id`
- program `(venue_id, program_date)` / version `(program_id, version_no)`
- reputation `(user_id, dimension, scope_key)`

Do not create expensive GIN/JSON indexes until a demonstrated query needs them.

Evidence binaries do not belong in PostgreSQL.

## 22. Backward compatibility

The following production behaviors must remain unchanged immediately after v0.2 migration:

- existing ADMIN login and role checks
- existing `/me` behavior
- existing public Dashboard/Bulls/Bull/Matches/Match/Venues API resources
- existing manual canonical admin CRUD
- existing match publication/statistics views
- existing service-role-only bridge security
- existing canonical row IDs

No v0.2 migration may rename/drop current columns or change existing function signatures required by `bullmatch-api`.

New columns added to existing tables are nullable or have safe defaults.

## 23. Migration sequencing contract

Implementation should be split into reviewable migrations, not one monolith:

1. **P1-011A — Community submission/evidence/claim generalization**
2. **P1-011B — Contributor profile + reputation event/aggregate foundation**
3. **P1-011C — People + temporal affiliations + bull media/identity extensions**
4. **P1-011D — Trait/style observations + verified lineage**
5. **P1-011E — Comparison + pairing lifecycle**
6. **P1-011F — Program versioning + optional rule-version foundation**
7. **P1-011G — Resolution type expansion + indexes/security tests**

These migration IDs are design labels; actual migration filenames must use repository timestamp conventions.

Each migration requires:

- transaction-safe DDL where supported
- grants/RLS assertions
- shared-Supabase isolation checks
- rollback/repair notes
- API compatibility check
- no fabricated production data

## 24. Rollback philosophy

Because new tables are additive, rollback should prefer disabling new application paths and leaving empty/unreferenced tables intact over destructive data deletion.

Before production usage:

- a migration may be reversed by dropping newly created empty objects and restoring altered constraints

After real community data exists:

- never drop submission/evidence/claim/reputation history merely to roll back application code
- use forward repair migrations
- restore old API behavior by feature flag/routing while preserving data

Constraint changes to `evidence`, `extraction_runs` and `claims` must be reversible in tests, but production rollback must first prove no new rows depend on nullable/new-origin behavior.

## 25. Deferred decisions

Not finalized in P1-011:

- exact reputation scoring formula and thresholds
- contribution-credit economic formula
- owner/camp representative verification policy
- public contributor badge rules
- automated claim auto-verification thresholds
- venue-specific rule vocabulary still awaiting field validation
- exact external animal-identifier types/visibility
- premium entitlements/billing schema

These belong to P1-012 or later product/legal/field-validation tasks.

## 26. Definition of ready for migration implementation

Schema v0.2 is ready for implementation when:

- this contract is merged
- P1-012 defines trust/moderation behavior that affects write permissions
- migration slices are converted into timestamped SQL
- local/transactional migration tests are written
- production API backward-compatibility tests pass
- RLS/grant/isolation tests prove community users cannot mutate canonical truth directly

## 27. Summary

v0.2 does **not** replace BullMatch's working production database.

It wraps that foundation with the missing structures needed for the real product:

- community submissions
- first-class evidence from community or sources
- atomic claims independent of AI
- temporal owner/camp/keeper history
- real bull imagery and identity support
- physical/horn/style observations
- verified lineage graph
- comparison day
- pairing lifecycle
- versioned programs
- rule-version readiness
- multidimensional contributor trust
- controlled promotion into canonical history

This is the data foundation required before opening BullMatch to large-scale community contribution and before building serious evidence-aware Matchup Intelligence.
