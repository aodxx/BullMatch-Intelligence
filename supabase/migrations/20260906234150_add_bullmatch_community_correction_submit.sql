-- BMI-P1-013 — controlled community Bull profile correction intake.
-- Authenticated actor identity is supplied only by the trusted Edge layer.
-- This function never mutates canonical Bull fields.

create or replace function public.bullmatch_api_submit_bull_correction(
  p_actor_id uuid,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_schema_version text := btrim(coalesce(v_payload->>'schema_version',''));
  v_client_key text := btrim(coalesce(v_payload->>'client_submission_key',''));
  v_bull_text text := btrim(coalesce(v_payload->>'bull_id',''));
  v_bull_id uuid;
  v_field_key text := btrim(coalesce(v_payload->>'field_key',''));
  v_value text := btrim(coalesce(v_payload->>'proposed_value',''));
  v_source_url text := btrim(coalesce(v_payload->>'source_url',''));
  v_note text := nullif(btrim(coalesce(v_payload->>'note','')), '');
  v_profile_status text;
  v_bull_name text;
  v_request_fingerprint text;
  v_dedupe_fingerprint text;
  v_value_fingerprint text;
  v_existing_id uuid;
  v_existing_fingerprint text;
  v_submission_id uuid;
  v_evidence_id uuid;
  v_claim_id uuid;
  v_review_case_id uuid;
  v_summary text;
begin
  if p_actor_id is null or not exists(select 1 from auth.users u where u.id=p_actor_id) then
    raise exception 'AUTH_ACTOR_NOT_FOUND' using errcode='42501';
  end if;
  if v_schema_version <> '1.0.0' then raise exception 'UNSUPPORTED_SCHEMA_VERSION' using errcode='22023'; end if;
  if v_client_key = '' or length(v_client_key) > 120 then raise exception 'INVALID_CLIENT_SUBMISSION_KEY' using errcode='22023'; end if;
  if v_bull_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then raise exception 'INVALID_BULL_ID' using errcode='22023'; end if;
  v_bull_id := v_bull_text::uuid;
  if v_field_key not in ('home_province','home_district','color_description','breed_description') then raise exception 'UNSUPPORTED_FIELD' using errcode='22023'; end if;
  if v_value = '' or length(v_value) > 500 then raise exception 'INVALID_PROPOSED_VALUE' using errcode='22023'; end if;
  if length(v_source_url) > 2048 or v_source_url !~* '^https?://[^[:space:]]+$' then raise exception 'INVALID_SOURCE_URL' using errcode='22023'; end if;
  if v_note is not null and length(v_note) > 1000 then raise exception 'INVALID_NOTE' using errcode='22023'; end if;

  select b.canonical_name into v_bull_name
  from bullmatch.bulls b
  where b.id=v_bull_id and b.verification_status='VERIFIED' and b.archived_at is null;
  if v_bull_name is null then raise exception 'VERIFIED_BULL_NOT_FOUND' using errcode='P0002'; end if;

  insert into bullmatch.contributor_profiles(user_id, contribution_started_at)
  values(p_actor_id, now())
  on conflict(user_id) do update
    set contribution_started_at=coalesce(bullmatch.contributor_profiles.contribution_started_at, excluded.contribution_started_at)
  returning status into v_profile_status;
  if v_profile_status <> 'ACTIVE' then raise exception 'CONTRIBUTOR_NOT_ACTIVE' using errcode='42501'; end if;

  v_request_fingerprint := encode(extensions.digest(concat_ws(E'\n','BMI-P1-013-BULL-CORRECTION-V1',v_bull_id::text,v_field_key,v_value,v_source_url,coalesce(v_note,'')),'sha256'),'hex');
  v_dedupe_fingerprint := encode(extensions.digest(concat_ws(E'\n','BULL_CORRECTION',v_bull_id::text,v_field_key,lower(v_value),lower(v_source_url)),'sha256'),'hex');
  v_value_fingerprint := encode(extensions.digest(concat_ws(E'\n','BULL',v_bull_id::text,v_field_key,v_value),'sha256'),'hex');

  select s.id,s.request_fingerprint into v_existing_id,v_existing_fingerprint
  from bullmatch_private.community_submissions s
  where s.submitter_user_id=p_actor_id and s.client_submission_key=v_client_key;
  if v_existing_id is not null then
    if v_existing_fingerprint is distinct from v_request_fingerprint then raise exception 'IDEMPOTENCY_CONFLICT' using errcode='40001'; end if;
    select c.id,c.review_case_id into v_claim_id,v_review_case_id from bullmatch_private.claims c where c.submission_id=v_existing_id order by c.created_at,c.id limit 1;
    select e.id into v_evidence_id from bullmatch_private.evidence e where e.submission_id=v_existing_id order by e.created_at,e.id limit 1;
    return jsonb_build_object('ok',true,'replayed',true,'policy_id','BMI-P1-013-BULL-CORRECTION-V1','submission_id',v_existing_id,'evidence_id',v_evidence_id,'claim_id',v_claim_id,'review_case_id',v_review_case_id,'status','REVIEW_REQUIRED','canonical_mutation',false);
  end if;

  begin
    insert into bullmatch_private.community_submissions(submitter_user_id,submission_type,client_submission_key,request_fingerprint,status,target_hint,user_note,source_url,dedupe_fingerprint,moderation_metadata)
    values(p_actor_id,'CORRECTION',v_client_key,v_request_fingerprint,'REVIEW_REQUIRED',jsonb_build_object('bull_id',v_bull_id,'field_key',v_field_key),v_note,v_source_url,v_dedupe_fingerprint,jsonb_build_object('policy_id','BMI-P1-013-BULL-CORRECTION-V1','risk_tier','STANDARD_CORRECTION'))
    returning id into v_submission_id;
  exception when unique_violation then
    select s.id,s.request_fingerprint into v_existing_id,v_existing_fingerprint from bullmatch_private.community_submissions s where s.submitter_user_id=p_actor_id and s.client_submission_key=v_client_key;
    if v_existing_id is null or v_existing_fingerprint is distinct from v_request_fingerprint then raise exception 'IDEMPOTENCY_CONFLICT' using errcode='40001'; end if;
    select c.id,c.review_case_id into v_claim_id,v_review_case_id from bullmatch_private.claims c where c.submission_id=v_existing_id order by c.created_at,c.id limit 1;
    select e.id into v_evidence_id from bullmatch_private.evidence e where e.submission_id=v_existing_id order by e.created_at,e.id limit 1;
    return jsonb_build_object('ok',true,'replayed',true,'policy_id','BMI-P1-013-BULL-CORRECTION-V1','submission_id',v_existing_id,'evidence_id',v_evidence_id,'claim_id',v_claim_id,'review_case_id',v_review_case_id,'status','REVIEW_REQUIRED','canonical_mutation',false);
  end;

  insert into bullmatch_private.evidence(submission_id,submitted_by_user_id,evidence_type,storage_ref,access_class,moderation_status,metadata)
  values(v_submission_id,p_actor_id,'URL_REFERENCE',v_source_url,'PUBLIC_REFERENCE','PENDING',jsonb_build_object('policy_id','BMI-P1-013-BULL-CORRECTION-V1','route','submit_bull_profile_correction')) returning id into v_evidence_id;

  insert into bullmatch_private.claims(extraction_run_id,submission_id,created_by_user_id,origin_type,subject_type,subject_ref,canonical_subject_id,field_key,value_json,basis,confidence,status,value_fingerprint)
  values(null,v_submission_id,p_actor_id,'COMMUNITY_SUBMISSION','BULL',jsonb_build_object('bull_id',v_bull_id),v_bull_id,v_field_key,jsonb_build_object('value',v_value),'EXPLICIT',null,'REVIEW_REQUIRED',v_value_fingerprint) returning id into v_claim_id;

  insert into bullmatch_private.claim_evidence(claim_id,evidence_id,relationship) values(v_claim_id,v_evidence_id,'SUPPORTS');

  v_summary := left('Community correction: ' || v_bull_name || ' / ' || v_field_key, 500);
  insert into bullmatch.review_cases(case_type,status,priority,subject_type,subject_ref,summary,context)
  values('DATA_QUALITY','OPEN','NORMAL','CLAIM',jsonb_build_object('claim_id',v_claim_id,'submission_id',v_submission_id,'bull_id',v_bull_id),v_summary,jsonb_build_object('policy_id','BMI-P1-013-BULL-CORRECTION-V1','submission_id',v_submission_id,'risk_tier','STANDARD_CORRECTION')) returning id into v_review_case_id;

  insert into bullmatch_private.review_case_claims(review_case_id,claim_id,claim_role) values(v_review_case_id,v_claim_id,'PRIMARY');
  update bullmatch_private.claims set review_case_id=v_review_case_id,updated_at=now() where id=v_claim_id;

  return jsonb_build_object('ok',true,'replayed',false,'policy_id','BMI-P1-013-BULL-CORRECTION-V1','submission_id',v_submission_id,'evidence_id',v_evidence_id,'claim_id',v_claim_id,'review_case_id',v_review_case_id,'status','REVIEW_REQUIRED','canonical_mutation',false);
end;
$$;

revoke all on function public.bullmatch_api_submit_bull_correction(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_submit_bull_correction(uuid,jsonb) to service_role;
