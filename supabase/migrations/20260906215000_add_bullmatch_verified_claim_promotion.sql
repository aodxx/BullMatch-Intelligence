-- BMI-P1-008 — guarded VERIFIED claim -> canonical promotion, first low-risk slice.
-- Promotion is intentionally ADMIN-only and limited to explicit, evidence-backed Bull descriptive fields.
-- Identity, names, ownership/camp, lineage, media, participants, results and match history remain excluded.

alter table bullmatch.review_actions drop constraint if exists review_actions_action_check;
alter table bullmatch.review_actions add constraint review_actions_action_check check (
  action in (
    'CLAIM','UNCLAIM','APPROVE','REJECT','EDIT','LINK_ENTITY','CREATE_ENTITY',
    'CONFIRM_DUPLICATE','MARK_NOT_DUPLICATE','RESOLVE_CONFLICT','MERGE','SPLIT',
    'COMMENT','REOPEN','PROMOTE_CLAIM'
  )
);

create or replace function public.bullmatch_api_promote_verified_claim(
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
  v_claim_id uuid;
  v_expected_version bigint;
  v_case bullmatch.review_cases%rowtype;
  v_claim bullmatch_private.claims%rowtype;
  v_bull bullmatch.bulls%rowtype;
  v_existing bullmatch.review_actions%rowtype;
  v_subject_id uuid;
  v_field text;
  v_value text;
  v_before_value jsonb;
  v_after_value jsonb;
  v_review_action_id uuid;
  v_support_count bigint;
  v_provenance_count bigint;
begin
  v_role:=bullmatch_private.require_review_role(p_actor_id);
  if v_role<>'ADMIN' then
    raise exception 'ACTIVE ADMIN required for canonical claim promotion' using errcode='42501';
  end if;

  if coalesce(v_command->>'schema_version','')<>'1.0.0' then
    raise exception 'unsupported promotion command schema_version' using errcode='22023';
  end if;
  begin v_command_id:=(v_command->>'command_id')::uuid;
  exception when others then raise exception 'valid command_id UUID is required' using errcode='22023'; end;
  begin v_case_id:=(v_command->>'review_case_id')::uuid;
  exception when others then raise exception 'valid review_case_id UUID is required' using errcode='22023'; end;
  begin v_claim_id:=(v_command->>'claim_id')::uuid;
  exception when others then raise exception 'valid claim_id UUID is required' using errcode='22023'; end;
  begin v_expected_version:=(v_command->>'expected_case_version')::bigint;
  exception when others then raise exception 'expected_case_version is required' using errcode='22023'; end;
  if v_expected_version<1 then raise exception 'expected_case_version must be >= 1' using errcode='22023'; end if;
  if upper(btrim(coalesce(v_command->>'expected_case_status','')))<>'RESOLVED' then
    raise exception 'verified claim promotion requires expected_case_status RESOLVED' using errcode='22023';
  end if;

  -- Idempotency uses the same globally unique review command ledger as other review actions.
  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'PROMOTE_CLAIM' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'case_version',v_existing.case_version_after,'canonical_mutation',true
    );
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id for update;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;

  -- Recheck after locking to close concurrent command races.
  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>'PROMOTE_CLAIM' then
      raise exception 'command_id already belongs to a different review command' using errcode='23505';
    end if;
    return jsonb_build_object(
      'ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,
      'review_case_id',v_existing.review_case_id,'action',v_existing.action,
      'case_version',v_existing.case_version_after,'canonical_mutation',true
    );
  end if;

  if v_case.status<>'RESOLVED' or v_case.case_version<>v_expected_version then
    raise exception 'STALE_REVIEW_CASE expected RESOLVED/% but current is %/%',
      v_expected_version,v_case.status,v_case.case_version using errcode='40001';
  end if;

  select c.* into v_claim
  from bullmatch_private.claims c
  join bullmatch_private.review_case_claims rcc
    on rcc.claim_id=c.id and rcc.review_case_id=v_case_id
  where c.id=v_claim_id
  for update of c;
  if not found then raise exception 'claim is not linked to this review case' using errcode='22023'; end if;
  if v_claim.status<>'VERIFIED' then raise exception 'only VERIFIED claims can be promoted' using errcode='22023'; end if;
  if v_claim.basis<>'EXPLICIT' then raise exception 'first promotion slice requires EXPLICIT claim basis' using errcode='22023'; end if;
  if upper(btrim(v_claim.subject_type))<>'BULL' then raise exception 'first promotion slice supports BULL claims only' using errcode='0A000'; end if;

  begin v_subject_id:=(v_claim.subject_ref->>'canonical_subject_id')::uuid;
  exception when others then raise exception 'BULL claim subject_ref.canonical_subject_id UUID is required' using errcode='22023'; end;
  if v_subject_id is null then raise exception 'BULL claim subject_ref.canonical_subject_id UUID is required' using errcode='22023'; end if;

  v_field:=lower(btrim(coalesce(v_claim.field_key,'')));
  if v_field not in ('home_province','home_district','color_description','breed_description') then
    raise exception 'claim field % is not in the first canonical promotion allowlist',v_claim.field_key using errcode='0A000';
  end if;

  if jsonb_typeof(v_claim.value_json)<>'string' then
    raise exception 'first promotion slice requires a JSON string value' using errcode='22023';
  end if;
  v_value:=btrim(v_claim.value_json #>> '{}');
  if v_value is null or v_value='' then raise exception 'canonical promotion value cannot be blank' using errcode='22023'; end if;
  if v_field in ('home_province','home_district') and length(v_value)>120 then
    raise exception 'province/district promotion value is too long' using errcode='22023';
  end if;
  if v_field in ('color_description','breed_description') and length(v_value)>500 then
    raise exception 'descriptive promotion value is too long' using errcode='22023';
  end if;

  select count(*) into v_support_count
  from bullmatch_private.claim_evidence ce
  where ce.claim_id=v_claim_id and ce.relationship='SUPPORTS';
  if v_support_count<1 then
    raise exception 'canonical promotion requires at least one SUPPORTS evidence link' using errcode='22023';
  end if;

  select count(*) into v_provenance_count
  from bullmatch_private.fact_provenance fp
  where fp.claim_id=v_claim_id and fp.subject_type='BULL'
    and fp.subject_id=v_subject_id and fp.field_key=v_field;
  if v_provenance_count>0 then
    raise exception 'this claim already has canonical provenance for the target field' using errcode='23505';
  end if;

  select * into v_bull from bullmatch.bulls b where b.id=v_subject_id for update;
  if not found then raise exception 'canonical Bull not found' using errcode='P0002'; end if;
  if v_bull.archived_at is not null then raise exception 'cannot promote into an archived Bull' using errcode='22023'; end if;
  if v_bull.verification_status<>'VERIFIED' then raise exception 'canonical target Bull must be VERIFIED' using errcode='22023'; end if;

  v_before_value:=jsonb_build_object('field_key',v_field,'value',to_jsonb(v_bull)->v_field);

  if v_field='home_province' then
    update bullmatch.bulls set home_province=v_value,updated_at=now() where id=v_subject_id;
  elsif v_field='home_district' then
    update bullmatch.bulls set home_district=v_value,updated_at=now() where id=v_subject_id;
  elsif v_field='color_description' then
    update bullmatch.bulls set color_description=v_value,updated_at=now() where id=v_subject_id;
  elsif v_field='breed_description' then
    update bullmatch.bulls set breed_description=v_value,updated_at=now() where id=v_subject_id;
  end if;

  v_after_value:=jsonb_build_object('field_key',v_field,'value',to_jsonb(v_value));

  update bullmatch.review_cases
  set case_version=case_version+1,updated_at=now()
  where id=v_case_id;

  insert into bullmatch.review_actions(
    review_case_id,actor_id,command_id,action,expected_case_version,
    case_version_before,case_version_after,before_value,after_value,notes
  ) values (
    v_case_id,p_actor_id,v_command_id,'PROMOTE_CLAIM',v_expected_version,
    v_expected_version,v_expected_version+1,
    jsonb_build_object('canonical',v_before_value,'claim_id',v_claim_id),
    jsonb_build_object('canonical',v_after_value,'claim_id',v_claim_id),
    'Verified evidence-backed claim promoted through strict low-risk allowlist'
  ) returning id into v_review_action_id;

  -- One claim-level provenance edge plus each supporting/contradicting evidence edge.
  insert into bullmatch_private.fact_provenance(
    subject_type,subject_id,field_key,value_fingerprint,claim_id,review_action_id,relationship
  ) values (
    'BULL',v_subject_id,v_field,md5(v_claim.value_json::text),v_claim_id,v_review_action_id,'SUPPORTS'
  );

  insert into bullmatch_private.fact_provenance(
    subject_type,subject_id,field_key,value_fingerprint,claim_id,evidence_id,review_action_id,relationship
  )
  select 'BULL',v_subject_id,v_field,md5(v_claim.value_json::text),v_claim_id,ce.evidence_id,v_review_action_id,
    case ce.relationship when 'CONTRADICTS' then 'CONTRADICTS' else 'SUPPORTS' end
  from bullmatch_private.claim_evidence ce
  where ce.claim_id=v_claim_id and ce.relationship in ('SUPPORTS','CONTRADICTS');

  insert into bullmatch_private.audit_log(
    actor_type,actor_id,action,entity_type,entity_id,correlation_id,metadata
  ) values (
    'USER',p_actor_id::text,'REVIEW_PROMOTE_CLAIM','BULL',v_subject_id,v_command_id,
    jsonb_build_object(
      'review_case_id',v_case_id,'review_action_id',v_review_action_id,'claim_id',v_claim_id,
      'field_key',v_field,'before',v_before_value,'after',v_after_value,
      'supporting_evidence_count',v_support_count,'canonical_mutation',true,
      'promotion_policy','BMI-P1-008-BULL-DESCRIPTIVE-V1'
    )
  );

  return jsonb_build_object(
    'ok',true,'idempotent_replay',false,'review_action_id',v_review_action_id,
    'review_case_id',v_case_id,'claim_id',v_claim_id,'action','PROMOTE_CLAIM',
    'subject_type','BULL','subject_id',v_subject_id,'field_key',v_field,
    'case_version',v_expected_version+1,'canonical_mutation',true,
    'promotion_policy','BMI-P1-008-BULL-DESCRIPTIVE-V1'
  );
end;
$$;

revoke all on function public.bullmatch_api_promote_verified_claim(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_promote_verified_claim(uuid,jsonb) to service_role;
