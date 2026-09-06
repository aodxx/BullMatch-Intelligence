-- BMI-P1-004 authorization assertions
-- Safe to run repeatedly. No production rows are created.

DO $$
DECLARE
  bad_count integer;
  private_usage boolean;
  helper_is_definer boolean;
BEGIN
  select count(*) into bad_count
  from information_schema.role_table_grants
  where table_schema='bullmatch'
    and grantee='authenticated'
    and privilege_type <> 'SELECT';
  if bad_count <> 0 then
    raise exception 'authenticated has non-SELECT BullMatch table grants';
  end if;

  select has_schema_privilege('authenticated','bullmatch_private','USAGE') into private_usage;
  if private_usage then
    raise exception 'authenticated unexpectedly has bullmatch_private USAGE';
  end if;

  select p.prosecdef into helper_is_definer
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='bullmatch' and p.proname='has_active_role';
  if coalesce(helper_is_definer, true) then
    raise exception 'has_active_role must be SECURITY INVOKER';
  end if;

  if not has_function_privilege('authenticated','bullmatch.has_active_role(text[])','EXECUTE') then
    raise exception 'authenticated cannot execute has_active_role';
  end if;

  if has_function_privilege('anon','bullmatch.has_active_role(text[])','EXECUTE') then
    raise exception 'anon unexpectedly can execute has_active_role';
  end if;

  select count(*) into bad_count
  from pg_policies
  where schemaname in ('bullmatch','bullmatch_private')
    and (coalesce(qual,'') ilike '%user_meta%' or coalesce(with_check,'') ilike '%user_meta%');
  if bad_count <> 0 then
    raise exception 'RLS policy references user-editable metadata';
  end if;

  select count(*) into bad_count
  from pg_policies
  where schemaname='bullmatch'
    and tablename in ('owners','owner_aliases','camps','camp_aliases','bulls','bull_aliases','venues','venue_aliases','events','matches','match_participants','match_results')
    and cmd='SELECT'
    and roles @> array['authenticated']::name[];
  if bad_count <> 12 then
    raise exception 'expected exactly one authenticated SELECT policy on each public domain table, found % total', bad_count;
  end if;

  select count(*) into bad_count
  from pg_policies
  where schemaname='bullmatch'
    and tablename in ('review_cases','review_actions')
    and cmd='SELECT'
    and roles @> array['authenticated']::name[];
  if bad_count <> 2 then
    raise exception 'review read policy count mismatch';
  end if;
END;
$$;

-- Non-member authenticated request must resolve to no BullMatch role/membership.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
DO $$
BEGIN
  if bullmatch.has_active_role(array['ADMIN','REVIEWER','VIEWER']) then
    raise exception 'non-member unexpectedly has BullMatch role';
  end if;
  if exists (select 1 from bullmatch.app_users) then
    raise exception 'non-member unexpectedly sees app membership';
  end if;
END;
$$;
rollback;
