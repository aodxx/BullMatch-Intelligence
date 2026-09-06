-- BMI-P1-008 — Review Backend Foundation
-- Production migration version: 20260906211732
-- Server-mediated reviewer queue/detail/evidence access and idempotent review commands.
-- Canonical Bull/Match history is intentionally NOT mutated by this migration.

alter table bullmatch_private.claims drop constraint if exists claims_status_check;
alter table bullmatch_private.claims add constraint claims_status_check check (
  status in ('PROPOSED','REVIEW_REQUIRED','CORROBORATED','VERIFIED','CONFLICT','REJECTED','SUPERSEDED','WITHDRAWN')
);

create table if not exists bullmatch_private.review_case_claims (
  review_case_id uuid not null references bullmatch.review_cases(id) on delete cascade,
  claim_id uuid not null references bullmatch_private.claims(id) on delete cascade,
  claim_role text not null default 'PRIMARY' check (claim_role in ('PRIMARY','RELATED','CONFLICTING')),
  created_at timestamptz not null default now(),
  primary key (review_case_id, claim_id)
);
create index if not exists review_case_claims_claim_idx on bullmatch_private.review_case_claims(claim_id, review_case_id);
alter table bullmatch_private.review_case_claims enable row level security;
grant all on bullmatch_private.review_case_claims to service_role;

create or replace function bullmatch_private.require_review_role(p_actor_id uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare v_role text;
begin
  if p_actor_id is null then raise exception 'review actor is required' using errcode='22023'; end if;
  select au.role into v_role
  from bullmatch.app_users au
  where au.user_id=p_actor_id and au.status='ACTIVE' and au.role in ('ADMIN','REVIEWER');
  if v_role is null then raise exception 'ACTIVE ADMIN or REVIEWER required' using errcode='42501'; end if;
  return v_role;
end;$$;
revoke all on function bullmatch_private.require_review_role(uuid) from public,anon,authenticated;
grant execute on function bullmatch_private.require_review_role(uuid) to service_role;

create or replace function public.bullmatch_api_review_query(
  p_actor_id uuid,p_resource text,p_id uuid default null,p_limit integer default 50,p_offset integer default 0
)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare
  v_resource text:=upper(btrim(coalesce(p_resource,'')));
  v_limit integer:=greatest(1,least(coalesce(p_limit,50),100));
  v_offset integer:=greatest(coalesce(p_offset,0),0);
  v_result jsonb;
begin
  perform bullmatch_private.require_review_role(p_actor_id);
  case v_resource
  when 'REVIEW_QUEUE' then
    select coalesce(jsonb_agg(to_jsonb(q) order by q.priority_rank desc,q.created_at asc,q.id),'[]'::jsonb)
    into v_result
    from (
      select rc.id,rc.case_type,rc.status,rc.priority,
        case rc.priority when 'URGENT' then 4 when 'HIGH' then 3 when 'NORMAL' then 2 else 1 end as priority_rank,
        rc.subject_type,rc.subject_ref,rc.summary,rc.context,rc.assigned_to,au.display_name as assigned_display_name,
        rc.case_version,rc.created_at,rc.updated_at,
        (select count(*) from bullmatch_private.review_case_claims rcc where rcc.review_case_id=rc.id) as claim_count,
        (select count(*) from bullmatch_private.review_case_claims rcc join bullmatch_private.claim_evidence ce on ce.claim_id=rcc.claim_id where rcc.review_case_id=rc.id) as evidence_link_count,
        (rc.case_type in ('CONFLICTING_RESULT','CONFLICTING_DATE','MERGE_SPLIT') or lower(coalesce(rc.context->>'has_conflict','false'))='true') as has_conflict,
        coalesce(rc.context->>'risk_tier','UNASSESSED') as risk_tier
      from bullmatch.review_cases rc
      left join bullmatch.app_users au on au.user_id=rc.assigned_to
      where rc.status in ('OPEN','IN_REVIEW')
      order by priority_rank desc,rc.created_at asc,rc.id
      limit v_limit offset v_offset
    ) q;

  when 'REVIEW_CASE' then
    if p_id is null then raise exception 'p_id is required for REVIEW_CASE' using errcode='22023'; end if;
    select jsonb_build_object(
      'case',jsonb_build_object(
        'id',rc.id,'case_type',rc.case_type,'status',rc.status,'priority',rc.priority,
        'subject_type',rc.subject_type,'subject_ref',rc.subject_ref,'summary',rc.summary,'context',rc.context,
        'assigned_to',rc.assigned_to,'assigned_display_name',au.display_name,'case_version',rc.case_version,
        'created_at',rc.created_at,'updated_at',rc.updated_at,'resolved_at',rc.resolved_at,'resolved_by',rc.resolved_by
      ),
      'claims',coalesce((
        select jsonb_agg(jsonb_build_object(
          'id',c.id,'claim_role',rcc.claim_role,'subject_type',c.subject_type,'subject_ref',c.subject_ref,
          'field_key',c.field_key,'value_json',c.value_json,'basis',c.basis,'confidence',c.confidence,
          'status',c.status,'created_at',c.created_at,
          'evidence_count',(select count(*) from bullmatch_private.claim_evidence ce0 where ce0.claim_id=c.id)
        ) order by case rcc.claim_role when 'PRIMARY' then 1 when 'CONFLICTING' then 2 else 3 end,c.created_at,c.id)
        from bullmatch_private.review_case_claims rcc
        join bullmatch_private.claims c on c.id=rcc.claim_id
        where rcc.review_case_id=rc.id
      ),'[]'::jsonb),
      'evidence',coalesce((
        select jsonb_agg(jsonb_build_object(
          'id',e.id,'claim_id',rcc.claim_id,'relationship',ce.relationship,'evidence_type',e.evidence_type,
          'access_class',e.access_class,
          'storage_ref',case when e.access_class='PUBLIC_REFERENCE' then e.storage_ref else null end,
          'text_excerpt',case when e.access_class='RESTRICTED' then null else e.text_excerpt end,
          'timestamp_start_seconds',e.timestamp_start_seconds,'timestamp_end_seconds',e.timestamp_end_seconds,
          'content_sha256',e.content_sha256,
          'source',jsonb_build_object(
            'id',si.id,'title',case when e.access_class='RESTRICTED' then null else si.title end,
            'canonical_url',case when e.access_class='RESTRICTED' then null else si.canonical_url end,
            'published_at',si.published_at,'retrieved_at',si.retrieved_at,'source_name',s.name,'reliability_tier',s.reliability_tier
          )
        ) order by case ce.relationship when 'CONTRADICTS' then 1 when 'SUPPORTS' then 2 else 3 end,e.created_at,e.id)
        from bullmatch_private.review_case_claims rcc
        join bullmatch_private.claim_evidence ce on ce.claim_id=rcc.claim_id
        join bullmatch_private.evidence e on e.id=ce.evidence_id
        join bullmatch_private.source_items si on si.id=e.source_item_id
        join bullmatch_private.sources s on s.id=si.source_id
        where rcc.review_case_id=rc.id
      ),'[]'::jsonb),
      'entity_match_candidates',coalesce((
        select jsonb_agg(to_jsonb(emc) order by emc.match_score desc,emc.created_at,emc.id)
        from bullmatch_private.entity_match_candidates emc where emc.review_case_id=rc.id
      ),'[]'::jsonb),
      'duplicate_candidates',coalesce((
        select jsonb_agg(to_jsonb(dc) order by dc.score desc,dc.created_at,dc.id)
        from bullmatch_private.duplicate_candidates dc where dc.review_case_id=rc.id
      ),'[]'::jsonb),
      'history',coalesce((
        select jsonb_agg(jsonb_build_object(
          'id',ra.id,'actor_id',ra.actor_id,'actor_display_name',hu.display_name,'action',ra.action,
          'command_id',ra.command_id,'expected_case_version',ra.expected_case_version,
          'case_version_before',ra.case_version_before,'case_version_after',ra.case_version_after,
          'before_value',ra.before_value,'after_value',ra.after_value,'notes',ra.notes,'created_at',ra.created_at
        ) order by ra.created_at,ra.id)
        from bullmatch.review_actions ra
        left join bullmatch.app_users hu on hu.user_id=ra.actor_id
        where ra.review_case_id=rc.id
      ),'[]'::jsonb)
    ) into v_result
    from bullmatch.review_cases rc
    left join bullmatch.app_users au on au.user_id=rc.assigned_to
    where rc.id=p_id;
  else
    raise exception 'unsupported review resource: %',p_resource using errcode='22023';
  end case;
  return v_result;
end;$$;
revoke all on function public.bullmatch_api_review_query(uuid,text,uuid,integer,integer) from public,anon,authenticated;
grant execute on function public.bullmatch_api_review_query(uuid,text,uuid,integer,integer) to service_role;

create or replace function public.bullmatch_api_review_command(p_actor_id uuid,p_command jsonb)
returns jsonb language plpgsql security definer set search_path=''
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
  v_case bullmatch.review_cases%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_review_action_id uuid;
  v_existing bullmatch.review_actions%rowtype;
  v_claim_ids uuid[]:=array[]::uuid[];
  v_resolution text;
  v_updated integer;
begin
  v_role:=bullmatch_private.require_review_role(p_actor_id);
  if coalesce(v_command->>'schema_version','')<>'1.0.0' then raise exception 'unsupported review command schema_version' using errcode='22023'; end if;
  begin v_command_id:=(v_command->>'command_id')::uuid; exception when others then raise exception 'valid command_id UUID is required' using errcode='22023'; end;
  begin v_case_id:=(v_command->>'review_case_id')::uuid; exception when others then raise exception 'valid review_case_id UUID is required' using errcode='22023'; end;
  v_action:=upper(btrim(coalesce(v_command->>'action','')));
  v_expected_status:=upper(btrim(coalesce(v_command->>'expected_case_status','')));
  begin v_expected_version:=(v_command->>'expected_case_version')::bigint; exception when others then raise exception 'expected_case_version is required' using errcode='22023'; end;
  if v_expected_version<1 then raise exception 'expected_case_version must be >= 1' using errcode='22023'; end if;
  if v_expected_status not in ('OPEN','IN_REVIEW','RESOLVED','REJECTED','CANCELLED') then raise exception 'invalid expected_case_status' using errcode='22023'; end if;
  if jsonb_typeof(v_payload)<>'object' then raise exception 'payload must be an object' using errcode='22023'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>v_action then raise exception 'command_id already belongs to a different review command' using errcode='23505'; end if;
    return jsonb_build_object('ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,'review_case_id',v_existing.review_case_id,'action',v_existing.action,'case_version',v_existing.case_version_after);
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id for update;
  if not found then raise exception 'review case not found' using errcode='P0002'; end if;

  select * into v_existing from bullmatch.review_actions where command_id=v_command_id;
  if found then
    if v_existing.review_case_id<>v_case_id or v_existing.action<>v_action then raise exception 'command_id already belongs to a different review command' using errcode='23505'; end if;
    return jsonb_build_object('ok',true,'idempotent_replay',true,'review_action_id',v_existing.id,'review_case_id',v_existing.review_case_id,'action',v_existing.action,'case_version',v_existing.case_version_after);
  end if;

  if v_case.case_version<>v_expected_version or v_case.status<>v_expected_status then
    raise exception 'STALE_REVIEW_CASE expected %/% but current is %/%',v_expected_status,v_expected_version,v_case.status,v_case.case_version using errcode='40001';
  end if;
  v_before:=to_jsonb(v_case);

  if v_action='CLAIM' then
    if v_case.status not in ('OPEN','IN_REVIEW') then raise exception 'case cannot be claimed from status %',v_case.status using errcode='22023'; end if;
    if v_case.assigned_to is not null and v_case.assigned_to<>p_actor_id then raise exception 'review case is already assigned' using errcode='40001'; end if;
    update bullmatch.review_cases set assigned_to=p_actor_id,status='IN_REVIEW',case_version=case_version+1,updated_at=now() where id=v_case_id;
  elsif v_action='UNCLAIM' then
    if v_case.status<>'IN_REVIEW' then raise exception 'only IN_REVIEW cases can be unclaimed' using errcode='22023'; end if;
    if v_case.assigned_to is distinct from p_actor_id and v_role<>'ADMIN' then raise exception 'only the assigned reviewer or ADMIN can unclaim this case' using errcode='42501'; end if;
    update bullmatch.review_cases set assigned_to=null,status='OPEN',case_version=case_version+1,updated_at=now() where id=v_case_id;
  elsif v_action='COMMENT' then
    if v_note is null then raise exception 'COMMENT requires note' using errcode='22023'; end if;
    update bullmatch.review_cases set case_version=case_version+1,updated_at=now() where id=v_case_id;
  elsif v_action in ('APPROVE','REJECT','RESOLVE_CONFLICT') then
    if v_case.status not in ('OPEN','IN_REVIEW') then raise exception 'terminal claim decisions require OPEN or IN_REVIEW case' using errcode='22023'; end if;
    if v_action='RESOLVE_CONFLICT' and v_note is null then raise exception 'RESOLVE_CONFLICT requires note' using errcode='22023'; end if;
    if jsonb_typeof(v_payload->'claim_ids')='array' then
      select coalesce(array_agg(x::uuid),array[]::uuid[]) into v_claim_ids from jsonb_array_elements_text(v_payload->'claim_ids') t(x);
    end if;
    if cardinality(v_claim_ids)=0 then
      select coalesce(array_agg(rcc.claim_id order by rcc.claim_id),array[]::uuid[]) into v_claim_ids
      from bullmatch_private.review_case_claims rcc where rcc.review_case_id=v_case_id;
    end if;
    if cardinality(v_claim_ids)=0 then raise exception 'review case has no linked claim_ids to decide' using errcode='22023'; end if;
    if exists(select 1 from unnest(v_claim_ids) x where not exists(select 1 from bullmatch_private.review_case_claims rcc where rcc.review_case_id=v_case_id and rcc.claim_id=x)) then
      raise exception 'claim_ids must belong to this review case' using errcode='22023';
    end if;

    if v_action='APPROVE' then
      update bullmatch_private.claims set status='VERIFIED' where id=any(v_claim_ids) and status in ('PROPOSED','REVIEW_REQUIRED','CORROBORATED');
      get diagnostics v_updated=row_count;
      if v_updated<>cardinality(v_claim_ids) then raise exception 'APPROVE requires non-conflicted, non-terminal linked claims' using errcode='22023'; end if;
      update bullmatch.review_cases set status='RESOLVED',resolved_at=now(),resolved_by=p_actor_id,case_version=case_version+1,updated_at=now() where id=v_case_id;
    elsif v_action='REJECT' then
      update bullmatch_private.claims set status='REJECTED' where id=any(v_claim_ids) and status not in ('VERIFIED','SUPERSEDED','WITHDRAWN');
      get diagnostics v_updated=row_count;
      if v_updated<>cardinality(v_claim_ids) then raise exception 'REJECT cannot overwrite VERIFIED/SUPERSEDED/WITHDRAWN claim state' using errcode='22023'; end if;
      update bullmatch.review_cases set status='REJECTED',resolved_at=now(),resolved_by=p_actor_id,case_version=case_version+1,updated_at=now() where id=v_case_id;
    else
      v_resolution:=upper(btrim(coalesce(v_payload->>'resolution','')));
      if v_resolution not in ('VERIFIED','REJECTED','SUPERSEDED','CONFLICT') then raise exception 'RESOLVE_CONFLICT resolution must be VERIFIED, REJECTED, SUPERSEDED, or CONFLICT' using errcode='22023'; end if;
      update bullmatch_private.claims set status=v_resolution where id=any(v_claim_ids) and status<>'WITHDRAWN';
      get diagnostics v_updated=row_count;
      if v_updated<>cardinality(v_claim_ids) then raise exception 'cannot resolve WITHDRAWN claim' using errcode='22023'; end if;
      update bullmatch.review_cases
      set status=case when v_resolution='CONFLICT' then 'IN_REVIEW' else 'RESOLVED' end,
          resolved_at=case when v_resolution='CONFLICT' then null else now() end,
          resolved_by=case when v_resolution='CONFLICT' then null else p_actor_id end,
          case_version=case_version+1,updated_at=now()
      where id=v_case_id;
    end if;
  elsif v_action='REOPEN' then
    if v_case.status not in ('RESOLVED','REJECTED','CANCELLED') then raise exception 'only terminal review cases can be reopened' using errcode='22023'; end if;
    if v_note is null then raise exception 'REOPEN requires note' using errcode='22023'; end if;
    update bullmatch.review_cases set status='OPEN',assigned_to=null,resolved_at=null,resolved_by=null,case_version=case_version+1,updated_at=now() where id=v_case_id;
  elsif v_action in ('MERGE','SPLIT') then
    raise exception '% execution is not enabled in BMI-P1-008 foundation; use reviewed impact preview first',v_action using errcode='0A000';
  else
    raise exception 'review action % is not implemented in this foundation slice',v_action using errcode='0A000';
  end if;

  select * into v_case from bullmatch.review_cases where id=v_case_id;
  v_after:=to_jsonb(v_case);
  insert into bullmatch.review_actions(
    review_case_id,actor_id,command_id,action,expected_case_version,case_version_before,case_version_after,before_value,after_value,notes
  ) values (
    v_case_id,p_actor_id,v_command_id,v_action,v_expected_version,v_expected_version,v_case.case_version,v_before,v_after,v_note
  ) returning id into v_review_action_id;

  insert into bullmatch_private.audit_log(actor_type,actor_id,action,entity_type,entity_id,correlation_id,metadata)
  values('USER',p_actor_id::text,'REVIEW_'||v_action,'REVIEW_CASE',v_case_id,v_command_id,
    jsonb_build_object('review_action_id',v_review_action_id,'case_version_before',v_expected_version,'case_version_after',v_case.case_version,'claim_ids',to_jsonb(v_claim_ids),'canonical_mutation',false));

  return jsonb_build_object(
    'ok',true,'idempotent_replay',false,'review_action_id',v_review_action_id,'review_case_id',v_case_id,
    'action',v_action,'case_status',v_case.status,'case_version',v_case.case_version,
    'claim_ids',to_jsonb(v_claim_ids),'canonical_mutation',false
  );
end;$$;
revoke all on function public.bullmatch_api_review_command(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.bullmatch_api_review_command(uuid,jsonb) to service_role;
