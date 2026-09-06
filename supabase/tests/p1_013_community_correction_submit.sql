-- BMI-P1-013 rollback-only regression for controlled community Bull correction intake.
-- Creates a temporary VERIFIED Bull inside the transaction only. No fixture remains after rollback.

begin;

DO $$
DECLARE
  v_user uuid;
  v_bull uuid;
  v_before jsonb;
  v_after jsonb;
  v_first jsonb;
  v_replay jsonb;
  v_failed boolean := false;
  v_submission uuid;
BEGIN
  select id into v_user from auth.users order by created_at limit 1;
  if v_user is null then
    raise exception 'expected at least one auth user for rollback regression';
  end if;

  insert into bullmatch.bulls(
    canonical_name,
    normalized_name,
    home_province,
    verification_status
  ) values (
    'ROLLBACK P1-013 BULL ' || substr(gen_random_uuid()::text,1,8),
    'rollback-p1-013-' || gen_random_uuid()::text,
    'นครศรีธรรมราช',
    'VERIFIED'
  ) returning id into v_bull;

  select to_jsonb(b) into v_before from bullmatch.bulls b where b.id=v_bull;

  v_first := public.bullmatch_api_submit_bull_correction(
    v_user,
    jsonb_build_object(
      'schema_version','1.0.0',
      'client_submission_key','rollback-submit-key',
      'bull_id',v_bull,
      'field_key','home_province',
      'proposed_value','พัทลุง',
      'source_url','https://example.invalid/reference',
      'note','rollback test'
    )
  );

  v_replay := public.bullmatch_api_submit_bull_correction(
    v_user,
    jsonb_build_object(
      'schema_version','1.0.0',
      'client_submission_key','rollback-submit-key',
      'bull_id',v_bull,
      'field_key','home_province',
      'proposed_value','พัทลุง',
      'source_url','https://example.invalid/reference',
      'note','rollback test'
    )
  );

  if coalesce((v_first->>'replayed')::boolean,true) then
    raise exception 'first submission unexpectedly marked replay';
  end if;
  if not coalesce((v_replay->>'replayed')::boolean,false) then
    raise exception 'idempotent replay was not detected';
  end if;
  if v_first->>'submission_id' is distinct from v_replay->>'submission_id' then
    raise exception 'idempotent replay returned a different submission';
  end if;

  v_submission := (v_first->>'submission_id')::uuid;

  if (select count(*) from bullmatch_private.community_submissions where id=v_submission) <> 1 then
    raise exception 'expected exactly one community submission';
  end if;
  if (select count(*) from bullmatch_private.evidence where submission_id=v_submission) <> 1 then
    raise exception 'expected exactly one evidence row';
  end if;
  if (select count(*) from bullmatch_private.claims where submission_id=v_submission and status='REVIEW_REQUIRED' and confidence is null) <> 1 then
    raise exception 'expected exactly one REVIEW_REQUIRED claim with null confidence';
  end if;
  if (select count(*) from bullmatch.review_cases where id=(v_first->>'review_case_id')::uuid and status='OPEN' and case_type='DATA_QUALITY') <> 1 then
    raise exception 'expected OPEN DATA_QUALITY review case';
  end if;
  if (select count(*) from bullmatch_private.review_case_claims where review_case_id=(v_first->>'review_case_id')::uuid and claim_id=(v_first->>'claim_id')::uuid) <> 1 then
    raise exception 'review case is not linked to the claim';
  end if;

  select to_jsonb(b) into v_after from bullmatch.bulls b where b.id=v_bull;
  if v_before is distinct from v_after then
    raise exception 'canonical Bull changed during community submission';
  end if;

  v_failed := false;
  begin
    perform public.bullmatch_api_submit_bull_correction(
      v_user,
      jsonb_build_object(
        'schema_version','1.0.0',
        'client_submission_key','rollback-submit-key',
        'bull_id',v_bull,
        'field_key','home_province',
        'proposed_value','ตรัง',
        'source_url','https://example.invalid/reference',
        'note','changed payload'
      )
    );
  exception when serialization_failure then
    v_failed := true;
  end;
  if not v_failed then
    raise exception 'same idempotency key with changed payload was accepted';
  end if;

  v_failed := false;
  begin
    perform public.bullmatch_api_submit_bull_correction(
      v_user,
      jsonb_build_object(
        'schema_version','1.0.0',
        'client_submission_key','rollback-invalid-field',
        'bull_id',v_bull,
        'field_key','canonical_name',
        'proposed_value','ชื่อใหม่',
        'source_url','https://example.invalid/reference'
      )
    );
  exception when invalid_parameter_value then
    v_failed := true;
  end;
  if not v_failed then
    raise exception 'unsupported canonical identity field was accepted';
  end if;

  if has_function_privilege('anon','public.bullmatch_api_submit_bull_correction(uuid,jsonb)','execute') then
    raise exception 'anon can execute contribution RPC';
  end if;
  if has_function_privilege('authenticated','public.bullmatch_api_submit_bull_correction(uuid,jsonb)','execute') then
    raise exception 'authenticated can execute contribution RPC directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_submit_bull_correction(uuid,jsonb)','execute') then
    raise exception 'service_role cannot execute contribution RPC';
  end if;
END $$;

rollback;

select count(*) as retained_fixture_count
from bullmatch_private.community_submissions
where client_submission_key like 'rollback-%';
