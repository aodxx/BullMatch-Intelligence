-- BMI-P1-008 — guarded reviewed CREATE_ENTITY semantics.
-- First slice supports only a new Bull identity created UNVERIFIED after explicit
-- candidate + duplicate search. It does not publish or verify the new Bull.

create or replace function public.bullmatch_api_review_create_entity(
  p_actor_id uuid,
  p_command jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_role text;
  v_command jsonb:=coalesce(p_command,'{}'::jsonb);
  v_command_id uuid;
  v_case_id uuid;
  v_expected_status text;
  v_expected_version bigint;
  v_payload jsonb:=coalesce(p_command->'payload','{}'::jsonb);
  v_note text:=nullif(btrim(coalesce(p_command->>'note','')),'');
  v_candidate_id uuid;
  v_creation_basis text;
  v_case bullmatch.review_cases%rowtype;
  v_candidate bullmatch_private.entity_match_candidates%rowtype;
  v_existing bullmatch.review_actions%rowtype;
  v_name text;
  v_normalized_name text;
  v_bull_id uuid;
  v_before jsonb;
  v_after jsonb;
  v_review_action_id uuid;
  v_duplicate_count bigint;
  v_confirmed_link_count bigint;
begin
  v_role:=bullmatch_private.require_review_role(p_actor_id);
  if v_role<>'ADMIN' then
    raise exception 'ACTIVE ADMIN required for reviewed entity creation' using errcode='42501';
  end if;

  if coalesce(v_command->>'schema_version','')<>'1.0.0' then
    raise exception 'unsupported create entity schema_version' using errcode='22023';
  end if;
  begin v_command_id:=(v_command->>'command_id')::uuid;
  exception when others then raise exception 'valid command_id UUID is required' using errcode='22023'; end;
  begin v_case_id:=(v_command->>'review_case_id')::uuid;
  exception when others then raise exception 'valid review_case_id UUID is required' using errcode='22023'; end;
  begin v_expected_version:=(v_command->>'expected_case_version')::bigint;
  exception when others then raise exception 'expected_case_version is required' using errcode='22023'; end;
  if v_expected_version<1 then raise exception 'expected_case_version must be >= 1' using errcode='22023'; end if;
  v_expected_status:=upper(btrim(coalesce(v_command->>'expected_case_status','')));
  if v_expected_status not in ('OPEN','IN_REVIEW') then
    raise exception 'CREATE_ENTITY requires expected_case_status OPEN or IN_REVIEW' using errcode='22023';
  end if;
  if jsonb_typeof(v_payload)<>'object' then raise exception 'payload must be an object' using errcode='22023'; end if;
  begin v_candidate_id:=(v_payload->>'candidate_id')::uuid;
  exception when others then raise exception 'payload.candidate_id UUID is required' using errcode='22023'; end;
  if v_note is null then raise exception 'CREATE_ENTITY requires reviewer note' using errcode='22023'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'CREATE_ENTITY' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'entity_id',v_existing.after_value->>'canonical_entity_id',
      'case_version',v_existing.case_version_after,'canonical_mutation',true,
      'verification_status','UNVERIFIED','creation_policy','BMI-P1-008-BULL-CREATE-V1'
    );
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id for update;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'CREATE_ENTITY' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'entity_id',v_existing.after_value->>'canonical_entity_id',
      'case_version',v_existing.case_version_after,'canonical_mutation',true,
      'verification_status','UNVERIFIED','creation_policy','BMI-P1-008-BULL-CREATE-V1'
    );
  end if;

  if v_case.status<>v_expected_status or v_case.case_version<>v_expected_version then
    raise exception 'STALE_REVIEW_CASE expected %/% but current is %/%',
      v_expected_status,v_expected_version,v_case.status,v_case.case_version using errcode='40001';
  end if;
  if v_case.case_type not in ('NEW_ENTITY','ENTITY_MATCH') or upper(v_case.subject_type)<>'BULL' then
    raise exception 'first CREATE_ENTITY slice requires a BULL NEW_ENTITY or ENTITY_MATCH review case' using errcode='0A000';
  end if;

  select * into v_candidate
  from bullmatch_private.entity_match_candidates emc
  where emc.id=v_candidate_id and emc.review_case_id=v_case_id
  for update;
  if not found then raise exception 'entity match candidate not found on this review case' using errcode='P0002'; end if;
  if v_candidate.entity_type<>'BULL' then
    raise exception 'first CREATE_ENTITY slice supports BULL candidates only' using errcode='0A000';
  end if;
  if v_candidate.decision<>'NEW_ENTITY_CANDIDATE' then
    raise exception 'CREATE_ENTITY requires candidate decision NEW_ENTITY_CANDIDATE' using errcode='22023';
  end if;
  if v_candidate.proposed_entity_id is not null then
    raise exception 'candidate already references a canonical entity' using errcode='23505';
  end if;

  if coalesce((v_candidate.signals->>'candidate_search_completed')::boolean,false) is not true
     or coalesce((v_candidate.signals->>'duplicate_search_completed')::boolean,false) is not true
     or nullif(btrim(coalesce(v_candidate.signals->>'search_policy_version','')),'') is null then
    raise exception 'CREATE_ENTITY requires completed candidate and duplicate search with search_policy_version' using errcode='22023';
  end if;

  v_creation_basis:=upper(btrim(coalesce(v_payload->>'creation_basis','')));
  if v_creation_basis not in ('VISUAL_IDENTITY','EXTERNAL_IDENTIFIER','OFFICIAL_RECORD','MATCH_HISTORY_CONTEXT','MULTI_SIGNAL') then
    raise exception 'Bull CREATE_ENTITY requires a reviewed strong non-name-only creation_basis' using errcode='22023';
  end if;

  v_name:=nullif(btrim(coalesce(v_candidate.mention_ref->>'raw_name','')),'');
  if v_name is null then raise exception 'Bull candidate mention_ref.raw_name is required' using errcode='22023'; end if;
  if length(v_name)>200 then raise exception 'Bull candidate raw_name is too long' using errcode='22023'; end if;
  v_normalized_name:=bullmatch.normalize_entity_name(v_name);
  if nullif(v_normalized_name,'') is null then raise exception 'Bull candidate name cannot normalize to blank' using errcode='22023'; end if;

  if exists(
    select 1 from bullmatch.bulls b
    where b.archived_at is null and b.normalized_name=v_normalized_name
  ) then
    raise exception 'existing active Bull with the same normalized name requires LINK_ENTITY or explicit distinct-identity escalation' using errcode='23505';
  end if;

  select count(*) into v_confirmed_link_count
  from bullmatch_private.entity_match_candidates emc
  where emc.candidate_group_id=v_candidate.candidate_group_id
    and emc.entity_type='BULL'
    and emc.decision='CONFIRMED_LINK';
  if v_confirmed_link_count>0 then
    raise exception 'candidate group already has a confirmed Bull link' using errcode='23505';
  end if;

  select count(*) into v_duplicate_count
  from bullmatch_private.duplicate_candidates dc
  where dc.candidate_group_id=v_candidate.candidate_group_id
    and dc.candidate_type='ENTITY'
    and dc.status in ('CANDIDATE','REVIEW_REQUIRED','CONFIRMED_DUPLICATE');
  if v_duplicate_count>0 then
    raise exception 'unresolved or confirmed duplicate candidate blocks CREATE_ENTITY' using errcode='23505';
  end if;

  v_before:=to_jsonb(v_candidate);

  -- Reuse the existing audited ADMIN creation primitive, but deliberately pass only
  -- canonical_name. All descriptive/relationship/media/history fields remain outside
  -- this first identity-creation slice and must use their own verified claim policies.
  perform set_config('request.jwt.claim.sub',p_actor_id::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',p_actor_id::text,'role','authenticated')::text,true);
  v_bull_id:=bullmatch.admin_create_bull(jsonb_build_object('canonical_name',v_name));

  update bullmatch_private.entity_match_candidates
  set proposed_entity_id=v_bull_id,
      decision='CONFIRMED_LINK',
      signals=coalesce(signals,'{}'::jsonb)||jsonb_build_object(
        'reviewed_creation_basis',v_creation_basis,
        'created_canonical_entity_id',v_bull_id,
        'reviewed_created_at',now(),
        'creation_policy','BMI-P1-008-BULL-CREATE-V1'
      ),
      updated_at=now()
  where id=v_candidate_id;

  select to_jsonb(emc) into v_after
  from bullmatch_private.entity_match_candidates emc where emc.id=v_candidate_id;

  update bullmatch.review_cases
  set case_version=case_version+1,updated_at=now()
  where id=v_case_id;

  insert into bullmatch.review_actions(
    review_case_id,actor_id,command_id,action,expected_case_version,
    case_version_before,case_version_after,before_value,after_value,notes
  ) values (
    v_case_id,p_actor_id,v_command_id,'CREATE_ENTITY',v_expected_version,
    v_expected_version,v_expected_version+1,
    jsonb_build_object('candidate',v_before),
    jsonb_build_object(
      'candidate',v_after,'canonical_entity_id',v_bull_id,
      'entity_type','BULL','verification_status','UNVERIFIED',
      'creation_policy','BMI-P1-008-BULL-CREATE-V1'
    ),
    v_note
  ) returning id into v_review_action_id;

  insert into bullmatch_private.audit_log(
    actor_type,actor_id,action,entity_type,entity_id,correlation_id,metadata
  ) values (
    'USER',p_actor_id::text,'REVIEW_CREATE_ENTITY','BULL',v_bull_id,v_command_id,
    jsonb_build_object(
      'review_case_id',v_case_id,'review_action_id',v_review_action_id,
      'candidate_id',v_candidate_id,'candidate_group_id',v_candidate.candidate_group_id,
      'case_version_before',v_expected_version,'case_version_after',v_expected_version+1,
      'creation_basis',v_creation_basis,'search_policy_version',v_candidate.signals->>'search_policy_version',
      'canonical_mutation',true,'verification_status','UNVERIFIED',
      'creation_policy','BMI-P1-008-BULL-CREATE-V1'
    )
  );

  return jsonb_build_object(
    'ok',true,'idempotent_replay',false,'review_action_id',v_review_action_id,
    'review_case_id',v_case_id,'action','CREATE_ENTITY','candidate_id',v_candidate_id,
    'entity_type','BULL','entity_id',v_bull_id,'case_version',v_expected_version+1,
    'canonical_mutation',true,'verification_status','UNVERIFIED',
    'creation_policy','BMI-P1-008-BULL-CREATE-V1'
  );
end;
$$;

revoke all on function public.bullmatch_api_review_create_entity(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_review_create_entity(uuid,jsonb) to service_role;
