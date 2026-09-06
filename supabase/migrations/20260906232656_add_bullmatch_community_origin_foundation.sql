-- BMI-P1-013 — Community Contribution Intake Foundation
-- Production migration version reconciled: 20260906232656
-- Additive community-origin schema only. No contributor-facing RPC is exposed here.

create table bullmatch.contributor_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  handle text null,
  display_name text null,
  profile_visibility text not null default 'PRIVATE'
    check (profile_visibility in ('PRIVATE','PUBLIC')),
  status text not null default 'ACTIVE'
    check (status in ('ACTIVE','SUSPENDED','BANNED','LEFT')),
  contribution_started_at timestamptz null,
  public_bio text null,
  home_region_code text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table bullmatch.contributor_profiles enable row level security;
revoke all on bullmatch.contributor_profiles from public, anon, authenticated;
grant select, insert, update, delete on bullmatch.contributor_profiles to service_role;

create table bullmatch_private.community_submissions (
  id uuid primary key default gen_random_uuid(),
  submitter_user_id uuid not null references auth.users(id),
  submission_type text not null
    check (submission_type in (
      'PROGRAM','RESULT','BULL_IDENTITY','BULL_PROFILE','AFFILIATION','LINEAGE',
      'PHYSICAL_OBSERVATION','STYLE_OBSERVATION','COMPARISON','PAIRING',
      'CORRECTION','URL','OTHER'
    )),
  client_submission_key text null,
  request_fingerprint text null,
  status text not null default 'RECEIVED'
    check (status in (
      'RECEIVED','PARSING','CLAIMS_READY','REVIEW_REQUIRED','PARTIALLY_ACCEPTED',
      'ACCEPTED','REJECTED','WITHDRAWN','DUPLICATE','FAILED'
    )),
  target_hint jsonb not null default '{}'::jsonb,
  user_note text null,
  source_url text null,
  dedupe_fingerprint text null,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz null,
  moderation_metadata jsonb not null default '{}'::jsonb
);

alter table bullmatch_private.community_submissions enable row level security;

create unique index community_submissions_submitter_client_key_uidx
  on bullmatch_private.community_submissions(submitter_user_id, client_submission_key)
  where client_submission_key is not null;
create index community_submissions_submitter_submitted_idx
  on bullmatch_private.community_submissions(submitter_user_id, submitted_at desc);
create index community_submissions_status_submitted_idx
  on bullmatch_private.community_submissions(status, submitted_at);
create index community_submissions_dedupe_fingerprint_idx
  on bullmatch_private.community_submissions(dedupe_fingerprint)
  where dedupe_fingerprint is not null;

revoke all on bullmatch_private.community_submissions from public, anon, authenticated;
grant select, insert, update, delete on bullmatch_private.community_submissions to service_role;

-- Generalize evidence origin without fabricating external source items for community input.
alter table bullmatch_private.evidence
  add column submission_id uuid null
    references bullmatch_private.community_submissions(id) on delete set null,
  add column submitted_by_user_id uuid null references auth.users(id) on delete set null,
  add column captured_at timestamptz null,
  add column original_filename text null,
  add column mime_type text null,
  add column rights_basis text null,
  add column moderation_status text not null default 'PENDING';

alter table bullmatch_private.evidence drop constraint evidence_evidence_type_check;
alter table bullmatch_private.evidence
  add constraint evidence_evidence_type_check
  check (evidence_type in (
    'TEXT','IMAGE','VIDEO_SEGMENT','AUDIO_SEGMENT','PDF','METADATA',
    'OPERATOR_NOTE','URL_REFERENCE','OTHER'
  ));

alter table bullmatch_private.evidence
  add constraint evidence_moderation_status_check
  check (moderation_status in ('PENDING','ALLOWED','RESTRICTED','REJECTED'));

alter table bullmatch_private.evidence alter column source_item_id drop not null;
alter table bullmatch_private.evidence drop constraint evidence_source_item_id_fkey;
alter table bullmatch_private.evidence
  add constraint evidence_source_item_id_fkey
  foreign key (source_item_id)
  references bullmatch_private.source_items(id)
  on delete set null;

alter table bullmatch_private.evidence
  add constraint evidence_origin_check
  check (num_nonnulls(source_item_id, submission_id) >= 1) not valid;
alter table bullmatch_private.evidence validate constraint evidence_origin_check;

create index evidence_submission_id_idx
  on bullmatch_private.evidence(submission_id) where submission_id is not null;
create index evidence_submitted_by_user_id_idx
  on bullmatch_private.evidence(submitted_by_user_id) where submitted_by_user_id is not null;

-- Generalize atomic claim origin while preserving existing source-extraction rows.
alter table bullmatch_private.claims
  add column submission_id uuid null
    references bullmatch_private.community_submissions(id) on delete set null,
  add column created_by_user_id uuid null references auth.users(id) on delete set null,
  add column origin_type text not null default 'SOURCE_EXTRACTION',
  add column canonical_subject_id uuid null,
  add column value_fingerprint text null,
  add column supersedes_claim_id uuid null
    references bullmatch_private.claims(id) on delete set null,
  add column review_case_id uuid null references bullmatch.review_cases(id) on delete set null,
  add column updated_at timestamptz not null default now();

alter table bullmatch_private.claims
  add constraint claims_origin_type_check
  check (origin_type in (
    'SOURCE_EXTRACTION','COMMUNITY_SUBMISSION','OPERATOR_MANUAL','SYSTEM_DERIVED'
  ));

alter table bullmatch_private.claims alter column extraction_run_id drop not null;
alter table bullmatch_private.claims drop constraint claims_extraction_run_id_fkey;
alter table bullmatch_private.claims
  add constraint claims_extraction_run_id_fkey
  foreign key (extraction_run_id)
  references bullmatch_private.extraction_runs(id);

alter table bullmatch_private.claims
  add constraint claims_origin_integrity_check
  check (
    (origin_type='SOURCE_EXTRACTION' and extraction_run_id is not null)
    or (origin_type='COMMUNITY_SUBMISSION' and submission_id is not null and created_by_user_id is not null)
    or (origin_type='OPERATOR_MANUAL' and created_by_user_id is not null)
    or origin_type='SYSTEM_DERIVED'
  ) not valid;
alter table bullmatch_private.claims validate constraint claims_origin_integrity_check;

create index claims_submission_id_idx
  on bullmatch_private.claims(submission_id) where submission_id is not null;
create index claims_created_by_user_id_idx
  on bullmatch_private.claims(created_by_user_id) where created_by_user_id is not null;
create index claims_review_case_id_idx
  on bullmatch_private.claims(review_case_id) where review_case_id is not null;
create index claims_value_fingerprint_idx
  on bullmatch_private.claims(value_fingerprint) where value_fingerprint is not null;
