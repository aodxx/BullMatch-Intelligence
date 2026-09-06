-- BMI-P1-013 rollback-only Production regression.
-- Requires at least one existing Auth user; creates no retained fixture rows.

begin;

DO $$
DECLARE
  v_user uuid;
  v_submission uuid;
  v_evidence uuid;
  v_claim uuid;
  v_failed boolean;
BEGIN
  select id into v_user from auth.users order by created_at limit 1;
  if v_user is null then
    raise exception 'expected at least one auth user for rollback regression';
  end if;

  insert into bullmatch.contributor_profiles(user_id, contribution_started_at)
  values(v_user, now())
  on conflict(user_id) do nothing;

  insert into bullmatch_private.community_submissions(
    submitter_user_id,
    submission_type,
    client_submission_key,
    request_fingerprint,
    status,
    target_hint,
    source_url,
    dedupe_fingerprint
  ) values (
    v_user,
    'CORRECTION',
    'rollback-p1-013',
    repeat('a',64),
    'REVIEW_REQUIRED',
    jsonb_build_object('test',true),
    'https://example.invalid/evidence',
    repeat('b',64)
  ) returning id into v_submission;

  insert into bullmatch_private.evidence(
    submission_id,
    submitted_by_user_id,
    evidence_type,
    storage_ref,
    access_class,
    moderation_status,
    metadata
  ) values (
    v_submission,
    v_user,
    'URL_REFERENCE',
    'https://example.invalid/evidence',
    'PUBLIC_REFERENCE',
    'PENDING',
    jsonb_build_object('test',true)
  ) returning id into v_evidence;

  insert into bullmatch_private.claims(
    extraction_run_id,
    submission_id,
    created_by_user_id,
    origin_type,
    subject_type,
    subject_ref,
    field_key,
    value_json,
    basis,
    confidence,
    status,
    value_fingerprint
  ) values (
    null,
    v_submission,
    v_user,
    'COMMUNITY_SUBMISSION',
    'BULL',
    jsonb_build_object('test_ref',true),
    'home_province',
    jsonb_build_object('value','พัทลุง'),
    'EXPLICIT',
    null,
    'REVIEW_REQUIRED',
    repeat('c',64)
  ) returning id into v_claim;

  if v_submission is null or v_evidence is null or v_claim is null then
    raise exception 'community origin insert failed';
  end if;

  v_failed := false;
  begin
    insert into bullmatch_private.evidence(evidence_type, access_class, moderation_status)
    values('URL_REFERENCE','PUBLIC_REFERENCE','PENDING');
  exception when check_violation then
    v_failed := true;
  end;
  if not v_failed then
    raise exception 'evidence without origin unexpectedly accepted';
  end if;

  v_failed := false;
  begin
    insert into bullmatch_private.claims(
      extraction_run_id,
      submission_id,
      created_by_user_id,
      origin_type,
      subject_type,
      subject_ref,
      field_key,
      value_json,
      basis,
      status
    ) values (
      null,
      null,
      v_user,
      'COMMUNITY_SUBMISSION',
      'BULL',
      '{}'::jsonb,
      'home_province',
      jsonb_build_object('value','x'),
      'EXPLICIT',
      'REVIEW_REQUIRED'
    );
  exception when check_violation then
    v_failed := true;
  end;
  if not v_failed then
    raise exception 'community claim without submission unexpectedly accepted';
  end if;

  if has_table_privilege('anon','bullmatch_private.community_submissions','select') then
    raise exception 'anon can read community_submissions';
  end if;
  if has_table_privilege('authenticated','bullmatch_private.community_submissions','select') then
    raise exception 'authenticated can read community_submissions directly';
  end if;
  if has_table_privilege('authenticated','bullmatch.contributor_profiles','select') then
    raise exception 'authenticated can read contributor_profiles directly';
  end if;
END $$;

rollback;
