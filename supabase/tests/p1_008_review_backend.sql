-- BMI-P1-008 review backend foundation assertions
-- Structural checks are read-only. Behavioral fixtures are wrapped in a transaction and rolled back.

DO $$
DECLARE
  bad_count integer;
BEGIN
  if not exists (
    select 1 from information_schema.tables
    where table_schema='bullmatch_private' and table_name='review_case_claims'
  ) then
    raise exception 'review_case_claims mapping table missing';
  end if;

  if not (select relrowsecurity from pg_class where oid='bullmatch_private.review_case_claims'::regclass) then
    raise exception 'review_case_claims RLS is not enabled';
  end if;

  if has_function_privilege('anon','public.bullmatch_api_review_query(uuid,text,uuid,integer,integer)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_review_query(uuid,text,uuid,integer,integer)','EXECUTE') then
    raise exception 'browser roles can execute reviewer query bridge directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_review_query(uuid,text,uuid,integer,integer)','EXECUTE') then
    raise exception 'service_role cannot execute reviewer query bridge';
  end if;

  if has_function_privilege('anon','public.bullmatch_api_review_command(uuid,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_review_command(uuid,jsonb)','EXECUTE') then
    raise exception 'browser roles can execute reviewer command bridge directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_review_command(uuid,jsonb)','EXECUTE') then
    raise exception 'service_role cannot execute reviewer command bridge';
  end if;

  select count(*) into bad_count
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in ('bullmatch_api_review_query','bullmatch_api_review_command')
    and (not p.prosecdef or coalesce(array_to_string(p.proconfig,','),'') not like '%search_path=%');
  if bad_count <> 0 then
    raise exception 'review bridge must be SECURITY DEFINER with fixed search_path';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='bullmatch_private.claims'::regclass
      and conname='claims_status_check'
      and pg_get_constraintdef(oid) like '%VERIFIED%'
      and pg_get_constraintdef(oid) like '%SUPERSEDED%'
      and pg_get_constraintdef(oid) like '%WITHDRAWN%'
  ) then
    raise exception 'claim lifecycle constraint is not aligned to Contribution & Trust contract';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_case uuid := gen_random_uuid();
  v_cmd uuid := gen_random_uuid();
  v_first jsonb;
  v_replay jsonb;
  v_stale_blocked boolean := false;
BEGIN
  select user_id into v_actor
  from bullmatch.app_users
  where status='ACTIVE' and role in ('ADMIN','REVIEWER')
  order by created_at
  limit 1;

  if v_actor is null then
    raise exception 'test requires one existing ACTIVE ADMIN or REVIEWER membership';
  end if;

  insert into bullmatch.review_cases(
    id,case_type,status,priority,subject_type,subject_ref,summary,context
  ) values (
    v_case,'DATA_QUALITY','OPEN','LOW','TEST',jsonb_build_object('rollback_only',true),
    'BMI-P1-008 rollback-only validation','{}'::jsonb
  );

  v_first := public.bullmatch_api_review_command(v_actor,jsonb_build_object(
    'schema_version','1.0.0',
    'command_id',v_cmd,
    'review_case_id',v_case,
    'action','CLAIM',
    'expected_case_status','OPEN',
    'expected_case_version',1,
    'payload','{}'::jsonb
  ));

  if coalesce((v_first->>'idempotent_replay')::boolean,true) then
    raise exception 'first command was incorrectly treated as replay';
  end if;
  if (v_first->>'case_version')::bigint <> 2 then
    raise exception 'CLAIM did not increment case_version to 2';
  end if;

  v_replay := public.bullmatch_api_review_command(v_actor,jsonb_build_object(
    'schema_version','1.0.0',
    'command_id',v_cmd,
    'review_case_id',v_case,
    'action','CLAIM',
    'expected_case_status','OPEN',
    'expected_case_version',1,
    'payload','{}'::jsonb
  ));

  if not coalesce((v_replay->>'idempotent_replay')::boolean,false) then
    raise exception 'duplicate command did not replay idempotently';
  end if;

  begin
    perform public.bullmatch_api_review_command(v_actor,jsonb_build_object(
      'schema_version','1.0.0',
      'command_id',gen_random_uuid(),
      'review_case_id',v_case,
      'action','COMMENT',
      'expected_case_status','OPEN',
      'expected_case_version',1,
      'payload','{}'::jsonb,
      'note','stale-write test'
    ));
  exception when serialization_failure then
    v_stale_blocked := true;
  end;

  if not v_stale_blocked then
    raise exception 'stale optimistic write was not rejected';
  end if;

  if (select count(*) from bullmatch.review_actions where command_id=v_cmd) <> 1 then
    raise exception 'idempotent command created duplicate review_actions';
  end if;
  if (select count(*) from bullmatch_private.audit_log where correlation_id=v_cmd) <> 1 then
    raise exception 'review command audit record missing or duplicated';
  end if;
END;
$$;
rollback;
