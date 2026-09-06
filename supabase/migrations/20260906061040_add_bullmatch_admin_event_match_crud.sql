create or replace function bullmatch.admin_create_event(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_venue_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data, array['venue_id','name','event_date','start_time','date_precision','status','notes']);

  if p_data ? 'venue_id' and p_data->'venue_id' <> 'null'::jsonb then
    v_venue_id := (p_data->>'venue_id')::uuid;
    if not exists(select 1 from bullmatch.venues where id=v_venue_id and archived_at is null) then
      raise exception 'active venue_id not found';
    end if;
  end if;

  insert into bullmatch.events(venue_id,name,event_date,start_time,date_precision,status,notes,verification_status)
  values(
    v_venue_id,
    nullif(btrim(p_data->>'name'),''),
    case when p_data ? 'event_date' and p_data->'event_date' <> 'null'::jsonb then (p_data->>'event_date')::date else null end,
    case when p_data ? 'start_time' and p_data->'start_time' <> 'null'::jsonb then (p_data->>'start_time')::timestamptz else null end,
    coalesce(nullif(p_data->>'date_precision',''),'UNKNOWN'),
    coalesce(nullif(p_data->>'status',''),'SCHEDULED'),
    p_data->>'notes',
    'UNVERIFIED'
  ) returning id into v_id;

  perform bullmatch.audit_domain_change(v_actor,'EVENT_CREATED','EVENT',v_id,
    jsonb_build_object('after',(select to_jsonb(e) from bullmatch.events e where e.id=v_id)));
  return v_id;
end;
$$;

create or replace function bullmatch.admin_update_event(p_event_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.events%rowtype; v_after bullmatch.events%rowtype; v_venue_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch, array['venue_id','name','event_date','start_time','date_precision','status','notes']);
  select * into v_before from bullmatch.events where id=p_event_id and archived_at is null for update;
  if not found then raise exception 'active event not found'; end if;

  if p_patch ? 'venue_id' then
    if p_patch->'venue_id'='null'::jsonb then v_venue_id := null;
    else
      v_venue_id := (p_patch->>'venue_id')::uuid;
      if not exists(select 1 from bullmatch.venues where id=v_venue_id and archived_at is null) then raise exception 'active venue_id not found'; end if;
    end if;
    if v_venue_id is distinct from v_before.venue_id and exists(select 1 from bullmatch.matches where event_id=p_event_id and archived_at is null) then
      raise exception 'cannot change event venue after matches exist';
    end if;
  else v_venue_id := v_before.venue_id; end if;

  update bullmatch.events
  set venue_id=v_venue_id,
      name=case when p_patch ? 'name' then nullif(btrim(p_patch->>'name'),'') else name end,
      event_date=case when p_patch ? 'event_date' then case when p_patch->'event_date'='null'::jsonb then null else (p_patch->>'event_date')::date end else event_date end,
      start_time=case when p_patch ? 'start_time' then case when p_patch->'start_time'='null'::jsonb then null else (p_patch->>'start_time')::timestamptz end else start_time end,
      date_precision=case when p_patch ? 'date_precision' then p_patch->>'date_precision' else date_precision end,
      status=case when p_patch ? 'status' then p_patch->>'status' else status end,
      notes=case when p_patch ? 'notes' then p_patch->>'notes' else notes end,
      verification_status=case when verification_status='VERIFIED' then 'REVIEW_REQUIRED' else verification_status end,
      updated_at=now()
  where id=p_event_id returning * into v_after;

  perform bullmatch.audit_domain_change(v_actor,'EVENT_UPDATED','EVENT',p_event_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_event_id;
end;
$$;

create or replace function bullmatch.admin_set_event_verification(p_event_id uuid, p_status text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_status text := upper(btrim(p_status)); v_before bullmatch.events%rowtype; v_after bullmatch.events%rowtype;
begin
  v_actor := bullmatch.require_admin();
  if v_status not in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED') then raise exception 'unsupported event verification status: %',v_status; end if;
  select * into v_before from bullmatch.events where id=p_event_id and archived_at is null for update;
  if not found then raise exception 'active event not found'; end if;
  update bullmatch.events set verification_status=v_status,updated_at=now() where id=p_event_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor,'EVENT_VERIFICATION_CHANGED','EVENT',p_event_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_event_id;
end;
$$;

create or replace function bullmatch.admin_archive_event(p_event_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_reason text := nullif(btrim(p_reason),''); v_before bullmatch.events%rowtype; v_after bullmatch.events%rowtype;
begin
  v_actor := bullmatch.require_admin();
  if v_reason is null then raise exception 'archive reason is required'; end if;
  select * into v_before from bullmatch.events where id=p_event_id and archived_at is null for update;
  if not found then raise exception 'active event not found'; end if;
  update bullmatch.events set archived_at=now(),archive_reason=v_reason,updated_at=now() where id=p_event_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor,'EVENT_ARCHIVED','EVENT',p_event_id,
    jsonb_build_object('reason',v_reason,'before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_event_id;
end;
$$;

create or replace function bullmatch.admin_create_match(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_event_id uuid; v_venue_id uuid; v_event_venue uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data,array['event_id','venue_id','match_date','date_precision','match_number','status','duration_seconds','result_detail']);

  if p_data ? 'event_id' and p_data->'event_id' <> 'null'::jsonb then
    v_event_id := (p_data->>'event_id')::uuid;
    select venue_id into v_event_venue from bullmatch.events where id=v_event_id and archived_at is null;
    if not found then raise exception 'active event_id not found'; end if;
  end if;

  if p_data ? 'venue_id' and p_data->'venue_id' <> 'null'::jsonb then
    v_venue_id := (p_data->>'venue_id')::uuid;
    if not exists(select 1 from bullmatch.venues where id=v_venue_id and archived_at is null) then raise exception 'active venue_id not found'; end if;
  elsif v_event_venue is not null then
    v_venue_id := v_event_venue;
  end if;

  if v_event_venue is not null and v_venue_id is not null and v_event_venue <> v_venue_id then
    raise exception 'match venue must agree with event venue';
  end if;

  insert into bullmatch.matches(event_id,venue_id,match_date,date_precision,match_number,status,duration_seconds,result_detail,verification_status,published_at)
  values(
    v_event_id,
    v_venue_id,
    case when p_data ? 'match_date' and p_data->'match_date' <> 'null'::jsonb then (p_data->>'match_date')::timestamptz else null end,
    coalesce(nullif(p_data->>'date_precision',''),'UNKNOWN'),
    case when p_data ? 'match_number' and p_data->'match_number' <> 'null'::jsonb then (p_data->>'match_number')::integer else null end,
    coalesce(nullif(p_data->>'status',''),'SCHEDULED'),
    case when p_data ? 'duration_seconds' and p_data->'duration_seconds' <> 'null'::jsonb then (p_data->>'duration_seconds')::integer else null end,
    p_data->>'result_detail',
    'UNVERIFIED',
    null
  ) returning id into v_id;

  perform bullmatch.audit_domain_change(v_actor,'MATCH_CREATED','MATCH',v_id,
    jsonb_build_object('after',(select to_jsonb(m) from bullmatch.matches m where m.id=v_id)));
  return v_id;
end;
$$;

create or replace function bullmatch.admin_update_match(p_match_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.matches%rowtype; v_after bullmatch.matches%rowtype;
  v_event_id uuid; v_venue_id uuid; v_event_venue uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch,array['event_id','venue_id','match_date','date_precision','match_number','status','duration_seconds','result_detail']);
  select * into v_before from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_before.published_at is not null then raise exception 'unpublish match before editing facts'; end if;

  if p_patch ? 'event_id' then
    if p_patch->'event_id'='null'::jsonb then v_event_id := null;
    else
      v_event_id := (p_patch->>'event_id')::uuid;
      select venue_id into v_event_venue from bullmatch.events where id=v_event_id and archived_at is null;
      if not found then raise exception 'active event_id not found'; end if;
    end if;
  else
    v_event_id := v_before.event_id;
    if v_event_id is not null then select venue_id into v_event_venue from bullmatch.events where id=v_event_id; end if;
  end if;

  if p_patch ? 'venue_id' then
    if p_patch->'venue_id'='null'::jsonb then v_venue_id := null;
    else
      v_venue_id := (p_patch->>'venue_id')::uuid;
      if not exists(select 1 from bullmatch.venues where id=v_venue_id and archived_at is null) then raise exception 'active venue_id not found'; end if;
    end if;
  else v_venue_id := v_before.venue_id; end if;

  if v_event_venue is not null and v_venue_id is null then v_venue_id := v_event_venue; end if;
  if v_event_venue is not null and v_venue_id is not null and v_event_venue <> v_venue_id then raise exception 'match venue must agree with event venue'; end if;

  update bullmatch.matches
  set event_id=v_event_id,
      venue_id=v_venue_id,
      match_date=case when p_patch ? 'match_date' then case when p_patch->'match_date'='null'::jsonb then null else (p_patch->>'match_date')::timestamptz end else match_date end,
      date_precision=case when p_patch ? 'date_precision' then p_patch->>'date_precision' else date_precision end,
      match_number=case when p_patch ? 'match_number' then case when p_patch->'match_number'='null'::jsonb then null else (p_patch->>'match_number')::integer end else match_number end,
      status=case when p_patch ? 'status' then p_patch->>'status' else status end,
      duration_seconds=case when p_patch ? 'duration_seconds' then case when p_patch->'duration_seconds'='null'::jsonb then null else (p_patch->>'duration_seconds')::integer end else duration_seconds end,
      result_detail=case when p_patch ? 'result_detail' then p_patch->>'result_detail' else result_detail end,
      verification_status=case when verification_status='VERIFIED' then 'REVIEW_REQUIRED' else verification_status end,
      updated_at=now()
  where id=p_match_id returning * into v_after;

  if v_before.verification_status='VERIFIED' then
    update bullmatch.match_results set verified_at=null,updated_at=now() where match_id=p_match_id;
  end if;

  perform bullmatch.audit_domain_change(v_actor,'MATCH_UPDATED','MATCH',p_match_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_match_id;
end;
$$;

create or replace function bullmatch.admin_archive_match(p_match_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_reason text := nullif(btrim(p_reason),''); v_before bullmatch.matches%rowtype; v_after bullmatch.matches%rowtype;
begin
  v_actor := bullmatch.require_admin();
  if v_reason is null then raise exception 'archive reason is required'; end if;
  select * into v_before from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_before.published_at is not null then raise exception 'unpublish match before archiving'; end if;
  update bullmatch.matches set archived_at=now(),archive_reason=v_reason,updated_at=now() where id=p_match_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor,'MATCH_ARCHIVED','MATCH',p_match_id,
    jsonb_build_object('reason',v_reason,'before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_match_id;
end;
$$;

revoke execute on function bullmatch.admin_create_event(jsonb) from public, anon;
revoke execute on function bullmatch.admin_update_event(uuid,jsonb) from public, anon;
revoke execute on function bullmatch.admin_set_event_verification(uuid,text) from public, anon;
revoke execute on function bullmatch.admin_archive_event(uuid,text) from public, anon;
revoke execute on function bullmatch.admin_create_match(jsonb) from public, anon;
revoke execute on function bullmatch.admin_update_match(uuid,jsonb) from public, anon;
revoke execute on function bullmatch.admin_archive_match(uuid,text) from public, anon;

grant execute on function bullmatch.admin_create_event(jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_update_event(uuid,jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_set_event_verification(uuid,text) to authenticated, service_role;
grant execute on function bullmatch.admin_archive_event(uuid,text) to authenticated, service_role;
grant execute on function bullmatch.admin_create_match(jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_update_match(uuid,jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_archive_match(uuid,text) to authenticated, service_role;
