-- BMI-P1-008 selected EDIT regression. Transaction-scoped fixtures only.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_review_edit_metadata(uuid,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_review_edit_metadata(uuid,jsonb)','EXECUTE') then
    raise exception 'browser roles can execute review EDIT directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_review_edit_metadata(uuid,jsonb)','EXECUTE') then
    raise exception 'service_role cannot execute review EDIT';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_case uuid:=gen_random_uuid();
  v_command uuid:=gen_random_uuid();
  v_result jsonb;
  v_replay jsonb;
  v_version bigint;
  v_priority text;
  v_summary text;
  v_count bigint;
  v_forbidden boolean:=false;
  v_terminal boolean:=false;
  v_bull_count_before bigint;
  v_bull_count_after bigint;
  v_terminal_case uuid:=gen_random_uuid();
BEGIN
  select user_id into v_actor from bullmatch.app_users
  where status='ACTIVE' and role in ('ADMIN','REVIEWER')
  order by case role when 'REVIEWER' then 1 else 2 end,created_at limit 1;
  if v_actor is null then raise exception 'test requires ACTIVE ADMIN/REVIEWER'; end if;

  select count(*) into v_bull_count_before from bullmatch.bulls;

  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_case,'DATA_QUALITY','OPEN','NORMAL','BULL','{}','rollback edit summary','{}',1);

  v_result:=public.bullmatch_api_review_edit_metadata(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,
    'expected_case_status','OPEN','expected_case_version',1,
    'note','ปรับลำดับคิวและสรุปเท่านั้น ไม่แตะข้อมูลข้อเท็จจริง',
    'patch',jsonb_build_object('priority','HIGH','summary','rollback edited review routing metadata')
  ));
  if (v_result->>'canonical_mutation')::boolean then raise exception 'EDIT unexpectedly reported canonical mutation'; end if;
  select priority,summary,case_version into v_priority,v_summary,v_version from bullmatch.review_cases where id=v_case;
  if v_priority<>'HIGH' or v_summary<>'rollback edited review routing metadata' or v_version<>2 then
    raise exception 'review metadata EDIT did not apply expected values/version';
  end if;

  v_replay:=public.bullmatch_api_review_edit_metadata(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,
    'expected_case_status','OPEN','expected_case_version',1,
    'note','replay','patch',jsonb_build_object('priority','HIGH')
  ));
  if not (v_replay->>'idempotent_replay')::boolean then raise exception 'EDIT replay was not idempotent'; end if;
  select case_version into v_version from bullmatch.review_cases where id=v_case;
  if v_version<>2 then raise exception 'EDIT replay changed case version'; end if;

  begin
    perform public.bullmatch_api_review_edit_metadata(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_case,
      'expected_case_status','OPEN','expected_case_version',2,'note','must block',
      'patch',jsonb_build_object('subject_ref',jsonb_build_object('canonical_subject_id',gen_random_uuid()))));
  exception when feature_not_supported then v_forbidden:=true; end;
  if not v_forbidden then raise exception 'EDIT allowed forbidden subject_ref mutation'; end if;

  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version,resolved_at,resolved_by)
  values(v_terminal_case,'DATA_QUALITY','RESOLVED','NORMAL','BULL','{}','rollback terminal edit gate','{}',1,now(),v_actor);
  begin
    perform public.bullmatch_api_review_edit_metadata(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_terminal_case,
      'expected_case_status','RESOLVED','expected_case_version',1,'note','must block',
      'patch',jsonb_build_object('priority','LOW')));
  exception when invalid_parameter_value then v_terminal:=true; end;
  if not v_terminal then raise exception 'EDIT allowed terminal review case mutation'; end if;

  select count(*) into v_count from bullmatch.review_actions where review_case_id=v_case and action='EDIT';
  if v_count<>1 then raise exception 'expected exactly one EDIT review action'; end if;
  select count(*) into v_count from bullmatch_private.audit_log where action='REVIEW_EDIT_METADATA' and entity_id=v_case;
  if v_count<>1 then raise exception 'expected exactly one REVIEW_EDIT_METADATA audit row'; end if;

  select count(*) into v_bull_count_after from bullmatch.bulls;
  if v_bull_count_after<>v_bull_count_before then raise exception 'review metadata EDIT changed Bull row count'; end if;
END;
$$;
rollback;
