# Database Schema v0.1 — Design Draft

Status: Phase 0 design; not yet a production migration.
Primary datastore: PostgreSQL / Supabase

## Design Principles

1. Stable UUIDs are canonical identifiers.
2. Names are attributes, never foreign keys.
3. Historical match-time facts remain attached to the match/participant record.
4. Raw/candidate data is separated from verified domain data.
5. Evidence and review decisions are auditable.
6. Entity merges must remain traceable.

## Core Domain Tables

### `bulls`

Purpose: canonical bull identity.

Suggested fields:
- `id uuid pk`
- `canonical_name text not null`
- `normalized_name text`
- `birth_date date null`
- `birth_date_precision text null`
- `sex text default 'male'`
- `color_description text null`
- `breed_description text null`
- `lineage_notes text null`
- `current_camp_id uuid null`
- `current_owner_id uuid null`
- `home_region text null`
- `status text`
- `primary_image_ref text null`
- `notes text null`
- `verification_status text`
- `created_at timestamptz`
- `updated_at timestamptz`

### `bull_aliases`

- `id uuid pk`
- `bull_id uuid fk bulls`
- `alias text not null`
- `normalized_alias text`
- `alias_type text null`
- `source_id uuid null`
- `verified boolean default false`
- `created_at timestamptz`

Index normalized alias for entity resolution.

### `owners`

- `id uuid pk`
- `name text not null`
- `normalized_name text`
- `region text null`
- `contact_private jsonb null`
- `notes text null`
- `verification_status text`
- timestamps

### `camps`

- `id uuid pk`
- `name text not null`
- `normalized_name text`
- `owner_id uuid null`
- `region text null`
- `notes text null`
- `verification_status text`
- timestamps

### `venues`

- `id uuid pk`
- `name text not null`
- `normalized_name text`
- `province text null`
- `district text null`
- `address text null`
- `latitude numeric null`
- `longitude numeric null`
- `status text`
- timestamps

### `events`

- `id uuid pk`
- `venue_id uuid null`
- `name text null`
- `event_date date null`
- `start_time timestamptz null`
- `date_precision text`
- `status text`
- `notes text null`
- timestamps

### `matches`

- `id uuid pk`
- `event_id uuid null`
- `venue_id uuid null`
- `match_date timestamptz null`
- `date_precision text`
- `match_number integer null`
- `status text`
- `result_type text` (`WIN`, `DRAW`, `NO_RESULT`, `CANCELLED`, `UNKNOWN`)
- `winner_participant_id uuid null` (added safely after participant design/migration ordering)
- `duration_seconds integer null`
- `result_detail text null`
- `verification_status text`
- `published_at timestamptz null`
- timestamps

### `match_participants`

Purpose: historical snapshot per bull per match.

- `id uuid pk`
- `match_id uuid fk matches`
- `bull_id uuid fk bulls`
- `side text null`
- `camp_id_snapshot uuid null`
- `owner_id_snapshot uuid null`
- `weight_kg numeric null`
- `age_months_estimate integer null`
- `display_name_snapshot text null`
- `participant_result text null`
- `notes text null`
- timestamps

Constraint: normally one bull appears once per match.

## Source & Evidence Tables

### `sources`

- `id uuid pk`
- `name text not null`
- `source_type text`
- `base_url text null`
- `connector_key text`
- `access_method text`
- `reliability_tier text null`
- `polling_enabled boolean`
- `poll_interval_minutes integer null`
- `policy_notes text null`
- `status text`
- timestamps

### `source_items`

Represents one discovered post/page/video/feed item.

- `id uuid pk`
- `source_id uuid fk sources`
- `external_id text null`
- `canonical_url text null`
- `published_at timestamptz null`
- `retrieved_at timestamptz not null`
- `content_hash text null`
- `title text null`
- `normalized_text text null`
- `raw_metadata jsonb null`
- `connector_name text`
- `connector_version text`
- `ingestion_status text`
- timestamps

Unique strategy should prefer `(source_id, external_id)` when external ID exists, otherwise an appropriate canonical/content identity.

### `evidence`

- `id uuid pk`
- `source_item_id uuid fk source_items`
- `evidence_type text`
- `storage_ref text null`
- `text_excerpt text null`
- `timestamp_start_seconds numeric null`
- `timestamp_end_seconds numeric null`
- `metadata jsonb null`
- `created_at timestamptz`

## AI Candidate Tables

### `extraction_runs`

- `id uuid pk`
- `source_item_id uuid fk source_items`
- `model_provider text`
- `model_name text`
- `prompt/schema_version text`
- `started_at timestamptz`
- `completed_at timestamptz null`
- `status text`
- `usage_metadata jsonb null`
- `error jsonb null`

### `extraction_candidates`

- `id uuid pk`
- `extraction_run_id uuid fk extraction_runs`
- `candidate_type text`
- `payload jsonb not null`
- `confidence numeric null`
- `status text`
- timestamps

Candidate payloads should later be replaced/supplemented by typed shared contracts where practical.

### `entity_match_candidates`

- `id uuid pk`
- `candidate_id uuid fk extraction_candidates`
- `entity_type text`
- `proposed_entity_id uuid null`
- `match_score numeric`
- `signals jsonb`
- `decision text`
- `review_case_id uuid null`
- timestamps

## Verification / Review Tables

### `review_cases`

- `id uuid pk`
- `case_type text`
- `status text`
- `priority text`
- `subject_type text`
- `subject_ref uuid/null or jsonb reference design to finalize`
- `summary text`
- `context jsonb`
- `created_at timestamptz`
- `resolved_at timestamptz null`
- `resolved_by uuid null`

### `review_actions`

- `id uuid pk`
- `review_case_id uuid fk review_cases`
- `actor_id uuid null`
- `action text`
- `before_value jsonb null`
- `after_value jsonb null`
- `notes text null`
- `created_at timestamptz`

### `audit_log`

- `id uuid pk`
- `actor_type text`
- `actor_id text/uuid null`
- `action text`
- `entity_type text`
- `entity_id uuid null`
- `metadata jsonb`
- `created_at timestamptz`

## Agent Operations

### `agent_runs`

- `id uuid pk`
- `agent_type text`
- `agent_version text`
- `source_id uuid null`
- `started_at timestamptz`
- `completed_at timestamptz null`
- `status text`
- `items_scanned integer default 0`
- `items_created integer default 0`
- `review_cases_created integer default 0`
- `error_count integer default 0`
- `metrics jsonb null`

## Important Relationships

```text
owners -> camps -> bulls
venues -> events -> matches -> match_participants -> bulls
sources -> source_items -> evidence
source_items -> extraction_runs -> extraction_candidates
extraction_candidates -> entity_match_candidates
candidates/conflicts -> review_cases -> review_actions
agent_runs -> operational history
```

## Required Follow-Up Before Migration

BMI-P0-002 must finalize:
- enum/check constraint strategy
- RLS/auth ownership model
- merge/split identity history design
- claim-level provenance model between evidence and verified facts
- winner foreign-key migration ordering
- source item uniqueness rules
- review subject reference strategy
- indexes for search/entity resolution
- soft-delete/archive policy

No production schema should be created from this draft without that review.
