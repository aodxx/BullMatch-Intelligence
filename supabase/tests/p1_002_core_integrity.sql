-- BMI-P1-002 core database integrity checks.
-- Intended to run against an empty/non-production test context.
-- The block inserts temporary rows and cleans them before returning.

do $$
declare
  bad_rls integer;
  private_browser_grants integer;
  unexpected_bullmatch_browser_grants integer;
  owner_id uuid := gen_random_uuid();
  bull_a uuid := gen_random_uuid();
  bull_b uuid := gen_random_uuid();
  match_a uuid := gen_random_uuid();
  match_b uuid := gen_random_uuid();
  p_a uuid := gen_random_uuid();
  p_b uuid := gen_random_uuid();
  p_other uuid := gen_random_uuid();
  source_id uuid := gen_random_uuid();
  winner_guard_fired boolean := false;
  publication_guard_fired boolean := false;
  dedupe_guard_fired boolean := false;
begin
  select count(*) into bad_rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname in ('bullmatch','bullmatch_private')
    and c.relkind = 'r'
    and not c.relrowsecurity;
  if bad_rls <> 0 then
    raise exception 'all BullMatch tables must have RLS enabled; failures=%', bad_rls;
  end if;

  select count(*) into private_browser_grants
  from information_schema.table_privileges
  where table_schema = 'bullmatch_private'
    and grantee in ('anon','authenticated');
  if private_browser_grants <> 0 then
    raise exception 'browser roles have unexpected private table grants: %', private_browser_grants;
  end if;

  select count(*) into unexpected_bullmatch_browser_grants
  from information_schema.table_privileges
  where table_schema = 'bullmatch'
    and grantee in ('anon','authenticated')
    and not (table_name = 'app_users' and grantee = 'authenticated' and privilege_type = 'SELECT');
  if unexpected_bullmatch_browser_grants <> 0 then
    raise exception 'unexpected browser grants in bullmatch schema: %', unexpected_bullmatch_browser_grants;
  end if;

  if (select column_default from information_schema.columns
      where table_schema='bullmatch' and table_name='bulls' and column_name='verification_status')
     not like '%UNVERIFIED%' then
    raise exception 'bull canonical default must be UNVERIFIED';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema='bullmatch' and table_name='review_cases'
      and column_name='case_version' and is_nullable='NO'
  ) then
    raise exception 'review_cases.case_version is missing';
  end if;

  if not exists (
    select 1 from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace n on n.oid = rel.relnamespace
    where n.nspname='bullmatch' and rel.relname='review_actions'
      and con.contype='u'
      and pg_get_constraintdef(con.oid) like '%command_id%'
  ) then
    raise exception 'review_actions.command_id unique constraint is missing';
  end if;

  insert into bullmatch.owners(id, name, normalized_name) values (owner_id, 'Test Owner', 'test owner');
  insert into bullmatch.bulls(id, canonical_name, normalized_name) values
    (bull_a, 'Test Bull A', 'test bull a'),
    (bull_b, 'Test Bull B', 'test bull b');
  insert into bullmatch.matches(id, verification_status) values
    (match_a, 'UNVERIFIED'),
    (match_b, 'UNVERIFIED');
  insert into bullmatch.match_participants(id, match_id, bull_id, side, display_name_snapshot) values
    (p_a, match_a, bull_a, 'A', 'Test Bull A'),
    (p_b, match_a, bull_b, 'B', 'Test Bull B'),
    (p_other, match_b, bull_a, 'A', 'Test Bull A');

  begin
    insert into bullmatch.match_results(match_id, result_type, winner_participant_id)
    values (match_a, 'WIN', p_other);
  exception when others then
    winner_guard_fired := true;
  end;
  if not winner_guard_fired then
    raise exception 'winner same-match guard did not fire';
  end if;

  insert into bullmatch.match_results(match_id, result_type, winner_participant_id)
  values (match_a, 'WIN', p_a);

  begin
    update bullmatch.matches set published_at = now() where id = match_a;
  exception when others then
    publication_guard_fired := true;
  end;
  if not publication_guard_fired then
    raise exception 'publication guard did not reject unverified match';
  end if;

  update bullmatch.matches set verification_status = 'VERIFIED' where id = match_a;
  update bullmatch.matches set published_at = now() where id = match_a;

  insert into bullmatch_private.sources(id, name, source_type, connector_key, access_method)
  values (source_id, 'Test Source', 'WEBSITE', 'test', 'PUBLIC_PAGE');
  insert into bullmatch_private.source_items(source_id, dedupe_key, retrieved_at, connector_name, connector_version)
  values (source_id, 'same-key', now(), 'test', '1');

  begin
    insert into bullmatch_private.source_items(source_id, dedupe_key, retrieved_at, connector_name, connector_version)
    values (source_id, 'same-key', now(), 'test', '1');
  exception when unique_violation then
    dedupe_guard_fired := true;
  end;
  if not dedupe_guard_fired then
    raise exception 'source dedupe constraint did not fire';
  end if;

  delete from bullmatch_private.sources where id = source_id;
  delete from bullmatch.matches where id in (match_a, match_b);
  delete from bullmatch.bulls where id in (bull_a, bull_b);
  delete from bullmatch.owners where id = owner_id;
end
$$;
