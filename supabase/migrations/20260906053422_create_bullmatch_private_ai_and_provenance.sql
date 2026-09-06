create table bullmatch_private.candidate_groups (
  id uuid primary key default gen_random_uuid(),
  group_type text not null check (group_type in ('MATCH','EVENT','ENTITY','SOURCE','OTHER')),
  source_item_id uuid null references bullmatch_private.source_items(id) on delete set null,
  extraction_run_id uuid null references bullmatch_private.extraction_runs(id) on delete set null,
  status text not null default 'CANDIDATE' check (status in ('CANDIDATE','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index candidate_groups_source_item_idx on bullmatch_private.candidate_groups(source_item_id);
create index candidate_groups_status_idx on bullmatch_private.candidate_groups(status, created_at);
alter table bullmatch_private.candidate_groups enable row level security;

create table bullmatch_private.claims (
  id uuid primary key default gen_random_uuid(),
  extraction_run_id uuid not null references bullmatch_private.extraction_runs(id) on delete cascade,
  candidate_group_id uuid null references bullmatch_private.candidate_groups(id) on delete set null,
  subject_type text not null,
  subject_ref jsonb not null default '{}'::jsonb,
  field_key text not null,
  value_json jsonb null,
  basis text not null check (basis in ('EXPLICIT','INFERRED','UNKNOWN')),
  confidence numeric(5,4) null check (confidence is null or confidence between 0 and 1),
  status text not null default 'PROPOSED' check (status in ('PROPOSED','REVIEW_REQUIRED','CORROBORATED','CONFLICT','REJECTED')),
  created_at timestamptz not null default now()
);
create index claims_extraction_run_idx on bullmatch_private.claims(extraction_run_id);
create index claims_candidate_group_idx on bullmatch_private.claims(candidate_group_id);
create index claims_subject_field_idx on bullmatch_private.claims(subject_type, field_key);
alter table bullmatch_private.claims enable row level security;

create table bullmatch_private.claim_evidence (
  claim_id uuid not null references bullmatch_private.claims(id) on delete cascade,
  evidence_id uuid not null references bullmatch_private.evidence(id) on delete cascade,
  relationship text not null default 'SUPPORTS' check (relationship in ('SUPPORTS','CONTRADICTS','CONTEXT')),
  created_at timestamptz not null default now(),
  primary key (claim_id, evidence_id, relationship)
);
create index claim_evidence_evidence_idx on bullmatch_private.claim_evidence(evidence_id);
alter table bullmatch_private.claim_evidence enable row level security;

create table bullmatch_private.entity_match_candidates (
  id uuid primary key default gen_random_uuid(),
  candidate_group_id uuid not null references bullmatch_private.candidate_groups(id) on delete cascade,
  claim_id uuid null references bullmatch_private.claims(id) on delete set null,
  entity_type text not null check (entity_type in ('BULL','OWNER','CAMP','VENUE','EVENT')),
  mention_ref jsonb not null default '{}'::jsonb,
  proposed_entity_id uuid null,
  match_score numeric(5,4) not null check (match_score between 0 and 1),
  signals jsonb not null default '{}'::jsonb,
  decision text not null check (decision in ('AUTO_LINK','REVIEW','NO_MATCH','NEW_ENTITY_CANDIDATE')),
  policy_version text not null,
  review_case_id uuid null references bullmatch.review_cases(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index entity_match_candidates_group_idx on bullmatch_private.entity_match_candidates(candidate_group_id);
create index entity_match_candidates_entity_idx on bullmatch_private.entity_match_candidates(entity_type, proposed_entity_id);
create index entity_match_candidates_review_idx on bullmatch_private.entity_match_candidates(review_case_id);
alter table bullmatch_private.entity_match_candidates enable row level security;

create table bullmatch_private.entity_source_mappings (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references bullmatch_private.sources(id) on delete cascade,
  entity_type text not null check (entity_type in ('BULL','OWNER','CAMP','VENUE','EVENT')),
  external_entity_key text not null,
  canonical_entity_id uuid not null,
  status text not null default 'VERIFIED' check (status in ('UNVERIFIED','VERIFIED','REVOKED')),
  review_action_id uuid null references bullmatch.review_actions(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_id, entity_type, external_entity_key)
);
create index entity_source_mappings_canonical_idx on bullmatch_private.entity_source_mappings(entity_type, canonical_entity_id);
alter table bullmatch_private.entity_source_mappings enable row level security;

create table bullmatch_private.duplicate_candidates (
  id uuid primary key default gen_random_uuid(),
  candidate_group_id uuid not null references bullmatch_private.candidate_groups(id) on delete cascade,
  candidate_type text not null check (candidate_type in ('MATCH','EVENT','ENTITY')),
  proposed_existing_id uuid null,
  score numeric(5,4) not null check (score between 0 and 1),
  signals jsonb not null default '{}'::jsonb,
  differing_fields jsonb not null default '{}'::jsonb,
  status text not null default 'CANDIDATE' check (status in ('CANDIDATE','REVIEW_REQUIRED','CONFIRMED_DUPLICATE','NOT_DUPLICATE')),
  review_case_id uuid null references bullmatch.review_cases(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index duplicate_candidates_group_idx on bullmatch_private.duplicate_candidates(candidate_group_id);
create index duplicate_candidates_review_idx on bullmatch_private.duplicate_candidates(review_case_id);
alter table bullmatch_private.duplicate_candidates enable row level security;

create table bullmatch_private.verification_results (
  id uuid primary key default gen_random_uuid(),
  candidate_group_id uuid not null references bullmatch_private.candidate_groups(id) on delete cascade,
  verification_version text not null,
  status text not null check (status in ('CORROBORATED','CONFLICT','INSUFFICIENT_EVIDENCE','REVIEW_REQUIRED','REJECTED')),
  confidence_summary numeric(5,4) null check (confidence_summary is null or confidence_summary between 0 and 1),
  summary jsonb not null default '{}'::jsonb,
  review_case_id uuid null references bullmatch.review_cases(id) on delete set null,
  created_at timestamptz not null default now()
);
create index verification_results_group_created_idx on bullmatch_private.verification_results(candidate_group_id, created_at desc);
create index verification_results_review_idx on bullmatch_private.verification_results(review_case_id);
alter table bullmatch_private.verification_results enable row level security;

create table bullmatch_private.fact_provenance (
  id uuid primary key default gen_random_uuid(),
  subject_type text not null,
  subject_id uuid not null,
  field_key text not null,
  value_fingerprint text null,
  claim_id uuid null references bullmatch_private.claims(id) on delete set null,
  evidence_id uuid null references bullmatch_private.evidence(id) on delete set null,
  review_action_id uuid null references bullmatch.review_actions(id) on delete set null,
  relationship text not null check (relationship in ('SUPPORTS','CONTRADICTS','DERIVED_FROM','MANUAL_ENTRY')),
  created_at timestamptz not null default now(),
  check (claim_id is not null or evidence_id is not null or review_action_id is not null)
);
create index fact_provenance_subject_idx on bullmatch_private.fact_provenance(subject_type, subject_id, field_key);
create index fact_provenance_claim_idx on bullmatch_private.fact_provenance(claim_id);
create index fact_provenance_evidence_idx on bullmatch_private.fact_provenance(evidence_id);
alter table bullmatch_private.fact_provenance enable row level security;

create table bullmatch_private.identity_events (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('BULL','OWNER','CAMP','VENUE','EVENT')),
  event_type text not null check (event_type in ('MERGE','SPLIT','ALIAS_VERIFIED','ALIAS_REVOKED','CANONICAL_RENAMED')),
  source_entity_ids uuid[] not null default '{}',
  target_entity_ids uuid[] not null default '{}',
  review_case_id uuid null references bullmatch.review_cases(id) on delete set null,
  review_action_id uuid null references bullmatch.review_actions(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index identity_events_entity_created_idx on bullmatch_private.identity_events(entity_type, created_at desc);
alter table bullmatch_private.identity_events enable row level security;

create table bullmatch_private.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_type text not null check (actor_type in ('USER','AGENT','SYSTEM')),
  actor_id text null,
  action text not null,
  entity_type text null,
  entity_id uuid null,
  correlation_id uuid null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_log_entity_created_idx on bullmatch_private.audit_log(entity_type, entity_id, created_at desc);
create index audit_log_correlation_idx on bullmatch_private.audit_log(correlation_id);
alter table bullmatch_private.audit_log enable row level security;

grant all on all tables in schema bullmatch_private to service_role;
grant all on all sequences in schema bullmatch_private to service_role;
