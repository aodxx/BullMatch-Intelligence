-- BMI-P1-008 guarded CREATE_ENTITY regression assertions.
-- All fixtures are transaction-scoped and rolled back.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_review_create_entity(uuid,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_review_create_entity(uuid,jsonb)','EXECUTE') then
    raise exception 'browser roles can execute reviewed entity creation directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_review_create_entity(uuid,jsonb)','EXECUTE') then
    raise exception 'service_role cannot execute reviewed entity creation';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_group uuid:=gen_random_uuid();
  v_case uuid:=gen_random_uuid();
  v_candidate uuid:=gen_random_uuid();
  v_command uuid:=gen_random_uuid();
  v_result jsonb;
  v_replay jsonb;
  v_bull uuid;
  v_version bigint;
  v_status text;
  v_count bigint;

  v_missing_group uuid:=gen_random_uuid();
  v_missing_case uuid:=gen_random_uuid();
  v_missing_candidate uuid:=gen_random_uuid();
  v_missing_blocked boolean:=false;

  v_dup_group uuid:=gen_random_uuid();
  v_dup_case uuid:=gen_random_uuid();
  v_dup_candidate uuid:=gen_random_uuid();
  v_dup_blocked boolean:=false;

  v_name_group uuid:=gen_random_uuid();
  v_name_case uuid:=gen_random_uuid();
  v_name_candidate uuid:=gen_random_uuid();
  v_existing_bull uuid:=gen_random_uuid();
  v_name_blocked boolean:=false;

  v_weak_group uuid:=gen_random_uuid();
  v_weak_case uuid:=gen_random_uuid();
  v_weak_candidate uuid:=gen_random_uuid();
  v_weak_blocked boolean:=false;
BEGIN
  select user_id into v_actor from bullmatch.app_users
  where status='ACTIVE' and role='ADMIN'
  order by created_at limit 1;
  if v_actor is null then raise exception 'test requires ACTIVE ADMIN'; end if;

  -- Successful reviewed creation: candidate and duplicate searches explicitly completed,
  -- no unresolved duplicate exists, and creation basis is stronger than name-only.
  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata)
  values(v_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_case,'NEW_ENTITY','OPEN','HIGH','BULL',jsonb_build_object('candidate_group_id',v_group),'rollback guarded Bull creation','{}',1);
  insert into bullmatch_private.entity_match_candidates(
    id,candidate_group_id,entity_type,mention_ref,proposed_entity_id,match_score,signals,decision,policy_version,review_case_id
  ) values(
    v_candidate,v_group,'BULL',jsonb_build_object('raw_name','โหนดทดสอบสร้างใหม่ '||left(v_candidate::text,8)),null,0.25,
    jsonb_build_object('candidate_search_completed',true,'duplicate_search_completed',true,'search_policy_version','test-search-v1'),
    'NEW_ENTITY_CANDIDATE','test-v1',v_case
  );

  v_result:=public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,
    'expected_case_status','OPEN','expected_case_version',1,
    'note','ตรวจ candidate และ duplicate แล้ว สร้าง identity ใหม่แบบ UNVERIFIED เท่านั้น',
    'payload',jsonb_build_object('candidate_id',v_candidate,'creation_basis','MULTI_SIGNAL')
  ));
  v_bull:=(v_result->>'entity_id')::uuid;
  if coalesce((v_result->>'canonical_mutation')::boolean,false) is not true then raise exception 'CREATE_ENTITY did not report canonical identity creation'; end if;
  if v_result->>'verification_status'<>'UNVERIFIED' then raise exception 'new Bull was not reported UNVERIFIED'; end if;

  select verification_status into v_status from bullmatch.bulls where id=v_bull;
  if v_status<>'UNVERIFIED' then raise exception 'new Bull must remain UNVERIFIED'; end if;
  select count(*) into v_count from bullmatch.bulls
  where id=v_bull and current_owner_id is null and current_camp_id is null
    and lineage_notes is null and primary_image_ref is null
    and color_description is null and breed_description is null;
  if v_count<>1 then raise exception 'guarded creation wrote fields outside identity-only slice'; end if;

  select count(*) into v_count from bullmatch_private.entity_match_candidates
  where id=v_candidate and proposed_entity_id=v_bull and decision='CONFIRMED_LINK';
  if v_count<>1 then raise exception 'created Bull was not linked back to candidate'; end if;

  v_replay:=public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,
    'expected_case_status','OPEN','expected_case_version',1,
    'note','idempotent replay','payload',jsonb_build_object('candidate_id',v_candidate,'creation_basis','MULTI_SIGNAL')
  ));
  if not (v_replay->>'idempotent_replay')::boolean then raise exception 'CREATE_ENTITY replay was not idempotent'; end if;
  if (v_replay->>'entity_id')::uuid<>v_bull then raise exception 'CREATE_ENTITY replay returned a different Bull'; end if;
  select case_version into v_version from bullmatch.review_cases where id=v_case;
  if v_version<>2 then raise exception 'idempotent replay changed case version'; end if;
  select count(*) into v_count from bullmatch.review_actions where review_case_id=v_case and action='CREATE_ENTITY';
  if v_count<>1 then raise exception 'expected exactly one CREATE_ENTITY review action'; end if;
  select count(*) into v_count from bullmatch_private.audit_log where action='REVIEW_CREATE_ENTITY' and entity_id=v_bull;
  if v_count<>1 then raise exception 'expected exactly one REVIEW_CREATE_ENTITY audit row'; end if;

  -- Missing duplicate-search completion must block creation.
  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata) values(v_missing_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_missing_case,'NEW_ENTITY','OPEN','NORMAL','BULL','{}','rollback missing search gate','{}',1);
  insert into bullmatch_private.entity_match_candidates(id,candidate_group_id,entity_type,mention_ref,match_score,signals,decision,policy_version,review_case_id)
  values(v_missing_candidate,v_missing_group,'BULL',jsonb_build_object('raw_name','วัวค้นหาไม่ครบ '||left(v_missing_candidate::text,8)),0.2,
    jsonb_build_object('candidate_search_completed',true,'search_policy_version','test-search-v1'),'NEW_ENTITY_CANDIDATE','test-v1',v_missing_case);
  begin
    perform public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_missing_case,
      'expected_case_status','OPEN','expected_case_version',1,'note','should block',
      'payload',jsonb_build_object('candidate_id',v_missing_candidate,'creation_basis','MULTI_SIGNAL')));
  exception when invalid_parameter_value then v_missing_blocked:=true; end;
  if not v_missing_blocked then raise exception 'incomplete duplicate search did not block CREATE_ENTITY'; end if;

  -- Any unresolved/confirmed duplicate candidate in the candidate group blocks creation.
  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata) values(v_dup_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_dup_case,'NEW_ENTITY','OPEN','HIGH','BULL','{}','rollback duplicate gate','{}',1);
  insert into bullmatch_private.entity_match_candidates(id,candidate_group_id,entity_type,mention_ref,match_score,signals,decision,policy_version,review_case_id)
  values(v_dup_candidate,v_dup_group,'BULL',jsonb_build_object('raw_name','วัวมี duplicate '||left(v_dup_candidate::text,8)),0.3,
    jsonb_build_object('candidate_search_completed',true,'duplicate_search_completed',true,'search_policy_version','test-search-v1'),
    'NEW_ENTITY_CANDIDATE','test-v1',v_dup_case);
  insert into bullmatch_private.duplicate_candidates(candidate_group_id,candidate_type,score,signals,differing_fields,status,review_case_id)
  values(v_dup_group,'ENTITY',0.7,'{}','{}','REVIEW_REQUIRED',v_dup_case);
  begin
    perform public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_dup_case,
      'expected_case_status','OPEN','expected_case_version',1,'note','should block',
      'payload',jsonb_build_object('candidate_id',v_dup_candidate,'creation_basis','MULTI_SIGNAL')));
  exception when unique_violation then v_dup_blocked:=true; end;
  if not v_dup_blocked then raise exception 'unresolved duplicate did not block CREATE_ENTITY'; end if;

  -- Exact normalized-name collision is conservatively blocked in V1.
  insert into bullmatch.bulls(id,canonical_name,normalized_name,verification_status)
  values(v_existing_bull,'นิลชื่อซ้ำ ทดสอบ',bullmatch.normalize_entity_name('นิลชื่อซ้ำ ทดสอบ'),'VERIFIED');
  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata) values(v_name_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_name_case,'NEW_ENTITY','OPEN','HIGH','BULL','{}','rollback normalized-name gate','{}',1);
  insert into bullmatch_private.entity_match_candidates(id,candidate_group_id,entity_type,mention_ref,match_score,signals,decision,policy_version,review_case_id)
  values(v_name_candidate,v_name_group,'BULL',jsonb_build_object('raw_name','นิลชื่อซ้ำ ทดสอบ'),0.1,
    jsonb_build_object('candidate_search_completed',true,'duplicate_search_completed',true,'search_policy_version','test-search-v1'),
    'NEW_ENTITY_CANDIDATE','test-v1',v_name_case);
  begin
    perform public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_name_case,
      'expected_case_status','OPEN','expected_case_version',1,'note','should block',
      'payload',jsonb_build_object('candidate_id',v_name_candidate,'creation_basis','MULTI_SIGNAL')));
  exception when unique_violation then v_name_blocked:=true; end;
  if not v_name_blocked then raise exception 'normalized-name collision did not block CREATE_ENTITY'; end if;

  -- Name-only/weak identity basis must never authorize a new Bull.
  insert into bullmatch_private.candidate_groups(id,group_type,status,metadata) values(v_weak_group,'ENTITY','REVIEW_REQUIRED','{}');
  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,case_version)
  values(v_weak_case,'NEW_ENTITY','OPEN','HIGH','BULL','{}','rollback weak-basis gate','{}',1);
  insert into bullmatch_private.entity_match_candidates(id,candidate_group_id,entity_type,mention_ref,match_score,signals,decision,policy_version,review_case_id)
  values(v_weak_candidate,v_weak_group,'BULL',jsonb_build_object('raw_name','วัวชื่ออย่างเดียว '||left(v_weak_candidate::text,8)),0.1,
    jsonb_build_object('candidate_search_completed',true,'duplicate_search_completed',true,'search_policy_version','test-search-v1'),
    'NEW_ENTITY_CANDIDATE','test-v1',v_weak_case);
  begin
    perform public.bullmatch_api_review_create_entity(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_weak_case,
      'expected_case_status','OPEN','expected_case_version',1,'note','ชื่ออย่างเดียวไม่พอ',
      'payload',jsonb_build_object('candidate_id',v_weak_candidate,'creation_basis','NAME_ONLY')));
  exception when invalid_parameter_value then v_weak_blocked:=true; end;
  if not v_weak_blocked then raise exception 'NAME_ONLY creation basis did not block CREATE_ENTITY'; end if;
END;
$$;
rollback;
