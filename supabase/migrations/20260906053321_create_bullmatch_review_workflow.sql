create table bullmatch.review_cases (
  id uuid primary key default gen_random_uuid(),
  case_type text not null check (case_type in ('NEW_MATCH','NEW_ENTITY','ENTITY_MATCH','DUPLICATE_MATCH','CONFLICTING_RESULT','CONFLICTING_DATE','LOW_CONFIDENCE','SOURCE_APPROVAL','MERGE_SPLIT','DATA_QUALITY','OTHER')),
  status text not null default 'OPEN' check (status in ('OPEN','IN_REVIEW','RESOLVED','REJECTED','CANCELLED')),
  priority text not null default 'NORMAL' check (priority in ('LOW','NORMAL','HIGH','URGENT')),
  subject_type text not null,
  subject_ref jsonb not null,
  summary text not null,
  context jsonb not null default '{}'::jsonb,
  assigned_to uuid null references bullmatch.app_users(user_id) on delete set null,
  case_version bigint not null default 1 check (case_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz null,
  resolved_by uuid null references bullmatch.app_users(user_id) on delete set null
);
create index review_cases_queue_idx on bullmatch.review_cases(status, priority, created_at);
create index review_cases_assigned_idx on bullmatch.review_cases(assigned_to);
create index review_cases_case_type_idx on bullmatch.review_cases(case_type, status);
alter table bullmatch.review_cases enable row level security;

create table bullmatch.review_actions (
  id uuid primary key default gen_random_uuid(),
  review_case_id uuid not null references bullmatch.review_cases(id) on delete cascade,
  actor_id uuid not null references bullmatch.app_users(user_id),
  command_id uuid not null unique,
  action text not null check (action in ('CLAIM','UNCLAIM','APPROVE','REJECT','EDIT','LINK_ENTITY','CREATE_ENTITY','CONFIRM_DUPLICATE','MARK_NOT_DUPLICATE','RESOLVE_CONFLICT','MERGE','SPLIT','COMMENT','REOPEN')),
  expected_case_version bigint null check (expected_case_version is null or expected_case_version > 0),
  case_version_before bigint null check (case_version_before is null or case_version_before > 0),
  case_version_after bigint null check (case_version_after is null or case_version_after > 0),
  before_value jsonb null,
  after_value jsonb null,
  notes text null,
  created_at timestamptz not null default now()
);
create index review_actions_case_created_idx on bullmatch.review_actions(review_case_id, created_at);
create index review_actions_actor_created_idx on bullmatch.review_actions(actor_id, created_at);
alter table bullmatch.review_actions enable row level security;

grant all on all tables in schema bullmatch to service_role;
grant all on all sequences in schema bullmatch to service_role;
