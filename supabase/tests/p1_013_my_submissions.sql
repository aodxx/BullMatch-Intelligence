-- BMI-P1-013 rollback-only regression for MY_SUBMISSIONS safe contributor projection.
-- Uses the existing Auth user and a temporary VERIFIED Bull; all fixture data is rolled back.

begin;

DO $$
DECLARE
  v_user uuid;
  v_bull uuid;
  v_submit jsonb;
  v_read jsonb;
  v_item jsonb;
  v_claim uuid;
  v_failed boolean := false;
BEGIN
  select id into v_user from auth.users order by created_at limit 1;
  if v_user is null then raise exception 'expected auth user'; end if;

  insert into bullmatch.bulls(canonical_name,normalized_name,verification_status)
  values(
    'ROLLBACK MY SUBMISSIONS '||substr(gen_random_uuid()::text,1,8),
    'rollback-my-submissions-'||gen_random_uuid()::text,
    'VERIFIED'
  ) returning id into v_bull;

  v_submit := public.bullmatch_api_submit_bull_correction(v_user,jsonb_build_object(
    'schema_version','1.0.0',
    'client_submission_key','rollback-my-submissions-key',
    'bull_id',v_bull,
    'field_key','color_description',
    'proposed_value','โหนดหลังขาว',
    'source_url','https://example.invalid/private-reference',
    'note','must not leak'
  ));

  v_read := public.bullmatch_api_contributor_query(v_user,'MY_SUBMISSIONS',50,0);
  if (v_read->>'total')::int < 1 then raise exception 'MY_SUBMISSIONS returned no own item'; end if;

  select x.value into v_item
  from jsonb_array_elements(v_read->'items') x(value)
  where x.value->>'id'=v_submit->>'submission_id'
  limit 1;

  if v_item is null then raise exception 'new submission missing from projection'; end if;
  if v_item#>>'{target,bull_name}' is null then raise exception 'safe verified Bull name missing'; end if;
  if v_item#>>'{claims,0,field_key}' <> 'color_description' then raise exception 'safe claim field missing'; end if;
  if v_item#>>'{claims,0,proposed_value}' <> 'โหนดหลังขาว' then raise exception 'safe proposed value missing'; end if;
  if v_item#>>'{claims,0,outcome}' <> 'PENDING_REVIEW' then raise exception 'unexpected initial outcome'; end if;

  if v_item::text ilike '%private-reference%' or v_item::text ilike '%must not leak%' then
    raise exception 'source URL or contributor private note leaked';
  end if;
  if v_item ? 'review_case_id' or v_item ? 'assigned_to' or v_item ? 'reviewer_note' then
    raise exception 'review-private field leaked';
  end if;

  v_claim := (v_submit->>'claim_id')::uuid;
  update bullmatch_private.claims set status='VERIFIED' where id=v_claim;
  v_read := public.bullmatch_api_contributor_query(v_user,'MY_SUBMISSIONS',50,0);
  select x.value into v_item from jsonb_array_elements(v_read->'items') x(value) where x.value->>'id'=v_submit->>'submission_id' limit 1;
  if v_item#>>'{claims,0,outcome}' <> 'ACCEPTED' then raise exception 'VERIFIED claim did not map to ACCEPTED'; end if;

  begin
    perform public.bullmatch_api_contributor_query(null,'MY_SUBMISSIONS',50,0);
  exception when insufficient_privilege then v_failed := true;
  end;
  if not v_failed then raise exception 'null actor unexpectedly accepted'; end if;

  if has_function_privilege('anon','public.bullmatch_api_contributor_query(uuid,text,integer,integer)','execute') then raise exception 'anon can execute contributor query'; end if;
  if has_function_privilege('authenticated','public.bullmatch_api_contributor_query(uuid,text,integer,integer)','execute') then raise exception 'authenticated can execute contributor query directly'; end if;
  if not has_function_privilege('service_role','public.bullmatch_api_contributor_query(uuid,text,integer,integer)','execute') then raise exception 'service_role cannot execute contributor query'; end if;
END $$;

rollback;

select count(*) as retained_fixture_count
from bullmatch_private.community_submissions
where client_submission_key='rollback-my-submissions-key';
