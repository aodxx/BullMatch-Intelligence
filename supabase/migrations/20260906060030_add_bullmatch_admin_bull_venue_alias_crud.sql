create or replace function bullmatch.admin_create_bull(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_name text; v_camp_id uuid; v_owner_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data, array[
    'canonical_name','birth_date','birth_date_precision','sex','color_description','breed_description','lineage_notes',
    'current_camp_id','current_owner_id','home_province','home_district','status','primary_image_ref','notes'
  ]);
  v_name := nullif(btrim(p_data->>'canonical_name'), '');
  if v_name is null then raise exception 'bull canonical_name is required'; end if;

  if p_data ? 'current_camp_id' and p_data->'current_camp_id' <> 'null'::jsonb then
    v_camp_id := (p_data->>'current_camp_id')::uuid;
    if not exists(select 1 from bullmatch.camps where id=v_camp_id and archived_at is null) then raise exception 'active current_camp_id not found'; end if;
  end if;
  if p_data ? 'current_owner_id' and p_data->'current_owner_id' <> 'null'::jsonb then
    v_owner_id := (p_data->>'current_owner_id')::uuid;
    if not exists(select 1 from bullmatch.owners where id=v_owner_id and archived_at is null) then raise exception 'active current_owner_id not found'; end if;
  end if;

  insert into bullmatch.bulls(
    canonical_name, normalized_name, birth_date, birth_date_precision, sex,
    color_description, breed_description, lineage_notes, current_camp_id, current_owner_id,
    home_province, home_district, status, primary_image_ref, notes, verification_status
  ) values (
    v_name,
    bullmatch.normalize_entity_name(v_name),
    case when p_data ? 'birth_date' and p_data->'birth_date' <> 'null'::jsonb then (p_data->>'birth_date')::date else null end,
    nullif(p_data->>'birth_date_precision',''),
    coalesce(nullif(p_data->>'sex',''),'MALE'),
    p_data->>'color_description',
    p_data->>'breed_description',
    p_data->>'lineage_notes',
    v_camp_id,
    v_owner_id,
    nullif(btrim(p_data->>'home_province'),''),
    nullif(btrim(p_data->>'home_district'),''),
    coalesce(nullif(p_data->>'status',''),'ACTIVE'),
    p_data->>'primary_image_ref',
    p_data->>'notes',
    'UNVERIFIED'
  ) returning id into v_id;

  perform bullmatch.audit_domain_change(v_actor, 'BULL_CREATED', 'BULL', v_id,
    jsonb_build_object('after',(select to_jsonb(b) from bullmatch.bulls b where b.id=v_id)));
  return v_id;
end;
$$;
revoke all on function bullmatch.admin_create_bull(jsonb) from public, anon;
grant execute on function bullmatch.admin_create_bull(jsonb) to authenticated;

create or replace function bullmatch.admin_update_bull(p_bull_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.bulls%rowtype; v_after bullmatch.bulls%rowtype;
  v_name text; v_camp_id uuid; v_owner_id uuid;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch, array[
    'canonical_name','birth_date','birth_date_precision','sex','color_description','breed_description','lineage_notes',
    'current_camp_id','current_owner_id','home_province','home_district','status','primary_image_ref','notes'
  ]);
  select * into v_before from bullmatch.bulls where id=p_bull_id and archived_at is null for update;
  if not found then raise exception 'active bull not found'; end if;

  if p_patch ? 'canonical_name' then
    v_name := nullif(btrim(p_patch->>'canonical_name'), '');
    if v_name is null then raise exception 'bull canonical_name cannot be empty'; end if;
  else v_name := v_before.canonical_name; end if;

  if p_patch ? 'current_camp_id' then
    if p_patch->'current_camp_id' = 'null'::jsonb then v_camp_id := null;
    else
      v_camp_id := (p_patch->>'current_camp_id')::uuid;
      if not exists(select 1 from bullmatch.camps where id=v_camp_id and archived_at is null) then raise exception 'active current_camp_id not found'; end if;
    end if;
  else v_camp_id := v_before.current_camp_id; end if;

  if p_patch ? 'current_owner_id' then
    if p_patch->'current_owner_id' = 'null'::jsonb then v_owner_id := null;
    else
      v_owner_id := (p_patch->>'current_owner_id')::uuid;
      if not exists(select 1 from bullmatch.owners where id=v_owner_id and archived_at is null) then raise exception 'active current_owner_id not found'; end if;
    end if;
  else v_owner_id := v_before.current_owner_id; end if;

  update bullmatch.bulls
  set canonical_name=v_name,
      normalized_name=bullmatch.normalize_entity_name(v_name),
      birth_date=case when p_patch ? 'birth_date' then case when p_patch->'birth_date'='null'::jsonb then null else (p_patch->>'birth_date')::date end else birth_date end,
      birth_date_precision=case when p_patch ? 'birth_date_precision' then nullif(p_patch->>'birth_date_precision','') else birth_date_precision end,
      sex=case when p_patch ? 'sex' then p_patch->>'sex' else sex end,
      color_description=case when p_patch ? 'color_description' then p_patch->>'color_description' else color_description end,
      breed_description=case when p_patch ? 'breed_description' then p_patch->>'breed_description' else breed_description end,
      lineage_notes=case when p_patch ? 'lineage_notes' then p_patch->>'lineage_notes' else lineage_notes end,
      current_camp_id=v_camp_id,
      current_owner_id=v_owner_id,
      home_province=case when p_patch ? 'home_province' then nullif(btrim(p_patch->>'home_province'),'') else home_province end,
      home_district=case when p_patch ? 'home_district' then nullif(btrim(p_patch->>'home_district'),'') else home_district end,
      status=case when p_patch ? 'status' then p_patch->>'status' else status end,
      primary_image_ref=case when p_patch ? 'primary_image_ref' then p_patch->>'primary_image_ref' else primary_image_ref end,
      notes=case when p_patch ? 'notes' then p_patch->>'notes' else notes end,
      updated_at=now()
  where id=p_bull_id returning * into v_after;

  perform bullmatch.audit_domain_change(v_actor, 'BULL_UPDATED', 'BULL', p_bull_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_bull_id;
end;
$$;
revoke all on function bullmatch.admin_update_bull(uuid,jsonb) from public, anon;
grant execute on function bullmatch.admin_update_bull(uuid,jsonb) to authenticated;

create or replace function bullmatch.admin_create_venue(p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_id uuid; v_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data, array['name','province','district','address','latitude','longitude','status']);
  v_name := nullif(btrim(p_data->>'name'), '');
  if v_name is null then raise exception 'venue name is required'; end if;

  insert into bullmatch.venues(name,normalized_name,province,district,address,latitude,longitude,status,verification_status)
  values (
    v_name,
    bullmatch.normalize_entity_name(v_name),
    nullif(btrim(p_data->>'province'),''),
    nullif(btrim(p_data->>'district'),''),
    p_data->>'address',
    case when p_data ? 'latitude' and p_data->'latitude' <> 'null'::jsonb then (p_data->>'latitude')::numeric else null end,
    case when p_data ? 'longitude' and p_data->'longitude' <> 'null'::jsonb then (p_data->>'longitude')::numeric else null end,
    coalesce(nullif(p_data->>'status',''),'ACTIVE'),
    'UNVERIFIED'
  ) returning id into v_id;

  perform bullmatch.audit_domain_change(v_actor, 'VENUE_CREATED', 'VENUE', v_id,
    jsonb_build_object('after',(select to_jsonb(v) from bullmatch.venues v where v.id=v_id)));
  return v_id;
end;
$$;
revoke all on function bullmatch.admin_create_venue(jsonb) from public, anon;
grant execute on function bullmatch.admin_create_venue(jsonb) to authenticated;

create or replace function bullmatch.admin_update_venue(p_venue_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.venues%rowtype; v_after bullmatch.venues%rowtype; v_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch, array['name','province','district','address','latitude','longitude','status']);
  select * into v_before from bullmatch.venues where id=p_venue_id and archived_at is null for update;
  if not found then raise exception 'active venue not found'; end if;

  if p_patch ? 'name' then
    v_name := nullif(btrim(p_patch->>'name'), '');
    if v_name is null then raise exception 'venue name cannot be empty'; end if;
  else v_name := v_before.name; end if;

  update bullmatch.venues
  set name=v_name,
      normalized_name=bullmatch.normalize_entity_name(v_name),
      province=case when p_patch ? 'province' then nullif(btrim(p_patch->>'province'),'') else province end,
      district=case when p_patch ? 'district' then nullif(btrim(p_patch->>'district'),'') else district end,
      address=case when p_patch ? 'address' then p_patch->>'address' else address end,
      latitude=case when p_patch ? 'latitude' then case when p_patch->'latitude'='null'::jsonb then null else (p_patch->>'latitude')::numeric end else latitude end,
      longitude=case when p_patch ? 'longitude' then case when p_patch->'longitude'='null'::jsonb then null else (p_patch->>'longitude')::numeric end else longitude end,
      status=case when p_patch ? 'status' then p_patch->>'status' else status end,
      updated_at=now()
  where id=p_venue_id returning * into v_after;

  perform bullmatch.audit_domain_change(v_actor, 'VENUE_UPDATED', 'VENUE', p_venue_id,
    jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_venue_id;
end;
$$;
revoke all on function bullmatch.admin_update_venue(uuid,jsonb) from public, anon;
grant execute on function bullmatch.admin_update_venue(uuid,jsonb) to authenticated;

create or replace function bullmatch.admin_archive_entity(p_entity_type text, p_entity_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_type text := upper(btrim(p_entity_type)); v_reason text := nullif(btrim(p_reason),'');
  v_before jsonb; v_after jsonb;
begin
  v_actor := bullmatch.require_admin();
  if v_reason is null then raise exception 'archive reason is required'; end if;

  case v_type
    when 'OWNER' then
      select to_jsonb(o) into v_before from bullmatch.owners o where o.id=p_entity_id and o.archived_at is null for update;
      if v_before is null then raise exception 'active owner not found'; end if;
      update bullmatch.owners set archived_at=now(), archive_reason=v_reason, updated_at=now() where id=p_entity_id;
      select to_jsonb(o) into v_after from bullmatch.owners o where o.id=p_entity_id;
    when 'CAMP' then
      select to_jsonb(c) into v_before from bullmatch.camps c where c.id=p_entity_id and c.archived_at is null for update;
      if v_before is null then raise exception 'active camp not found'; end if;
      update bullmatch.camps set archived_at=now(), archive_reason=v_reason, updated_at=now() where id=p_entity_id;
      select to_jsonb(c) into v_after from bullmatch.camps c where c.id=p_entity_id;
    when 'BULL' then
      select to_jsonb(b) into v_before from bullmatch.bulls b where b.id=p_entity_id and b.archived_at is null for update;
      if v_before is null then raise exception 'active bull not found'; end if;
      update bullmatch.bulls set archived_at=now(), archive_reason=v_reason, updated_at=now() where id=p_entity_id;
      select to_jsonb(b) into v_after from bullmatch.bulls b where b.id=p_entity_id;
    when 'VENUE' then
      select to_jsonb(v) into v_before from bullmatch.venues v where v.id=p_entity_id and v.archived_at is null for update;
      if v_before is null then raise exception 'active venue not found'; end if;
      update bullmatch.venues set archived_at=now(), archive_reason=v_reason, updated_at=now() where id=p_entity_id;
      select to_jsonb(v) into v_after from bullmatch.venues v where v.id=p_entity_id;
    else raise exception 'unsupported entity_type: %', v_type;
  end case;

  perform bullmatch.audit_domain_change(v_actor, v_type || '_ARCHIVED', v_type, p_entity_id,
    jsonb_build_object('reason',v_reason,'before',v_before,'after',v_after));
  return p_entity_id;
end;
$$;
revoke all on function bullmatch.admin_archive_entity(text,uuid,text) from public, anon;
grant execute on function bullmatch.admin_archive_entity(text,uuid,text) to authenticated;

create or replace function bullmatch.admin_set_entity_verification(p_entity_type text, p_entity_id uuid, p_status text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_type text := upper(btrim(p_entity_type)); v_status text := upper(btrim(p_status));
  v_before jsonb; v_after jsonb;
begin
  v_actor := bullmatch.require_admin();
  if v_status not in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','REJECTED') then raise exception 'unsupported verification status: %', v_status; end if;

  case v_type
    when 'OWNER' then
      select to_jsonb(o) into v_before from bullmatch.owners o where o.id=p_entity_id and o.archived_at is null for update;
      if v_before is null then raise exception 'active owner not found'; end if;
      update bullmatch.owners set verification_status=v_status, updated_at=now() where id=p_entity_id;
      select to_jsonb(o) into v_after from bullmatch.owners o where o.id=p_entity_id;
    when 'CAMP' then
      select to_jsonb(c) into v_before from bullmatch.camps c where c.id=p_entity_id and c.archived_at is null for update;
      if v_before is null then raise exception 'active camp not found'; end if;
      update bullmatch.camps set verification_status=v_status, updated_at=now() where id=p_entity_id;
      select to_jsonb(c) into v_after from bullmatch.camps c where c.id=p_entity_id;
    when 'BULL' then
      select to_jsonb(b) into v_before from bullmatch.bulls b where b.id=p_entity_id and b.archived_at is null for update;
      if v_before is null then raise exception 'active bull not found'; end if;
      update bullmatch.bulls set verification_status=v_status, updated_at=now() where id=p_entity_id;
      select to_jsonb(b) into v_after from bullmatch.bulls b where b.id=p_entity_id;
    when 'VENUE' then
      select to_jsonb(v) into v_before from bullmatch.venues v where v.id=p_entity_id and v.archived_at is null for update;
      if v_before is null then raise exception 'active venue not found'; end if;
      update bullmatch.venues set verification_status=v_status, updated_at=now() where id=p_entity_id;
      select to_jsonb(v) into v_after from bullmatch.venues v where v.id=p_entity_id;
    else raise exception 'unsupported entity_type: %', v_type;
  end case;

  perform bullmatch.audit_domain_change(v_actor, v_type || '_VERIFICATION_CHANGED', v_type, p_entity_id,
    jsonb_build_object('before',v_before,'after',v_after));
  return p_entity_id;
end;
$$;
revoke all on function bullmatch.admin_set_entity_verification(text,uuid,text) from public, anon;
grant execute on function bullmatch.admin_set_entity_verification(text,uuid,text) to authenticated;

create or replace function bullmatch.admin_upsert_alias(
  p_entity_type text, p_entity_id uuid, p_alias text, p_alias_type text default null, p_verified boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_type text := upper(btrim(p_entity_type)); v_alias text := nullif(btrim(p_alias),'');
  v_normalized text; v_alias_id uuid;
begin
  v_actor := bullmatch.require_admin();
  if v_alias is null then raise exception 'alias is required'; end if;
  v_normalized := bullmatch.normalize_entity_name(v_alias);

  case v_type
    when 'OWNER' then
      if not exists(select 1 from bullmatch.owners where id=p_entity_id and archived_at is null) then raise exception 'active owner not found'; end if;
      insert into bullmatch.owner_aliases(owner_id,alias,normalized_alias,alias_type,verified,first_seen_at)
      values(p_entity_id,v_alias,v_normalized,p_alias_type,p_verified,now())
      on conflict(owner_id,normalized_alias) do update set alias=excluded.alias,alias_type=excluded.alias_type,verified=excluded.verified,updated_at=now()
      returning id into v_alias_id;
    when 'CAMP' then
      if not exists(select 1 from bullmatch.camps where id=p_entity_id and archived_at is null) then raise exception 'active camp not found'; end if;
      insert into bullmatch.camp_aliases(camp_id,alias,normalized_alias,alias_type,verified,first_seen_at)
      values(p_entity_id,v_alias,v_normalized,p_alias_type,p_verified,now())
      on conflict(camp_id,normalized_alias) do update set alias=excluded.alias,alias_type=excluded.alias_type,verified=excluded.verified,updated_at=now()
      returning id into v_alias_id;
    when 'BULL' then
      if not exists(select 1 from bullmatch.bulls where id=p_entity_id and archived_at is null) then raise exception 'active bull not found'; end if;
      insert into bullmatch.bull_aliases(bull_id,alias,normalized_alias,alias_type,verified,first_seen_at)
      values(p_entity_id,v_alias,v_normalized,p_alias_type,p_verified,now())
      on conflict(bull_id,normalized_alias) do update set alias=excluded.alias,alias_type=excluded.alias_type,verified=excluded.verified,updated_at=now()
      returning id into v_alias_id;
    when 'VENUE' then
      if not exists(select 1 from bullmatch.venues where id=p_entity_id and archived_at is null) then raise exception 'active venue not found'; end if;
      insert into bullmatch.venue_aliases(venue_id,alias,normalized_alias,alias_type,verified,first_seen_at)
      values(p_entity_id,v_alias,v_normalized,p_alias_type,p_verified,now())
      on conflict(venue_id,normalized_alias) do update set alias=excluded.alias,alias_type=excluded.alias_type,verified=excluded.verified,updated_at=now()
      returning id into v_alias_id;
    else raise exception 'unsupported entity_type: %', v_type;
  end case;

  perform bullmatch.audit_domain_change(v_actor, v_type || '_ALIAS_UPSERTED', v_type || '_ALIAS', v_alias_id,
    jsonb_build_object('canonical_entity_id',p_entity_id,'alias',v_alias,'normalized_alias',v_normalized,'verified',p_verified));
  return v_alias_id;
end;
$$;
revoke all on function bullmatch.admin_upsert_alias(text,uuid,text,text,boolean) from public, anon;
grant execute on function bullmatch.admin_upsert_alias(text,uuid,text,text,boolean) to authenticated;

create or replace function bullmatch.admin_set_alias_verified(p_entity_type text, p_alias_id uuid, p_verified boolean)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_type text := upper(btrim(p_entity_type)); v_entity_id uuid; v_before jsonb; v_after jsonb;
begin
  v_actor := bullmatch.require_admin();
  case v_type
    when 'OWNER' then
      select owner_id,to_jsonb(a) into v_entity_id,v_before from bullmatch.owner_aliases a where a.id=p_alias_id for update;
      if v_before is null then raise exception 'owner alias not found'; end if;
      update bullmatch.owner_aliases set verified=p_verified,updated_at=now() where id=p_alias_id;
      select to_jsonb(a) into v_after from bullmatch.owner_aliases a where a.id=p_alias_id;
    when 'CAMP' then
      select camp_id,to_jsonb(a) into v_entity_id,v_before from bullmatch.camp_aliases a where a.id=p_alias_id for update;
      if v_before is null then raise exception 'camp alias not found'; end if;
      update bullmatch.camp_aliases set verified=p_verified,updated_at=now() where id=p_alias_id;
      select to_jsonb(a) into v_after from bullmatch.camp_aliases a where a.id=p_alias_id;
    when 'BULL' then
      select bull_id,to_jsonb(a) into v_entity_id,v_before from bullmatch.bull_aliases a where a.id=p_alias_id for update;
      if v_before is null then raise exception 'bull alias not found'; end if;
      update bullmatch.bull_aliases set verified=p_verified,updated_at=now() where id=p_alias_id;
      select to_jsonb(a) into v_after from bullmatch.bull_aliases a where a.id=p_alias_id;
    when 'VENUE' then
      select venue_id,to_jsonb(a) into v_entity_id,v_before from bullmatch.venue_aliases a where a.id=p_alias_id for update;
      if v_before is null then raise exception 'venue alias not found'; end if;
      update bullmatch.venue_aliases set verified=p_verified,updated_at=now() where id=p_alias_id;
      select to_jsonb(a) into v_after from bullmatch.venue_aliases a where a.id=p_alias_id;
    else raise exception 'unsupported entity_type: %', v_type;
  end case;

  perform bullmatch.audit_domain_change(v_actor, v_type || '_ALIAS_VERIFICATION_CHANGED', v_type || '_ALIAS', p_alias_id,
    jsonb_build_object('canonical_entity_id',v_entity_id,'before',v_before,'after',v_after));
  return p_alias_id;
end;
$$;
revoke all on function bullmatch.admin_set_alias_verified(text,uuid,boolean) from public, anon;
grant execute on function bullmatch.admin_set_alias_verified(text,uuid,boolean) to authenticated;
