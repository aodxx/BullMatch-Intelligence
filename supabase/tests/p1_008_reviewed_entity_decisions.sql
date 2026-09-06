-- BMI-P1-008 reviewed entity / duplicate decision regression assertions.
-- Behavioral fixtures are transaction-scoped and rolled back.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_review_entity_decision(uuid,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_review_entity_decision(uuid,jsonb)','EXECUTE') then
    raise exception 'browser roles can execute reviewed entity decisions directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_review_entity_decision(uuid,jsonb)','EXECUTE') then
    raise exception 'service_role cannot execute reviewed entity decisions';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_group uuid:=gen_random_uuid();
  v_bull uuid:=gen_random_uuid();
  v_case uuid:=gen_random_uuid();
  v_entity uuid:=gen_random_uuid();
  v_bad_entity uuid:=gen_random_uuid();
  v_dup_a uuid:=gen_random_uuid();
  v_dup_b uuid:=gen_random_uuid();
  v_link_command uuid:=gen_random_uuid();
  v_dup_command uuid:=gen_random_uuid();
  v_not_dup_command uuid:=gen_random_uuid();
  v_result jsonb;
  v_replay jsonb;
  v_decision text;
  v_status text;
  v_version bigint;
  v_count bigint;
  v_name_only_blocked boolean:=false;
  v_bull_name text;
BEGIN
  select user_id into v_actor from bullmatch.app_users
  where status='ACTIVE' and role in ('ADMIN','REVIEWER')
  order by case role when 'REVIEWER' then 1 else 2 end,created_at limit 1;
  if v_actor is null then raise exception 'test requires ACTIVE ADMIN/REVIEWER'; end if;

  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata)
  values(v_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.bulls(id,canonical_name,normalized_name,verification_status)
  values(v_bull,'ROLLBACK LINK TARGET '||left(v_bull::text,8),'rollback-link-'||v_bull::text,'VERIFIED');
  select canonical_name into v_bull_name from bullmatch.bulls where id=v_bull;

  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_case,'ENTITY_MATCH','OPEN','HIGH','BULL',jsonb_build_object('candidate_group_id',v_group),'rollback reviewed entity decisions','{}',1);

  insert into bullmatch_private.entity_match_candidates(
    id,candidate_group_id,entity_type,mention_ref,proposed_entity_id,match_score,signals,decision,policy_version,review_case_id
  ) values
    (v_entity,v_group,'BULL',jsonb_build_object('raw_name','เป้าหมายทดสอบ'),null,0.70,'{}','REVIEW','test-v1',v_case),
    (v_bad_entity,v_group,'BULL',jsonb_build_object('raw_name','ชื่อคล้ายอย่างเดียว'),null,0.95,jsonb_build_object('name_similarity',0.95),'REVIEW','test-v1',v_case);

  insert into bullmatch_private.duplicate_candidates(
    id,candidate_group_id,candidate_type,proposed_existing_id,score,signals,differing_fields,status,review_case_id
  ) values
    (v_dup_a,v_group,'ENTITY',v_bull,0.90,'{}','{}','REVIEW_REQUIRED',v_case),
    (v_dup_b,v_group,'ENTITY',v_bull,0.40,'{}','{}','REVIEW_REQUIRED',v_case);

  v_result:=public.bullmatch_api_review_entity_decision(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_link_command,'review_case_id',v_case,
    'action','LINK_ENTITY','expected_case_status','OPEN','expected_case_version',1,
    'note','ยืนยันจากภาพและบริบทคอก ไม่ใช้ชื่อเพียงอย่างเดียว',
    'payload',jsonb_build_object('candidate_id',v_entity,'canonical_entity_id',v_bull,'identity_basis','MULTI_SIGNAL')));
  if (v_result->>'canonical_mutation')::boolean then raise exception 'LINK_ENTITY unexpectedly reported canonical mutation'; end if;
  select decision into v_decision from bullmatch_private.entity_match_candidates where id=v_entity;
  if v_decision<>'CONFIRMED_LINK' then raise exception 'LINK_ENTITY did not confirm candidate'; end if;

  perform public.bullmatch_api_review_entity_decision(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_dup_command,'review_case_id',v_case,
    'action','CONFIRM_DUPLICATE','expected_case_status','OPEN','expected_case_version',2,
    'note','หลักฐานชี้ว่าเป็นรายการซ้ำ ไม่ใช่การรวมวัว','payload',jsonb_build_object('candidate_id',v_dup_a)));
  select status into v_status from bullmatch_private.duplicate_candidates where id=v_dup_a;
  if v_status<>'CONFIRMED_DUPLICATE' then raise exception 'duplicate confirmation failed'; end if;

  perform public.bullmatch_api_review_entity_decision(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_not_dup_command,'review_case_id',v_case,
    'action','MARK_NOT_DUPLICATE','expected_case_status','OPEN','expected_case_version',3,
    'note','ตรวจแล้วเป็นคนละรายการ','payload',jsonb_build_object('candidate_id',v_dup_b)));
  select status into v_status from bullmatch_private.duplicate_candidates where id=v_dup_b;
  if v_status<>'NOT_DUPLICATE' then raise exception 'not-duplicate decision failed'; end if;

  v_replay:=public.bullmatch_api_review_entity_decision(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_link_command,'review_case_id',v_case,
    'action','LINK_ENTITY','expected_case_status','OPEN','expected_case_version',1,
    'note','replay','payload',jsonb_build_object('candidate_id',v_entity,'canonical_entity_id',v_bull,'identity_basis','MULTI_SIGNAL')));
  if not (v_replay->>'idempotent_replay')::boolean then raise exception 'LINK_ENTITY replay was not idempotent'; end if;
  select case_version into v_version from bullmatch.review_cases where id=v_case;
  if v_version<>4 then raise exception 'idempotent replay changed case version'; end if;

  begin
    perform public.bullmatch_api_review_entity_decision(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_case,
      'action','LINK_ENTITY','expected_case_status','OPEN','expected_case_version',4,
      'note','ชื่อเหมือนกัน','payload',jsonb_build_object('candidate_id',v_bad_entity,'canonical_entity_id',v_bull,'identity_basis','NAME_ONLY')));
  exception when invalid_parameter_value then
    v_name_only_blocked:=true;
  end;
  if not v_name_only_blocked then raise exception 'Bull name-only entity link was not blocked'; end if;

  select canonical_name into v_decision from bullmatch.bulls where id=v_bull;
  if v_decision<>v_bull_name then raise exception 'candidate decisions mutated canonical Bull'; end if;

  select count(*) into v_count from bullmatch.review_actions
  where review_case_id=v_case and action in ('LINK_ENTITY','CONFIRM_DUPLICATE','MARK_NOT_DUPLICATE');
  if v_count<>3 then raise exception 'expected 3 entity decision review actions, got %',v_count; end if;
  select count(*) into v_count from bullmatch_private.audit_log
  where entity_id in (v_entity,v_dup_a,v_dup_b)
    and action in ('REVIEW_LINK_ENTITY','REVIEW_CONFIRM_DUPLICATE','REVIEW_MARK_NOT_DUPLICATE');
  if v_count<>3 then raise exception 'expected 3 entity decision audit rows, got %',v_count; end if;
END;
$$;
rollback;
