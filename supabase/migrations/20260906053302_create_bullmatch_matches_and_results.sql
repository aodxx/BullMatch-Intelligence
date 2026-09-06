create table bullmatch.matches (
  id uuid primary key default gen_random_uuid(),
  event_id uuid null references bullmatch.events(id) on delete set null,
  venue_id uuid null references bullmatch.venues(id) on delete set null,
  match_date timestamptz null,
  date_precision text not null default 'UNKNOWN' check (date_precision in ('EXACT','DATE_ONLY','ESTIMATED','UNKNOWN')),
  match_number integer null check (match_number is null or match_number > 0),
  status text not null default 'SCHEDULED' check (status in ('SCHEDULED','COMPLETED','CANCELLED','NO_RESULT','UNKNOWN')),
  duration_seconds integer null check (duration_seconds is null or duration_seconds >= 0),
  result_detail text null,
  verification_status text not null default 'UNVERIFIED' check (verification_status in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED')),
  published_at timestamptz null,
  archived_at timestamptz null,
  archive_reason text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index matches_match_date_idx on bullmatch.matches(match_date);
create index matches_venue_date_idx on bullmatch.matches(venue_id, match_date);
create index matches_event_number_idx on bullmatch.matches(event_id, match_number);
create index matches_bull_publication_idx on bullmatch.matches(published_at) where published_at is not null;
alter table bullmatch.matches enable row level security;

create table bullmatch.match_participants (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references bullmatch.matches(id) on delete cascade,
  bull_id uuid not null references bullmatch.bulls(id),
  side text null check (side is null or side in ('A','B','OTHER')),
  camp_id_snapshot uuid null references bullmatch.camps(id) on delete set null,
  owner_id_snapshot uuid null references bullmatch.owners(id) on delete set null,
  weight_kg numeric(7,2) null check (weight_kg is null or weight_kg > 0),
  age_months_estimate integer null check (age_months_estimate is null or age_months_estimate >= 0),
  display_name_snapshot text not null,
  participant_result text null check (participant_result is null or participant_result in ('WIN','LOSS','DRAW','NO_RESULT','CANCELLED','UNKNOWN')),
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(match_id, bull_id)
);
create unique index match_participants_side_unique_idx on bullmatch.match_participants(match_id, side) where side in ('A','B');
create index match_participants_bull_idx on bullmatch.match_participants(bull_id);
create index match_participants_bull_match_idx on bullmatch.match_participants(bull_id, match_id);
alter table bullmatch.match_participants enable row level security;

create table bullmatch.match_results (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null unique references bullmatch.matches(id) on delete cascade,
  result_type text not null check (result_type in ('WIN','DRAW','NO_RESULT','CANCELLED','UNKNOWN')),
  winner_participant_id uuid null references bullmatch.match_participants(id),
  result_reason text null,
  verified_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((result_type = 'WIN' and winner_participant_id is not null) or (result_type <> 'WIN' and winner_participant_id is null))
);
alter table bullmatch.match_results enable row level security;

create or replace function bullmatch.enforce_match_result_winner_integrity()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  participant_match_id uuid;
begin
  if new.winner_participant_id is null then
    return new;
  end if;

  select mp.match_id into participant_match_id
  from bullmatch.match_participants mp
  where mp.id = new.winner_participant_id;

  if participant_match_id is null or participant_match_id <> new.match_id then
    raise exception 'winner participant must belong to the same match';
  end if;

  return new;
end;
$$;
revoke all on function bullmatch.enforce_match_result_winner_integrity() from public, anon, authenticated;
grant execute on function bullmatch.enforce_match_result_winner_integrity() to service_role;

create trigger match_results_winner_integrity_trg
before insert or update of match_id, winner_participant_id, result_type
on bullmatch.match_results
for each row execute function bullmatch.enforce_match_result_winner_integrity();

grant all on all tables in schema bullmatch to service_role;
grant all on all sequences in schema bullmatch to service_role;
