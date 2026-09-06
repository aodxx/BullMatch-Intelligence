-- BMI-P1-008 guarded VERIFIED claim -> canonical promotion regression assertions.
-- Behavioral fixtures are transaction-scoped and rolled back.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_promote_verified_claim(uuid,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_promote_verified_claim(uuid,jsonb)','EXECUTE') then
    raise exception 'browser roles can execute canonical promotion directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_promote_verified_claim(uuid,jsonb)','EXECUTE') then
    raise exception 'service_role cannot execute canonical promotion';
  end if;
  if not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='bullmatch_api_promote_verified_claim'
      and p.prosecdef and coalesce(array_to_string(p.proconfig,','),'') like '%search_path=%'
  ) then
    raise exception 'promotion RPC must be SECURITY DEFINER with fixed search_path';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_source uuid:=gen_random_uuid();
  v_item uuid:=gen_random_uuid();
  v_evidence uuid:=gen_random_uuid();
  v_run uuid:=gen_random_uuid();
  v_group uuid:=gen_random_uuid();
  v_bull uuid:=gen_random_uuid();
  v_claim uuid:=gen_random_uuid();
  v_bad_claim uuid:=gen_random_uuid();
  v_case uuid:=gen_random_uuid();
  v_command uuid:=gen_random_uuid();
  v_result jsonb;
  v_replay jsonb;
  v_value text;
  v_version bigint;
  v_count bigint;
  v_blocked boolean:=false;
BEGIN
  select user_id into v_actor
  from bullmatch.app_users
  where status='ACTIVE' and role='ADMIN'
  order by created_at limit 1;
  if v_actor is null then raise exception 'test requires an ACTIVE ADMIN'; end if;

  insert into bullmatch_private.sources(id,name,source_type,connector_key,access_method,policy_status,status)
  values(v_source,'ROLLBACK PROMOTION SOURCE','OPERATOR_UPLOAD','rollback-promotion','TEST','APPROVED','ACTIVE');
  insert into bullmatch_private.source_items(id,source_id,dedupe_key,retrieved_at,connector_name,connector_version,ingestion_status)
  values(v_item,v_source,'rollback-'||v_item::text,now(),'rollback','1','EXTRACTED');
  insert into bullmatch_private.evidence(id,source_item_id,evidence_type,text_excerpt,access_class)
  values(v_evidence,v_item,'TEXT','rollback evidence','INTERNAL');
  insert into bullmatch_private.extraction_runs(id,source_item_id,model_provider,model_name,contract_version,input_hash,started_at,status)
  values(v_run,v_item,'TEST','TEST','1','rollback-'||v_run::text,now(),'SUCCEEDED');
  insert into bullmatch_private.candidate_groups(id,group_type,source_item_id,extraction_run_id,status)
  values(v_group,'ENTITY',v_item,v_run,'VERIFIED');

  insert into bullmatch.bulls(id,canonical_name,normalized_name,verification_status)
  values(v_bull,'ROLLBACK PROMOTION BULL '||left(v_bull::text,8),'rollback-promotion-'||v_bull::text,'VERIFIED');

  insert into bullmatch_private.claims(id,extraction_run_id,candidate_group_id,subject_type,subject_ref,field_key,value_json,basis,status)
  values
    (v_claim,v_run,v_group,'BULL',jsonb_build_object('canonical_subject_id',v_bull),'home_province',to_jsonb('พัทลุง'::text),'EXPLICIT','VERIFIED'),
    (v_bad_claim,v_run,v_group,'BULL',jsonb_build_object('canonical_subject_id',v_bull),'canonical_name',to_jsonb('ห้ามแก้ชื่อ'::text),'EXPLICIT','VERIFIED');
  insert into bullmatch_private.claim_evidence(claim_id,evidence_id,relationship)
  values(v_claim,v_evidence,'SUPPORTS'),(v_bad_claim,v_evidence,'SUPPORTS');

  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context,resolved_at,resolved_by,case_version)
  values(v_case,'DATA_QUALITY','RESOLVED','NORMAL','BULL',jsonb_build_object('bull_id',v_bull),'rollback promotion validation','{}',now(),v_actor,2);
  insert into bullmatch_private.review_case_claims(review_case_id,claim_id,claim_role)
  values(v_case,v_claim,'PRIMARY'),(v_case,v_bad_claim,'RELATED');

  v_result:=public.bullmatch_api_promote_verified_claim(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,'claim_id',v_claim,
    'expected_case_status','RESOLVED','expected_case_version',2));
  if not (v_result->>'canonical_mutation')::boolean then raise exception 'promotion did not report canonical mutation'; end if;
  if (v_result->>'case_version')::bigint<>3 then raise exception 'promotion did not increment case version'; end if;

  select home_province into v_value from bullmatch.bulls where id=v_bull;
  if v_value<>'พัทลุง' then raise exception 'canonical Bull field was not promoted'; end if;

  select count(*) into v_count from bullmatch_private.fact_provenance
  where claim_id=v_claim and subject_id=v_bull and field_key='home_province';
  if v_count<>2 then raise exception 'expected claim + evidence provenance rows, got %',v_count; end if;
  select count(*) into v_count from bullmatch.review_actions where command_id=v_command and action='PROMOTE_CLAIM';
  if v_count<>1 then raise exception 'promotion review action missing'; end if;
  select count(*) into v_count from bullmatch_private.audit_log where correlation_id=v_command and action='REVIEW_PROMOTE_CLAIM';
  if v_count<>1 then raise exception 'promotion audit record missing'; end if;

  v_replay:=public.bullmatch_api_promote_verified_claim(v_actor,jsonb_build_object(
    'schema_version','1.0.0','command_id',v_command,'review_case_id',v_case,'claim_id',v_claim,
    'expected_case_status','RESOLVED','expected_case_version',2));
  if not (v_replay->>'idempotent_replay')::boolean then raise exception 'same command_id did not replay idempotently'; end if;
  select case_version into v_version from bullmatch.review_cases where id=v_case;
  if v_version<>3 then raise exception 'idempotent replay changed case version'; end if;

  begin
    perform public.bullmatch_api_promote_verified_claim(v_actor,jsonb_build_object(
      'schema_version','1.0.0','command_id',gen_random_uuid(),'review_case_id',v_case,'claim_id',v_bad_claim,
      'expected_case_status','RESOLVED','expected_case_version',3));
  exception when feature_not_supported then
    v_blocked:=true;
  end;
  if not v_blocked then raise exception 'non-allowlisted canonical_name promotion was not blocked'; end if;
END;
$$;
rollback;
