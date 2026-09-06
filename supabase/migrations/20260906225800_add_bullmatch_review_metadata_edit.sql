-- BMI-P1-008 — selected safe EDIT semantics.
-- EDIT is intentionally limited to review-case routing metadata only.
-- It cannot mutate claims, evidence, subject identity, canonical entities or history.

create or replace function public.bullmatch_api_review_edit_metadata(
  p_actor_id uuid,
  p_command jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_command jsonb:=coalesce(p_command,'{}'::jsonb);
  v_command_id uuid;
  v_case_id uuid;
  v_expected_status text;
  v_expected_version bigint;
  v_patch jsonb:=coalesce(p_command->'patch','{}'::jsonb);
  v_note text:=nullif(btrim(coalesce(p_command->>'note','')),'');
  v_case bullmatch.review_cases%rowtype;
  v_existing bullmatch.review_actions%rowtype;
  v_priority text;
  v_summary text;
  v_before jsonb;
  v_after jsonb;
  v_review_action_id uuid;
  v_key text;
begin
  perform bullmatch_private.require_review_role(p_actor_id);

  if coalesce(v_command->>'schema_version','')<>'1.0.0' then
    raise exception 'unsupported review edit schema_version' using errcode='22023';
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
    raise exception 'EDIT requires expected_case_status OPEN or IN_REVIEW' using errcode='22023';
  end if;
  if jsonb_typeof(v_patch)<>'object' or v_patch='{}'::jsonb then
    raise exception 'non-empty patch object is required' using errcode='22023';
  end if;
  if v_note is null then raise exception 'EDIT requires reviewer note' using errcode='22023'; end if;

  for v_key in select jsonb_object_keys(v_patch)
  loop
    if v_key not in ('priority','summary') then
      raise exception 'EDIT field % is not allowed; only priority and summary are editable',v_key using errcode='0A000';
    end if;
  end loop;

  if v_patch ? 'priority' then
    if jsonb_typeof(v_patch->'priority')<>'string' then raise exception 'priority must be a string' using errcode='22023'; end if;
    v_priority:=upper(btrim(v_patch->>'priority'));
    if v_priority not in ('LOW','NORMAL','HIGH','URGENT') then raise exception 'invalid review priority' using errcode='22023'; end if;
  end if;
  if v_patch ? 'summary' then
    if jsonb_typeof(v_patch->'summary')<>'string' then raise exception 'summary must be a string' using errcode='22023'; end if;
    v_summary:=nullif(btrim(v_patch->>'summary'),'');
    if v_summary is null then raise exception 'summary cannot be blank' using errcode='22023'; end if;
    if length(v_summary)>500 then raise exception 'summary is too long' using errcode='22023'; end if;
  end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'EDIT' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action','EDIT',
      'case_version',v_existing.case_version_after,'canonical_mutation',false,
      'edit_policy','BMI-P1-008-REVIEW-METADATA-EDIT-V1'
    );
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id for update;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'EDIT' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action','EDIT',
      'case_version',v_existing.case_version_after,'canonical_mutation',false,
      'edit_policy','BMI-P1-008-REVIEW-METADATA-EDIT-V1'
    );
  end if;

  if v_case.status<>v_expected_status or v_case.case_version<>v_expected_version then
    raise exception 'STALE_REVIEW_CASE expected %/% but current is %/%',
      v_expected_status,v_expected_version,v_case.status,v_case.case_version using errcode='40001';
  end if;

  v_before:=jsonb_build_object('priority',v_case.priority,'summary',v_case.summary);

  update bullmatch.review_cases
  set priority=case when v_patch ? 'priority' then v_priority else priority end,
      summary=case when v_patch ? 'summary' then v_summary else summary end,
      case_version=case_version+1,
      updated_at=now()
  where id=v_case_id;

  select jsonb_build_object('priority',priority,'summary',summary)
  into v_after from bullmatch.review_cases where id=v_case_id;

  insert into bullmatch.review_actions(
    review_case_id,actor_id,command_id,action,expected_case_version,
    case_version_before,case_version_after,before_value,after_value,notes
  ) values (
    v_case_id,p_actor_id,v_command_id,'EDIT',v_expected_version,
    v_expected_version,v_expected_version+1,v_before,v_after,v_note
  ) returning id into v_review_action_id;

  insert into bullmatch_private.audit_log(
    actor_type,actor_id,action,entity_type,entity_id,correlation_id,metadata
  ) values (
    'USER',p_actor_id::text,'REVIEW_EDIT_METADATA','REVIEW_CASE',v_case_id,v_command_id,
    jsonb_build_object(
      'review_action_id',v_review_action_id,
      'case_version_before',v_expected_version,'case_version_after',v_expected_version+1,
      'before',v_before,'after',v_after,
      'canonical_mutation',false,
      'edit_policy','BMI-P1-008-REVIEW-METADATA-EDIT-V1'
    )
  );

  return jsonb_build_object(
    'ok',true,'idempotent_replay',false,'review_action_id',v_review_action_id,
    'review_case_id',v_case_id,'action','EDIT','case_version',v_expected_version+1,
    'canonical_mutation',false,'before',v_before,'after',v_after,
    'edit_policy','BMI-P1-008-REVIEW-METADATA-EDIT-V1'
  );
end;
$$;

revoke all on function public.bullmatch_api_review_edit_metadata(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_review_edit_metadata(uuid,jsonb) to service_role;
