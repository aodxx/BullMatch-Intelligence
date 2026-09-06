alter table bullmatch.owners alter column verification_status set default 'UNVERIFIED';
alter table bullmatch.camps alter column verification_status set default 'UNVERIFIED';
alter table bullmatch.bulls alter column verification_status set default 'UNVERIFIED';
alter table bullmatch.venues alter column verification_status set default 'UNVERIFIED';
alter table bullmatch.events alter column verification_status set default 'UNVERIFIED';

create unique index matches_event_number_unique_idx
on bullmatch.matches(event_id, match_number)
where event_id is not null and match_number is not null;

create or replace function bullmatch.enforce_match_publication_integrity()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  participant_count integer;
  has_result boolean;
begin
  if new.published_at is null then
    return new;
  end if;

  if new.verification_status <> 'VERIFIED' then
    raise exception 'only VERIFIED matches may be published';
  end if;

  select count(*) into participant_count
  from bullmatch.match_participants mp
  where mp.match_id = new.id;

  if participant_count < 2 then
    raise exception 'published match requires at least two participants';
  end if;

  select exists(
    select 1 from bullmatch.match_results mr where mr.match_id = new.id
  ) into has_result;

  if not has_result then
    raise exception 'published match requires a match result';
  end if;

  return new;
end;
$$;
revoke all on function bullmatch.enforce_match_publication_integrity() from public, anon, authenticated;
grant execute on function bullmatch.enforce_match_publication_integrity() to service_role;

create trigger matches_publication_integrity_trg
before insert or update of published_at, verification_status
on bullmatch.matches
for each row execute function bullmatch.enforce_match_publication_integrity();

revoke all on all tables in schema bullmatch from public, anon, authenticated;
revoke all on all sequences in schema bullmatch from public, anon, authenticated;
revoke all on all tables in schema bullmatch_private from public, anon, authenticated;
revoke all on all sequences in schema bullmatch_private from public, anon, authenticated;

grant select on bullmatch.app_users to authenticated;
grant all on all tables in schema bullmatch to service_role;
grant all on all sequences in schema bullmatch to service_role;
grant all on all tables in schema bullmatch_private to service_role;
grant all on all sequences in schema bullmatch_private to service_role;
