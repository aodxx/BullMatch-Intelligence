-- BMI-P1-001 shared Supabase tenancy isolation checks.
-- Run after bootstrap_bullmatch_shared_tenancy has been applied.

do $$
begin
  if not exists (select 1 from pg_namespace where nspname = 'bullmatch') then
    raise exception 'bullmatch schema is missing';
  end if;

  if not exists (select 1 from pg_namespace where nspname = 'bullmatch_private') then
    raise exception 'bullmatch_private schema is missing';
  end if;

  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'bullmatch'
      and c.relname = 'app_users'
      and c.relrowsecurity
  ) then
    raise exception 'RLS must be enabled on bullmatch.app_users';
  end if;

  if not has_schema_privilege('authenticated', 'bullmatch', 'USAGE') then
    raise exception 'authenticated must have USAGE on bullmatch';
  end if;

  if has_schema_privilege('authenticated', 'bullmatch_private', 'USAGE') then
    raise exception 'authenticated must not have USAGE on bullmatch_private';
  end if;

  if has_schema_privilege('anon', 'bullmatch_private', 'USAGE') then
    raise exception 'anon must not have USAGE on bullmatch_private';
  end if;

  if not has_table_privilege('authenticated', 'bullmatch.app_users', 'SELECT') then
    raise exception 'authenticated must be allowed to SELECT its membership subject to RLS';
  end if;

  if has_table_privilege('authenticated', 'bullmatch.app_users', 'INSERT')
     or has_table_privilege('authenticated', 'bullmatch.app_users', 'UPDATE')
     or has_table_privilege('authenticated', 'bullmatch.app_users', 'DELETE') then
    raise exception 'authenticated must not have direct write privileges on bullmatch.app_users';
  end if;

  if (select count(*) from pg_policies
      where schemaname = 'bullmatch'
        and tablename = 'app_users'
        and policyname = 'bullmatch_members_read_own_membership') <> 1 then
    raise exception 'expected own-membership RLS policy is missing or duplicated';
  end if;
end
$$;
