-- BMI-P1-008 deterministic Bull identity impact preview assertions.
-- Behavioral fixtures are rollback-only.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_identity_impact_preview(uuid,uuid)','EXECUTE')
     or has_function_privilege('authenticated','public.bullmatch_api_identity_impact_preview(uuid,uuid)','EXECUTE') then
    raise exception 'browser roles can execute identity impact preview directly';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_identity_impact_preview(uuid,uuid)','EXECUTE') then
    raise exception 'service_role cannot execute identity impact preview';
  end if;
  if not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='bullmatch_api_identity_impact_preview'
      and p.prosecdef and coalesce(array_to_string(p.proconfig,','),'') like '%search_path=%'
  ) then
    raise exception 'identity impact preview must be SECURITY DEFINER with fixed search_path';
  end if;
END;
$$;

begin;
DO $$
DECLARE
  v_actor uuid;
  v_bull_a uuid:=gen_random_uuid();
  v_bull_b uuid:=gen_random_uuid();
  v_match uuid:=gen_random_uuid();
  v_case uuid:=gen_random_uuid();
  v_preview jsonb;
BEGIN
  select user_id into v_actor
  from bullmatch.app_users
  where status='ACTIVE' and role in ('ADMIN','REVIEWER')
  order by created_at limit 1;
  if v_actor is null then raise exception 'test requires an ACTIVE ADMIN/REVIEWER'; end if;

  insert into bullmatch.bulls(id,canonical_name,normalized_name,verification_status)
  values
    (v_bull_a,'TEST A '||left(v_bull_a::text,8),'test-a-'||v_bull_a::text,'VERIFIED'),
    (v_bull_b,'TEST B '||left(v_bull_b::text,8),'test-b-'||v_bull_b::text,'VERIFIED');

  insert into bullmatch.matches(id,status,verification_status)
  values(v_match,'COMPLETED','VERIFIED');

  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot)
  values(v_match,v_bull_a,'A','TEST A'),(v_match,v_bull_b,'B','TEST B');

  insert into bullmatch.review_cases(id,case_type,status,priority,subject_type,subject_ref,summary,context)
  values(v_case,'MERGE_SPLIT','OPEN','HIGH','BULL_IDENTITY',jsonb_build_object(
    'entity_type','BULL',
    'operation','MERGE',
    'source_entity_ids',jsonb_build_array(v_bull_a,v_bull_b),
    'target_entity_ids',jsonb_build_array(v_bull_a)
  ),'rollback-only merge preview test','{}'::jsonb);

  v_preview:=public.bullmatch_api_identity_impact_preview(v_actor,v_case);

  if (v_preview->'impact'->>'distinct_matches')::int <> 1 then
    raise exception 'identity preview did not report affected match';
  end if;
  if (v_preview->'safety'->>'hard_conflict_match_count')::int <> 1 then
    raise exception 'same-match Bull hard conflict was not detected';
  end if;
  if not (v_preview->'safety'->>'merge_blocked_by_hard_conflict')::boolean then
    raise exception 'merge was not blocked by same-match identity conflict';
  end if;
  if (v_preview->>'execution_enabled')::boolean then
    raise exception 'identity impact preview unexpectedly enables execution';
  end if;
  if nullif(v_preview->>'impact_preview_fingerprint','') is null then
    raise exception 'identity impact preview fingerprint missing';
  end if;
END;
$$;
rollback;
