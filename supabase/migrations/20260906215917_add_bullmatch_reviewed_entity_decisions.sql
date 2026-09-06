-- BMI-P1-008 — reviewed entity-link and duplicate-decision semantics.
-- These operations resolve candidate metadata only; they do not create, merge, archive or rewrite canonical entities/history.

alter table bullmatch_private.entity_match_candidates drop constraint if exists entity_match_candidates_decision_check;
alter table bullmatch_private.entity_match_candidates add constraint entity_match_candidates_decision_check check (
  decision in ('AUTO_LINK','REVIEW','NO_MATCH','NEW_ENTITY_CANDIDATE','CONFIRMED_LINK')
);

create or replace function public.bullmatch_api_review_entity_decision(
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
  v_action text;
  v_expected_status text;
  v_expected_version bigint;
  v_payload jsonb:=coalesce(p_command->'payload','{}'::jsonb);
  v_note text:=nullif(btrim(coalesce(p_command->>'note','')),'');
  v_candidate_id uuid;
  v_target_id uuid;
  v_identity_basis text;
  v_case bullmatch.review_cases%rowtype;
  v_entity_candidate bullmatch_private.entity_match_candidates%rowtype;
  v_duplicate_candidate bullmatch_private.duplicate_candidates%rowtype;
  v_existing bullmatch.review_actions%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_review_action_id uuid;
  v_target_ok boolean:=false;
begin
  v_role:=bullmatch_private.require_review_role(p_actor_id);

  if coalesce(v_command->>'schema_version','')<>'1.0.0' then
    raise exception 'unsupported entity decision schema_version' using errcode='22023';
  end if;
  begin v_command_id:=(v_command->>'command_id')::uuid;
  exception when others then raise exception 'valid command_id UUID is required' using errcode='22023'; end;
  begin v_case_id:=(v_command->>'review_case_id')::uuid;
  exception when others then raise exception 'valid review_case_id UUID is required' using errcode='22023'; end;
  v_action:=upper(btrim(coalesce(v_command->>'action','')));
  if v_action not in ('LINK_ENTITY','CONFIRM_DUPLICATE','MARK_NOT_DUPLICATE') then
    raise exception 'unsupported reviewed entity decision action: %',v_action using errcode='0A000';
  end if;
  v_expected_status:=upper(btrim(coalesce(v_command->>'expected_case_status','')));
  begin v_expected_version:=(v_command->>'expected_case_version')::bigint;
  exception when others then raise exception 'expected_case_version is required' using errcode='22023'; end;
  if v_expected_version<1 then raise exception 'expected_case_version must be >= 1' using errcode='22023'; end if;
  if v_expected_status not in ('OPEN','IN_REVIEW') then
    raise exception 'entity decisions require expected_case_status OPEN or IN_REVIEW' using errcode='22023';
  end if;
  if jsonb_typeof(v_payload)<>'object' then raise exception 'payload must be an object' using errcode='22023'; end if;
  begin v_candidate_id:=(v_payload->>'candidate_id')::uuid;
  exception when others then raise exception 'payload.candidate_id UUID is required' using errcode='22023'; end;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>v_action then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'case_version',v_existing.case_version_after,'canonical_mutation',false
    );
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id for update;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>v_action then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'case_version',v_existing.case_version_after,'canonical_mutation',false
    );
  end if;

  if v_case.status<>v_expected_status or v_case.case_version<>v_expected_version then
    raise exception 'STALE_REVIEW_CASE expected %/% but current is %/%',
      v_expected_status,v_expected_version,v_case.status,v_case.case_version using errcode='40001';
  end if;

  if v_action='LINK_ENTITY' then
    if v_note is null then raise exception 'LINK_ENTITY requires reviewer note' using errcode='22023'; end if;
    begin v_target_id:=(v_payload->>'canonical_entity_id')::uuid;
    exception when others then raise exception 'payload.canonical_entity_id UUID is required' using errcode='22023'; end;

    select * into v_entity_candidate
    from bullmatch_private.entity_match_candidates emc
    where emc.id=v_candidate_id and emc.review_case_id=v_case_id
    for update;
    if not found then raise exception 'entity match candidate not found on this review case' using errcode='P0002'; end if;
    if v_entity_candidate.decision='CONFIRMED_LINK' then
      raise exception 'entity match candidate already has a confirmed link' using errcode='23505';
    end if;

    case v_entity_candidate.entity_type
      when 'BULL' then
        select exists(select 1 from bullmatch.bulls x where x.id=v_target_id and x.verification_status='VERIFIED' and x.archived_at is null) into v_target_ok;
      when 'OWNER' then
        select exists(select 1 from bullmatch.owners x where x.id=v_target_id and x.verification_status='VERIFIED' and x.archived_at is null) into v_target_ok;
      when 'CAMP' then
        select exists(select 1 from bullmatch.camps x where x.id=v_target_id and x.verification_status='VERIFIED' and x.archived_at is null) into v_target_ok;
      when 'VENUE' then
        select exists(select 1 from bullmatch.venues x where x.id=v_target_id and x.verification_status='VERIFIED' and x.archived_at is null) into v_target_ok;
      when 'EVENT' then
        select exists(select 1 from bullmatch.events x where x.id=v_target_id and x.verification_status='VERIFIED' and x.archived_at is null) into v_target_ok;
      else
        raise exception 'unsupported entity candidate type %',v_entity_candidate.entity_type using errcode='0A000';
    end case;
    if not v_target_ok then raise exception 'canonical target must exist, be VERIFIED, and not archived' using errcode='22023'; end if;

    v_identity_basis:=upper(btrim(coalesce(v_payload->>'identity_basis','')));
    if v_entity_candidate.entity_type='BULL' then
      if v_identity_basis not in ('VISUAL_IDENTITY','OWNER_CAMP_CONTEXT','EXTERNAL_IDENTIFIER','MATCH_HISTORY_CONTEXT','OFFICIAL_RECORD','MULTI_SIGNAL') then
        raise exception 'Bull LINK_ENTITY requires a reviewed non-name-only identity_basis' using errcode='22023';
      end if;
    else
      if v_identity_basis='' then v_identity_basis:='REVIEWED_CONTEXT'; end if;
    end if;

    v_before:=to_jsonb(v_entity_candidate);
    update bullmatch_private.entity_match_candidates
    set proposed_entity_id=v_target_id,
        decision='CONFIRMED_LINK',
        signals=coalesce(signals,'{}'::jsonb)||jsonb_build_object(
          'reviewed_identity_basis',v_identity_basis,
          'reviewed_at',now()
        ),
        updated_at=now()
    where id=v_candidate_id;
    select to_jsonb(emc) into v_after from bullmatch_private.entity_match_candidates emc where emc.id=v_candidate_id;

  else
    select * into v_duplicate_candidate
    from bullmatch_private.duplicate_candidates dc
    where dc.id=v_candidate_id and dc.review_case_id=v_case_id
    for update;
    if not found then raise exception 'duplicate candidate not found on this review case' using errcode='P0002'; end if;
    if v_duplicate_candidate.status in ('CONFIRMED_DUPLICATE','NOT_DUPLICATE') then
      raise exception 'duplicate candidate already has a terminal reviewed decision' using errcode='23505';
    end if;
    if v_note is null then raise exception '% requires reviewer note',v_action using errcode='22023'; end if;

    v_before:=to_jsonb(v_duplicate_candidate);
    update bullmatch_private.duplicate_candidates
    set status=case when v_action='CONFIRM_DUPLICATE' then 'CONFIRMED_DUPLICATE' else 'NOT_DUPLICATE' end,
        updated_at=now()
    where id=v_candidate_id;
    select to_jsonb(dc) into v_after from bullmatch_private.duplicate_candidates dc where dc.id=v_candidate_id;
  end if;

  update bullmatch.review_cases
  set case_version=case_version+1,updated_at=now()
  where id=v_case_id;

  insert into bullmatch.review_actions(
    review_case_id,actor_id,command_id,action,expected_case_version,
    case_version_before,case_version_after,before_value,after_value,notes
  ) values (
    v_case_id,p_actor_id,v_command_id,v_action,v_expected_version,
    v_expected_version,v_expected_version+1,v_before,v_after,v_note
  ) returning id into v_review_action_id;

  insert into bullmatch_private.audit_log(
    actor_type,actor_id,action,entity_type,entity_id,correlation_id,metadata
  ) values (
    'USER',p_actor_id::text,'REVIEW_'||v_action,
    case when v_action='LINK_ENTITY' then 'ENTITY_MATCH_CANDIDATE' else 'DUPLICATE_CANDIDATE' end,
    v_candidate_id,v_command_id,
    jsonb_build_object(
      'review_case_id',v_case_id,'review_action_id',v_review_action_id,
      'case_version_before',v_expected_version,'case_version_after',v_expected_version+1,
      'canonical_target_id',v_target_id,'identity_basis',nullif(v_identity_basis,''),
      'canonical_mutation',false
    )
  );

  return jsonb_build_object(
    'ok',true,'idempotent_replay',false,'review_action_id',v_review_action_id,
    'review_case_id',v_case_id,'action',v_action,'candidate_id',v_candidate_id,
    'case_version',v_expected_version+1,'canonical_mutation',false,
    'candidate',v_after
  );
end;
$$;

revoke all on function public.bullmatch_api_review_entity_decision(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_review_entity_decision(uuid,jsonb) to service_role;
