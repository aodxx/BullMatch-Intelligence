-- BMI-P1-008 — deterministic read-only Bull identity merge/split impact preview.
-- Name similarity is never merge authority; execution remains disabled.

create or replace function public.bullmatch_api_identity_impact_preview(
  p_actor_id uuid,
  p_review_case_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_case bullmatch.review_cases%rowtype;
  v_entity_type text;
  v_operation text;
  v_source_ids uuid[] := array[]::uuid[];
  v_target_ids uuid[] := array[]::uuid[];
  v_source_count integer;
  v_target_count integer;
  v_missing_sources integer;
  v_missing_targets integer;
  v_alias_count bigint;
  v_participant_rows bigint;
  v_match_count bigint;
  v_published_match_count bigint;
  v_source_mapping_count bigint;
  v_provenance_count bigint;
  v_identity_event_count bigint;
  v_hard_conflict_match_count bigint;
  v_unverified_source_count bigint;
  v_archived_source_count bigint;
  v_fingerprint text;
begin
  perform bullmatch_private.require_review_role(p_actor_id);

  select * into v_case from bullmatch.review_cases where id=p_review_case_id;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;
  if v_case.case_type <> 'MERGE_SPLIT' then raise exception 'identity impact preview requires MERGE_SPLIT review case' using errcode='22023'; end if;

  v_entity_type := upper(btrim(coalesce(v_case.subject_ref->>'entity_type','')));
  v_operation := upper(btrim(coalesce(v_case.subject_ref->>'operation','')));
  if v_entity_type <> 'BULL' then raise exception 'foundation identity preview currently supports BULL only' using errcode='0A000'; end if;
  if v_operation not in ('MERGE','SPLIT') then raise exception 'MERGE_SPLIT subject_ref.operation must be MERGE or SPLIT' using errcode='22023'; end if;

  begin
    if jsonb_typeof(v_case.subject_ref->'source_entity_ids')='array' then
      select coalesce(array_agg(x::uuid order by x),array[]::uuid[]) into v_source_ids
      from jsonb_array_elements_text(v_case.subject_ref->'source_entity_ids') t(x);
    end if;
    if jsonb_typeof(v_case.subject_ref->'target_entity_ids')='array' then
      select coalesce(array_agg(x::uuid order by x),array[]::uuid[]) into v_target_ids
      from jsonb_array_elements_text(v_case.subject_ref->'target_entity_ids') t(x);
    end if;
  exception when invalid_text_representation then
    raise exception 'identity preview entity IDs must be UUIDs' using errcode='22023';
  end;

  v_source_count := cardinality(v_source_ids);
  v_target_count := cardinality(v_target_ids);
  if v_operation='MERGE' and v_source_count < 2 then raise exception 'MERGE preview requires at least two source_entity_ids' using errcode='22023'; end if;
  if v_operation='SPLIT' and v_source_count <> 1 then raise exception 'SPLIT preview requires exactly one source_entity_id' using errcode='22023'; end if;
  if v_operation='MERGE' and v_target_count <> 1 then raise exception 'MERGE preview requires exactly one target_entity_id survivor' using errcode='22023'; end if;

  select count(*) into v_missing_sources from unnest(v_source_ids) x where not exists(select 1 from bullmatch.bulls b where b.id=x);
  select count(*) into v_missing_targets from unnest(v_target_ids) x where not exists(select 1 from bullmatch.bulls b where b.id=x);
  if v_missing_sources>0 then raise exception 'one or more source Bull IDs do not exist' using errcode='22023'; end if;
  if v_missing_targets>0 then raise exception 'one or more target Bull IDs do not exist' using errcode='22023'; end if;

  select count(*) into v_alias_count from bullmatch.bull_aliases a where a.bull_id=any(v_source_ids);
  select count(*) into v_participant_rows from bullmatch.match_participants mp where mp.bull_id=any(v_source_ids);
  select count(distinct mp.match_id) into v_match_count from bullmatch.match_participants mp where mp.bull_id=any(v_source_ids);
  select count(distinct m.id) into v_published_match_count
  from bullmatch.matches m join bullmatch.match_participants mp on mp.match_id=m.id
  where mp.bull_id=any(v_source_ids) and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null;
  select count(*) into v_source_mapping_count from bullmatch_private.entity_source_mappings esm where esm.entity_type='BULL' and esm.canonical_entity_id=any(v_source_ids);
  select count(*) into v_provenance_count from bullmatch_private.fact_provenance fp where fp.subject_type='BULL' and fp.subject_id=any(v_source_ids);
  select count(*) into v_identity_event_count from bullmatch_private.identity_events ie where ie.entity_type='BULL' and (ie.source_entity_ids && v_source_ids or ie.target_entity_ids && v_source_ids);
  select count(*) into v_unverified_source_count from bullmatch.bulls b where b.id=any(v_source_ids) and b.verification_status<>'VERIFIED';
  select count(*) into v_archived_source_count from bullmatch.bulls b where b.id=any(v_source_ids) and b.archived_at is not null;

  select count(*) into v_hard_conflict_match_count
  from (
    select mp.match_id
    from bullmatch.match_participants mp
    where mp.bull_id=any(v_source_ids)
    group by mp.match_id
    having count(distinct mp.bull_id)>1
  ) conflicts;

  v_fingerprint := md5(concat_ws('|',
    p_review_case_id::text,v_case.case_version::text,v_operation,v_entity_type,
    array_to_string(v_source_ids,','),array_to_string(v_target_ids,','),
    v_alias_count::text,v_participant_rows::text,v_match_count::text,v_published_match_count::text,
    v_source_mapping_count::text,v_provenance_count::text,v_identity_event_count::text,
    v_hard_conflict_match_count::text,v_unverified_source_count::text,v_archived_source_count::text
  ));

  return jsonb_build_object(
    'review_case_id',p_review_case_id,
    'case_version',v_case.case_version,
    'operation',v_operation,
    'entity_type',v_entity_type,
    'source_entity_ids',to_jsonb(v_source_ids),
    'target_entity_ids',to_jsonb(v_target_ids),
    'source_entities',coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',b.id,'canonical_name',b.canonical_name,'verification_status',b.verification_status,
        'archived',b.archived_at is not null,'camp_id',b.current_camp_id,'owner_id',b.current_owner_id,
        'home_province',b.home_province,'primary_image_ref',b.primary_image_ref,
        'stats',case when s.bull_id is null then null else jsonb_build_object(
          'published_matches',s.published_matches,'statistical_matches',s.statistical_matches,
          'wins',s.wins,'losses',s.losses,'draws',s.draws,'win_rate_pct',s.win_rate_pct
        ) end
      ) order by b.canonical_name,b.id)
      from bullmatch.bulls b left join bullmatch.bull_basic_stats s on s.bull_id=b.id
      where b.id=any(v_source_ids)
    ),'[]'::jsonb),
    'target_entities',coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',b.id,'canonical_name',b.canonical_name,'verification_status',b.verification_status,
        'archived',b.archived_at is not null
      ) order by b.canonical_name,b.id)
      from bullmatch.bulls b where b.id=any(v_target_ids)
    ),'[]'::jsonb),
    'impact',jsonb_build_object(
      'alias_rows',v_alias_count,
      'match_participant_rows',v_participant_rows,
      'distinct_matches',v_match_count,
      'published_verified_matches',v_published_match_count,
      'source_mappings',v_source_mapping_count,
      'fact_provenance_rows',v_provenance_count,
      'prior_identity_events',v_identity_event_count
    ),
    'safety',jsonb_build_object(
      'hard_conflict_match_count',v_hard_conflict_match_count,
      'merge_blocked_by_hard_conflict',(v_operation='MERGE' and v_hard_conflict_match_count>0),
      'unverified_source_count',v_unverified_source_count,
      'archived_source_count',v_archived_source_count,
      'split_requires_assignment_plan',(v_operation='SPLIT'),
      'name_similarity_is_not_merge_authority',true
    ),
    'impact_preview_fingerprint',v_fingerprint,
    'execution_enabled',false
  );
end;$$;

revoke all on function public.bullmatch_api_identity_impact_preview(uuid,uuid) from public,anon,authenticated;
grant execute on function public.bullmatch_api_identity_impact_preview(uuid,uuid) to service_role;
