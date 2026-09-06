create or replace function bullmatch.normalize_entity_name(input_text text)
returns text
language sql
immutable
strict
security invoker
set search_path = ''
as $$
  select lower(regexp_replace(btrim(input_text), '[[:space:]]+', ' ', 'g'));
$$;
revoke all on function bullmatch.normalize_entity_name(text) from public, anon, authenticated;

create or replace function bullmatch.require_admin()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then
    raise insufficient_privilege using message = 'BullMatch ADMIN authentication required';
  end if;
  if not exists (
    select 1 from bullmatch.app_users au
    where au.user_id = v_user_id and au.status = 'ACTIVE' and au.role = 'ADMIN'
  ) then
    raise insufficient_privilege using message = 'BullMatch ACTIVE ADMIN role required';
  end if;
  return v_user_id;
end;
$$;
revoke all on function bullmatch.require_admin() from public, anon, authenticated;

create or replace function bullmatch.assert_allowed_json_keys(p_payload jsonb, p_allowed text[])
returns void
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  v_bad text;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'payload must be a JSON object';
  end if;
  select string_agg(k, ', ' order by k) into v_bad
  from jsonb_object_keys(p_payload) as t(k)
  where not (k = any(p_allowed));
  if v_bad is not null then raise exception 'unsupported payload field(s): %', v_bad; end if;
end;
$$;
revoke all on function bullmatch.assert_allowed_json_keys(jsonb,text[]) from public, anon, authenticated;

create or replace function bullmatch.audit_domain_change(
  p_actor_id uuid, p_action text, p_entity_type text, p_entity_id uuid, p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into bullmatch_private.audit_log(actor_type, actor_id, action, entity_type, entity_id, metadata)
  values ('USER', p_actor_id::text, p_action, p_entity_type, p_entity_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;
revoke all on function bullmatch.audit_domain_change(uuid,text,text,uuid,jsonb) from public, anon, authenticated;

create or replace function bullmatch.admin_create_owner(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data, array['name','province','district','notes']);
  v_name := nullif(btrim(p_data->>'name'), '');
  if v_name is null then raise exception 'owner name is required'; end if;
  insert into bullmatch.owners(name, normalized_name, province, district, notes, verification_status)
  values (v_name, bullmatch.normalize_entity_name(v_name), nullif(btrim(p_data->>'province'), ''), nullif(btrim(p_data->>'district'), ''), p_data->>'notes', 'UNVERIFIED')
  returning id into v_id;
  perform bullmatch.audit_domain_change(v_actor, 'OWNER_CREATED', 'OWNER', v_id,
    jsonb_build_object('after', (select to_jsonb(o) from bullmatch.owners o where o.id=v_id)));
  return v_id;
end;
$$;
revoke all on function bullmatch.admin_create_owner(jsonb) from public, anon;
grant execute on function bullmatch.admin_create_owner(jsonb) to authenticated;

create or replace function bullmatch.admin_update_owner(p_owner_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.owners%rowtype; v_after bullmatch.owners%rowtype; v_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch, array['name','province','district','notes']);
  select * into v_before from bullmatch.owners where id=p_owner_id and archived_at is null for update;
  if not found then raise exception 'active owner not found'; end if;
  if p_patch ? 'name' then
    v_name := nullif(btrim(p_patch->>'name'), '');
    if v_name is null then raise exception 'owner name cannot be empty'; end if;
  else v_name := v_before.name; end if;
  update bullmatch.owners
  set name=v_name,
      normalized_name=bullmatch.normalize_entity_name(v_name),
      province=case when p_patch ? 'province' then nullif(btrim(p_patch->>'province'),'') else province end,
      district=case when p_patch ? 'district' then nullif(btrim(p_patch->>'district'),'') else district end,
      notes=case when p_patch ? 'notes' then p_patch->>'notes' else notes end,
      updated_at=now()
  where id=p_owner_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor, 'OWNER_UPDATED', 'OWNER', p_owner_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_owner_id;
end;
$$;
revoke all on function bullmatch.admin_update_owner(uuid,jsonb) from public, anon;
grant execute on function bullmatch.admin_update_owner(uuid,jsonb) to authenticated;

create or replace function bullmatch.admin_create_camp(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_name text; v_owner_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data, array['name','owner_id','province','district','notes']);
  v_name := nullif(btrim(p_data->>'name'), '');
  if v_name is null then raise exception 'camp name is required'; end if;
  if p_data ? 'owner_id' and p_data->'owner_id' <> 'null'::jsonb then
    v_owner_id := (p_data->>'owner_id')::uuid;
    if not exists(select 1 from bullmatch.owners where id=v_owner_id and archived_at is null) then raise exception 'active owner_id not found'; end if;
  end if;
  insert into bullmatch.camps(name, normalized_name, owner_id, province, district, notes, verification_status)
  values (v_name, bullmatch.normalize_entity_name(v_name), v_owner_id, nullif(btrim(p_data->>'province'), ''), nullif(btrim(p_data->>'district'), ''), p_data->>'notes', 'UNVERIFIED')
  returning id into v_id;
  perform bullmatch.audit_domain_change(v_actor, 'CAMP_CREATED', 'CAMP', v_id,
    jsonb_build_object('after', (select to_jsonb(c) from bullmatch.camps c where c.id=v_id)));
  return v_id;
end;
$$;
revoke all on function bullmatch.admin_create_camp(jsonb) from public, anon;
grant execute on function bullmatch.admin_create_camp(jsonb) to authenticated;

create or replace function bullmatch.admin_update_camp(p_camp_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.camps%rowtype; v_after bullmatch.camps%rowtype; v_name text; v_owner_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch, array['name','owner_id','province','district','notes']);
  select * into v_before from bullmatch.camps where id=p_camp_id and archived_at is null for update;
  if not found then raise exception 'active camp not found'; end if;
  if p_patch ? 'name' then
    v_name := nullif(btrim(p_patch->>'name'), '');
    if v_name is null then raise exception 'camp name cannot be empty'; end if;
  else v_name := v_before.name; end if;
  if p_patch ? 'owner_id' then
    if p_patch->'owner_id' = 'null'::jsonb then v_owner_id := null;
    else
      v_owner_id := (p_patch->>'owner_id')::uuid;
      if not exists(select 1 from bullmatch.owners where id=v_owner_id and archived_at is null) then raise exception 'active owner_id not found'; end if;
    end if;
  else v_owner_id := v_before.owner_id; end if;
  update bullmatch.camps
  set name=v_name,
      normalized_name=bullmatch.normalize_entity_name(v_name),
      owner_id=v_owner_id,
      province=case when p_patch ? 'province' then nullif(btrim(p_patch->>'province'),'') else province end,
      district=case when p_patch ? 'district' then nullif(btrim(p_patch->>'district'),'') else district end,
      notes=case when p_patch ? 'notes' then p_patch->>'notes' else notes end,
      updated_at=now()
  where id=p_camp_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor, 'CAMP_UPDATED', 'CAMP', p_camp_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_camp_id;
end;
$$;
revoke all on function bullmatch.admin_update_camp(uuid,jsonb) from public, anon;
grant execute on function bullmatch.admin_update_camp(uuid,jsonb) to authenticated;
