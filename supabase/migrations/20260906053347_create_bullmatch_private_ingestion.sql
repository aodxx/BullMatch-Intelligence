create table bullmatch_private.owner_private_details (
  owner_id uuid primary key references bullmatch.owners(id) on delete cascade,
  contact_private jsonb not null default '{}'::jsonb,
  notes_private text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table bullmatch_private.owner_private_details enable row level security;

create table bullmatch_private.sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source_type text not null check (source_type in ('WEBSITE','RSS','SITEMAP','API','YOUTUBE','OPERATOR_UPLOAD','SEARCH_DISCOVERY','OTHER')),
  base_url text null,
  connector_key text not null,
  access_method text not null,
  reliability_tier text not null default 'UNKNOWN' check (reliability_tier in ('OFFICIAL','HIGH','MEDIUM','LOW','UNKNOWN')),
  policy_status text not null default 'REVIEW_REQUIRED' check (policy_status in ('APPROVED','REVIEW_REQUIRED','BLOCKED')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','PAUSED','ERROR','RETIRED')),
  polling_enabled boolean not null default false,
  poll_interval_minutes integer null check (poll_interval_minutes is null or poll_interval_minutes >= 60),
  connector_config jsonb not null default '{}'::jsonb,
  secret_requirements jsonb not null default '[]'::jsonb,
  tags text[] not null default '{}',
  policy_notes text null,
  last_success_at timestamptz null,
  last_error_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index sources_status_polling_idx on bullmatch_private.sources(policy_status, status, polling_enabled);
create index sources_connector_key_idx on bullmatch_private.sources(connector_key);
alter table bullmatch_private.sources enable row level security;

create table bullmatch_private.source_runtime_state (
  source_id uuid primary key references bullmatch_private.sources(id) on delete cascade,
  cursor_strategy text not null default 'NONE' check (cursor_strategy in ('NONE','TIMESTAMP','EXTERNAL_ID','PAGE_TOKEN','ETAG','CUSTOM')),
  cursor jsonb null,
  last_attempt_at timestamptz null,
  last_success_at timestamptz null,
  consecutive_failures integer not null default 0 check (consecutive_failures >= 0),
  cooldown_until timestamptz null,
  last_health text null,
  last_error_code text null,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table bullmatch_private.source_runtime_state enable row level security;

create table bullmatch_private.source_items (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references bullmatch_private.sources(id) on delete cascade,
  external_id text null,
  canonical_url text null,
  dedupe_key text not null,
  published_at timestamptz null,
  retrieved_at timestamptz not null,
  content_hash text null,
  title text null,
  normalized_text text null,
  raw_metadata jsonb not null default '{}'::jsonb,
  connector_name text not null,
  connector_version text not null,
  ingestion_status text not null default 'DISCOVERED' check (ingestion_status in ('DISCOVERED','EXTRACTED','REVIEW_REQUIRED','PROCESSED','FAILED','IGNORED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_id, dedupe_key)
);
create unique index source_items_external_id_unique_idx on bullmatch_private.source_items(source_id, external_id) where external_id is not null;
create index source_items_source_published_idx on bullmatch_private.source_items(source_id, published_at desc);
create index source_items_content_hash_idx on bullmatch_private.source_items(content_hash);
alter table bullmatch_private.source_items enable row level security;

create table bullmatch_private.evidence (
  id uuid primary key default gen_random_uuid(),
  source_item_id uuid not null references bullmatch_private.source_items(id) on delete cascade,
  evidence_type text not null check (evidence_type in ('TEXT','IMAGE','VIDEO_SEGMENT','AUDIO_SEGMENT','PDF','METADATA','OPERATOR_NOTE','OTHER')),
  storage_ref text null,
  content_sha256 text null,
  text_excerpt text null,
  timestamp_start_seconds numeric null check (timestamp_start_seconds is null or timestamp_start_seconds >= 0),
  timestamp_end_seconds numeric null check (timestamp_end_seconds is null or timestamp_end_seconds >= 0),
  metadata jsonb not null default '{}'::jsonb,
  access_class text not null default 'INTERNAL' check (access_class in ('PUBLIC_REFERENCE','INTERNAL','RESTRICTED')),
  created_at timestamptz not null default now(),
  check (timestamp_start_seconds is null or timestamp_end_seconds is null or timestamp_end_seconds >= timestamp_start_seconds)
);
create index evidence_source_item_idx on bullmatch_private.evidence(source_item_id);
create index evidence_sha_idx on bullmatch_private.evidence(content_sha256);
alter table bullmatch_private.evidence enable row level security;

create table bullmatch_private.agent_runs (
  id uuid primary key default gen_random_uuid(),
  agent_type text not null,
  agent_version text not null,
  source_id uuid null references bullmatch_private.sources(id) on delete set null,
  correlation_id uuid null,
  started_at timestamptz not null,
  completed_at timestamptz null,
  status text not null check (status in ('RUNNING','SUCCEEDED','FAILED','PARTIAL','CANCELLED')),
  items_scanned integer not null default 0 check (items_scanned >= 0),
  items_created integer not null default 0 check (items_created >= 0),
  review_cases_created integer not null default 0 check (review_cases_created >= 0),
  error_count integer not null default 0 check (error_count >= 0),
  metrics jsonb not null default '{}'::jsonb,
  errors jsonb not null default '[]'::jsonb
);
create index agent_runs_type_started_idx on bullmatch_private.agent_runs(agent_type, started_at desc);
create index agent_runs_source_started_idx on bullmatch_private.agent_runs(source_id, started_at desc);
alter table bullmatch_private.agent_runs enable row level security;

create table bullmatch_private.extraction_runs (
  id uuid primary key default gen_random_uuid(),
  source_item_id uuid not null references bullmatch_private.source_items(id) on delete cascade,
  agent_run_id uuid null references bullmatch_private.agent_runs(id) on delete set null,
  model_provider text not null,
  model_name text not null,
  contract_version text not null,
  prompt_version text null,
  input_hash text not null,
  started_at timestamptz not null,
  completed_at timestamptz null,
  status text not null check (status in ('RUNNING','SUCCEEDED','FAILED','PARTIAL')),
  usage_metadata jsonb not null default '{}'::jsonb,
  error jsonb null,
  created_at timestamptz not null default now()
);
create index extraction_runs_source_item_idx on bullmatch_private.extraction_runs(source_item_id, created_at desc);
create index extraction_runs_input_hash_idx on bullmatch_private.extraction_runs(input_hash);
alter table bullmatch_private.extraction_runs enable row level security;

grant all on all tables in schema bullmatch_private to service_role;
grant all on all sequences in schema bullmatch_private to service_role;
