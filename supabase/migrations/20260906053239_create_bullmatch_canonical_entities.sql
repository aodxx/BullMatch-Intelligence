create extension if not exists pg_trgm with schema extensions;

create table bullmatch.owners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  province text null,
  district text null,
  notes text null,
  verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED')),
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index owners_normalized_name_idx on bullmatch.owners(normalized_name);
create index owners_normalized_name_trgm_idx on bullmatch.owners using gin (normalized_name extensions.gin_trgm_ops);
alter table bullmatch.owners enable row level security;

create table bullmatch.owner_aliases (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references bullmatch.owners(id) on delete cascade,
  alias text not null,
  normalized_alias text not null,
  alias_type text null,
  verified boolean not null default false,
  first_seen_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id, normalized_alias)
);
create index owner_aliases_normalized_idx on bullmatch.owner_aliases(normalized_alias);
create index owner_aliases_normalized_trgm_idx on bullmatch.owner_aliases using gin (normalized_alias extensions.gin_trgm_ops);
alter table bullmatch.owner_aliases enable row level security;

create table bullmatch.camps (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  owner_id uuid null references bullmatch.owners(id) on delete set null,
  province text null,
  district text null,
  notes text null,
  verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED')),
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index camps_normalized_name_idx on bullmatch.camps(normalized_name);
create index camps_owner_idx on bullmatch.camps(owner_id);
create index camps_normalized_name_trgm_idx on bullmatch.camps using gin (normalized_name extensions.gin_trgm_ops);
alter table bullmatch.camps enable row level security;

create table bullmatch.camp_aliases (
  id uuid primary key default gen_random_uuid(),
  camp_id uuid not null references bullmatch.camps(id) on delete cascade,
  alias text not null,
  normalized_alias text not null,
  alias_type text null,
  verified boolean not null default false,
  first_seen_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(camp_id, normalized_alias)
);
create index camp_aliases_normalized_idx on bullmatch.camp_aliases(normalized_alias);
create index camp_aliases_normalized_trgm_idx on bullmatch.camp_aliases using gin (normalized_alias extensions.gin_trgm_ops);
alter table bullmatch.camp_aliases enable row level security;

create table bullmatch.bulls (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  normalized_name text not null,
  birth_date date null,
  birth_date_precision text null check (birth_date_precision is null or birth_date_precision in ('DAY','MONTH','YEAR','ESTIMATED','UNKNOWN')),
  sex text not null default 'MALE' check (sex in ('MALE','UNKNOWN')),
  color_description text null,
  breed_description text null,
  lineage_notes text null,
  current_camp_id uuid null references bullmatch.camps(id) on delete set null,
  current_owner_id uuid null references bullmatch.owners(id) on delete set null,
  home_province text null,
  home_district text null,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','RESTING','RETIRED','DECEASED','UNKNOWN')),
  primary_image_ref text null,
  notes text null,
  verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED')),
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index bulls_normalized_name_idx on bullmatch.bulls(normalized_name);
create index bulls_current_camp_idx on bullmatch.bulls(current_camp_id);
create index bulls_current_owner_idx on bullmatch.bulls(current_owner_id);
create index bulls_normalized_name_trgm_idx on bullmatch.bulls using gin (normalized_name extensions.gin_trgm_ops);
alter table bullmatch.bulls enable row level security;

create table bullmatch.bull_aliases (
  id uuid primary key default gen_random_uuid(),
  bull_id uuid not null references bullmatch.bulls(id) on delete cascade,
  alias text not null,
  normalized_alias text not null,
  alias_type text null check (alias_type is null or alias_type in ('ALTERNATE_NAME','SPELLING','TITLE_PREFIX','SOURCE_LABEL','FORMER_NAME','OTHER')),
  verified boolean not null default false,
  first_seen_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(bull_id, normalized_alias)
);
create index bull_aliases_normalized_idx on bullmatch.bull_aliases(normalized_alias);
create index bull_aliases_normalized_trgm_idx on bullmatch.bull_aliases using gin (normalized_alias extensions.gin_trgm_ops);
alter table bullmatch.bull_aliases enable row level security;

create table bullmatch.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  province text null,
  district text null,
  address text null,
  latitude numeric(9,6) null check (latitude is null or latitude between -90 and 90),
  longitude numeric(9,6) null check (longitude is null or longitude between -180 and 180),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE','UNKNOWN')),
  verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED')),
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index venues_normalized_name_idx on bullmatch.venues(normalized_name);
create index venues_province_district_idx on bullmatch.venues(province, district);
create index venues_normalized_name_trgm_idx on bullmatch.venues using gin (normalized_name extensions.gin_trgm_ops);
alter table bullmatch.venues enable row level security;

create table bullmatch.venue_aliases (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references bullmatch.venues(id) on delete cascade,
  alias text not null,
  normalized_alias text not null,
  alias_type text null,
  verified boolean not null default false,
  first_seen_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(venue_id, normalized_alias)
);
create index venue_aliases_normalized_idx on bullmatch.venue_aliases(normalized_alias);
create index venue_aliases_normalized_trgm_idx on bullmatch.venue_aliases using gin (normalized_alias extensions.gin_trgm_ops);
alter table bullmatch.venue_aliases enable row level security;

create table bullmatch.events (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid null references bullmatch.venues(id) on delete set null,
  name text null,
  event_date date null,
  start_time timestamptz null,
  date_precision text not null default 'UNKNOWN' check (date_precision in ('EXACT','DATE_ONLY','MONTH_ONLY','YEAR_ONLY','ESTIMATED','UNKNOWN')),
  status text not null default 'SCHEDULED' check (status in ('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED','UNKNOWN')),
  notes text null,
  verification_status text not null default 'VERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED')),
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index events_venue_date_idx on bullmatch.events(venue_id, event_date);
create index events_event_date_idx on bullmatch.events(event_date);
alter table bullmatch.events enable row level security;

grant all on all tables in schema bullmatch to service_role;
grant all on all sequences in schema bullmatch to service_role;
