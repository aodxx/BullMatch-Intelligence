create or replace function bullmatch.sync_match_result_state()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update bullmatch.match_participants mp
  set participant_result = case
      when new.result_type = 'WIN' and mp.id = new.winner_participant_id then 'WIN'
      when new.result_type = 'WIN' then 'LOSS'
      when new.result_type = 'DRAW' then 'DRAW'
      when new.result_type = 'NO_RESULT' then 'NO_RESULT'
      when new.result_type = 'CANCELLED' then 'CANCELLED'
      else 'UNKNOWN'
    end,
    updated_at = now()
  where mp.match_id = new.match_id;

  update bullmatch.matches m
  set status = case
      when new.result_type in ('WIN','DRAW') then 'COMPLETED'
      when new.result_type = 'NO_RESULT' then 'NO_RESULT'
      when new.result_type = 'CANCELLED' then 'CANCELLED'
      else m.status
    end,
    updated_at = now()
  where m.id = new.match_id;

  return new;
end;
$$;

revoke all on function bullmatch.sync_match_result_state() from public, anon, authenticated;
grant execute on function bullmatch.sync_match_result_state() to service_role;

drop trigger if exists match_results_sync_state_trg on bullmatch.match_results;
create trigger match_results_sync_state_trg
after insert or update of result_type, winner_participant_id
on bullmatch.match_results
for each row execute function bullmatch.sync_match_result_state();

create or replace function bullmatch.admin_add_match_participant(p_match_id uuid, p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_match bullmatch.matches%rowtype; v_id uuid; v_bull_id uuid;
  v_side text; v_camp_id uuid; v_owner_id uuid; v_display_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_data,array['bull_id','side','camp_id_snapshot','owner_id_snapshot','weight_kg','age_months_estimate','display_name_snapshot','notes']);
  select * into v_match from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_match.published_at is not null then raise exception 'unpublish match before editing participants'; end if;

  if not (p_data ? 'bull_id') or p_data->'bull_id'='null'::jsonb then raise exception 'bull_id is required'; end if;
  v_bull_id := (p_data->>'bull_id')::uuid;
  select canonical_name into v_display_name from bullmatch.bulls where id=v_bull_id;
  if not found then raise exception 'bull_id not found'; end if;

  if p_data ? 'side' and p_data->'side' <> 'null'::jsonb then v_side := upper(btrim(p_data->>'side')); end if;
  if v_side is not null and v_side not in ('A','B','OTHER') then raise exception 'unsupported participant side: %',v_side; end if;

  if p_data ? 'camp_id_snapshot' and p_data->'camp_id_snapshot' <> 'null'::jsonb then
    v_camp_id := (p_data->>'camp_id_snapshot')::uuid;
    if not exists(select 1 from bullmatch.camps where id=v_camp_id) then raise exception 'camp_id_snapshot not found'; end if;
  end if;
  if p_data ? 'owner_id_snapshot' and p_data->'owner_id_snapshot' <> 'null'::jsonb then
    v_owner_id := (p_data->>'owner_id_snapshot')::uuid;
    if not exists(select 1 from bullmatch.owners where id=v_owner_id) then raise exception 'owner_id_snapshot not found'; end if;
  end if;
  if p_data ? 'display_name_snapshot' then v_display_name := nullif(btrim(p_data->>'display_name_snapshot'),''); end if;
  if v_display_name is null then raise exception 'display_name_snapshot is required'; end if;

  insert into bullmatch.match_participants(match_id,bull_id,side,camp_id_snapshot,owner_id_snapshot,weight_kg,age_months_estimate,display_name_snapshot,participant_result,notes)
  values(
    p_match_id,v_bull_id,v_side,v_camp_id,v_owner_id,
    case when p_data ? 'weight_kg' and p_data->'weight_kg' <> 'null'::jsonb then (p_data->>'weight_kg')::numeric else null end,
    case when p_data ? 'age_months_estimate' and p_data->'age_months_estimate' <> 'null'::jsonb then (p_data->>'age_months_estimate')::integer else null end,
    v_display_name,'UNKNOWN',p_data->>'notes'
  ) returning id into v_id;

  if v_match.verification_status <> 'UNVERIFIED' then update bullmatch.matches set verification_status='REVIEW_REQUIRED',updated_at=now() where id=p_match_id; end if;
  update bullmatch.match_results set verified_at=null,updated_at=now() where match_id=p_match_id;

  perform bullmatch.audit_domain_change(v_actor,'MATCH_PARTICIPANT_ADDED','MATCH_PARTICIPANT',v_id,
    jsonb_build_object('match_id',p_match_id,'after',(select to_jsonb(mp) from bullmatch.match_participants mp where mp.id=v_id)));
  return v_id;
end;
$$;

create or replace function bullmatch.admin_update_match_participant(p_participant_id uuid, p_patch jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.match_participants%rowtype; v_after bullmatch.match_participants%rowtype; v_match bullmatch.matches%rowtype;
  v_bull_id uuid; v_side text; v_camp_id uuid; v_owner_id uuid; v_display_name text;
begin
  v_actor := bullmatch.require_admin();
  perform bullmatch.assert_allowed_json_keys(p_patch,array['bull_id','side','camp_id_snapshot','owner_id_snapshot','weight_kg','age_months_estimate','display_name_snapshot','notes']);
  select * into v_before from bullmatch.match_participants where id=p_participant_id for update;
  if not found then raise exception 'match participant not found'; end if;
  select * into v_match from bullmatch.matches where id=v_before.match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_match.published_at is not null then raise exception 'unpublish match before editing participants'; end if;

  v_bull_id := v_before.bull_id;
  if p_patch ? 'bull_id' then
    if p_patch->'bull_id'='null'::jsonb then raise exception 'bull_id cannot be null'; end if;
    v_bull_id := (p_patch->>'bull_id')::uuid;
    if not exists(select 1 from bullmatch.bulls where id=v_bull_id) then raise exception 'bull_id not found'; end if;
  end if;

  v_side := v_before.side;
  if p_patch ? 'side' then
    if p_patch->'side'='null'::jsonb then v_side := null; else v_side := upper(btrim(p_patch->>'side')); end if;
    if v_side is not null and v_side not in ('A','B','OTHER') then raise exception 'unsupported participant side: %',v_side; end if;
  end if;

  v_camp_id := v_before.camp_id_snapshot;
  if p_patch ? 'camp_id_snapshot' then
    if p_patch->'camp_id_snapshot'='null'::jsonb then v_camp_id := null; else
      v_camp_id := (p_patch->>'camp_id_snapshot')::uuid;
      if not exists(select 1 from bullmatch.camps where id=v_camp_id) then raise exception 'camp_id_snapshot not found'; end if;
    end if;
  end if;

  v_owner_id := v_before.owner_id_snapshot;
  if p_patch ? 'owner_id_snapshot' then
    if p_patch->'owner_id_snapshot'='null'::jsonb then v_owner_id := null; else
      v_owner_id := (p_patch->>'owner_id_snapshot')::uuid;
      if not exists(select 1 from bullmatch.owners where id=v_owner_id) then raise exception 'owner_id_snapshot not found'; end if;
    end if;
  end if;

  v_display_name := v_before.display_name_snapshot;
  if p_patch ? 'display_name_snapshot' then v_display_name := nullif(btrim(p_patch->>'display_name_snapshot'),''); end if;
  if v_display_name is null then raise exception 'display_name_snapshot is required'; end if;

  update bullmatch.match_participants
  set bull_id=v_bull_id,side=v_side,camp_id_snapshot=v_camp_id,owner_id_snapshot=v_owner_id,
      weight_kg=case when p_patch ? 'weight_kg' then case when p_patch->'weight_kg'='null'::jsonb then null else (p_patch->>'weight_kg')::numeric end else weight_kg end,
      age_months_estimate=case when p_patch ? 'age_months_estimate' then case when p_patch->'age_months_estimate'='null'::jsonb then null else (p_patch->>'age_months_estimate')::integer end else age_months_estimate end,
      display_name_snapshot=v_display_name,
      notes=case when p_patch ? 'notes' then p_patch->>'notes' else notes end,
      updated_at=now()
  where id=p_participant_id returning * into v_after;

  if v_match.verification_status <> 'UNVERIFIED' then update bullmatch.matches set verification_status='REVIEW_REQUIRED',updated_at=now() where id=v_before.match_id; end if;
  update bullmatch.match_results set verified_at=null,updated_at=now() where match_id=v_before.match_id;

  perform bullmatch.audit_domain_change(v_actor,'MATCH_PARTICIPANT_UPDATED','MATCH_PARTICIPANT',p_participant_id,
    jsonb_build_object('match_id',v_before.match_id,'before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_participant_id;
end;
$$;

create or replace function bullmatch.admin_remove_match_participant(p_participant_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.match_participants%rowtype; v_match bullmatch.matches%rowtype;
begin
  v_actor := bullmatch.require_admin();
  select * into v_before from bullmatch.match_participants where id=p_participant_id for update;
  if not found then raise exception 'match participant not found'; end if;
  select * into v_match from bullmatch.matches where id=v_before.match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_match.published_at is not null then raise exception 'unpublish match before editing participants'; end if;
  if exists(select 1 from bullmatch.match_results where winner_participant_id=p_participant_id) then raise exception 'change match result before removing winner participant'; end if;

  delete from bullmatch.match_participants where id=p_participant_id;
  if v_match.verification_status <> 'UNVERIFIED' then update bullmatch.matches set verification_status='REVIEW_REQUIRED',updated_at=now() where id=v_before.match_id; end if;
  update bullmatch.match_results set verified_at=null,updated_at=now() where match_id=v_before.match_id;
  perform bullmatch.audit_domain_change(v_actor,'MATCH_PARTICIPANT_REMOVED','MATCH_PARTICIPANT',p_participant_id,jsonb_build_object('match_id',v_before.match_id,'before',to_jsonb(v_before)));
  return p_participant_id;
end;
$$;

create or replace function bullmatch.admin_set_match_result(p_match_id uuid, p_result_type text, p_winner_participant_id uuid default null, p_reason text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_match bullmatch.matches%rowtype; v_type text := upper(btrim(p_result_type)); v_id uuid; v_before jsonb;
begin
  v_actor := bullmatch.require_admin();
  select * into v_match from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_match.published_at is not null then raise exception 'unpublish match before changing result'; end if;
  if v_type not in ('WIN','DRAW','NO_RESULT','CANCELLED') then raise exception 'unsupported manual result type: %',v_type; end if;
  if (select count(*) from bullmatch.match_participants where match_id=p_match_id) < 2 then raise exception 'match result requires at least two participants'; end if;
  if v_type='WIN' then
    if p_winner_participant_id is null then raise exception 'WIN requires winner participant'; end if;
    if not exists(select 1 from bullmatch.match_participants where id=p_winner_participant_id and match_id=p_match_id) then raise exception 'winner participant must belong to same match'; end if;
  elsif p_winner_participant_id is not null then raise exception '% result cannot have winner participant',v_type;
  end if;

  select to_jsonb(mr) into v_before from bullmatch.match_results mr where mr.match_id=p_match_id;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,result_reason,verified_at)
  values(p_match_id,v_type,p_winner_participant_id,nullif(btrim(p_reason),''),null)
  on conflict(match_id) do update set result_type=excluded.result_type,winner_participant_id=excluded.winner_participant_id,result_reason=excluded.result_reason,verified_at=null,updated_at=now()
  returning id into v_id;

  update bullmatch.matches set verification_status=case when verification_status='UNVERIFIED' then 'UNVERIFIED' else 'REVIEW_REQUIRED' end,updated_at=now() where id=p_match_id;
  perform bullmatch.audit_domain_change(v_actor,'MATCH_RESULT_SET','MATCH_RESULT',v_id,
    jsonb_build_object('match_id',p_match_id,'before',v_before,'after',(select to_jsonb(mr) from bullmatch.match_results mr where mr.id=v_id)));
  return v_id;
end;
$$;

create or replace function bullmatch.admin_set_match_verification(p_match_id uuid, p_status text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_match bullmatch.matches%rowtype; v_status text := upper(btrim(p_status)); v_result bullmatch.match_results%rowtype; v_count integer;
begin
  v_actor := bullmatch.require_admin();
  if v_status not in ('UNVERIFIED','REVIEW_REQUIRED','VERIFIED','CONFLICT','REJECTED') then raise exception 'unsupported match verification status: %',v_status; end if;
  select * into v_match from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  if v_match.published_at is not null and v_status <> 'VERIFIED' then raise exception 'unpublish match before changing verification away from VERIFIED'; end if;

  if v_status='VERIFIED' then
    select count(*) into v_count from bullmatch.match_participants where match_id=p_match_id;
    if v_count < 2 then raise exception 'verified match requires at least two participants'; end if;
    select * into v_result from bullmatch.match_results where match_id=p_match_id;
    if not found or v_result.result_type='UNKNOWN' then raise exception 'verified match requires a known result'; end if;
    if (v_result.result_type in ('WIN','DRAW') and v_match.status <> 'COMPLETED') or (v_result.result_type='NO_RESULT' and v_match.status <> 'NO_RESULT') or (v_result.result_type='CANCELLED' and v_match.status <> 'CANCELLED') then raise exception 'match status is inconsistent with result'; end if;
    update bullmatch.match_results set verified_at=now(),updated_at=now() where match_id=p_match_id;
  else
    update bullmatch.match_results set verified_at=null,updated_at=now() where match_id=p_match_id;
  end if;

  update bullmatch.matches set verification_status=v_status,updated_at=now() where id=p_match_id;
  perform bullmatch.audit_domain_change(v_actor,'MATCH_VERIFICATION_CHANGED','MATCH',p_match_id,jsonb_build_object('before_status',v_match.verification_status,'after_status',v_status));
  return p_match_id;
end;
$$;

create or replace function bullmatch.admin_set_match_published(p_match_id uuid, p_publish boolean)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid; v_before bullmatch.matches%rowtype; v_after bullmatch.matches%rowtype;
begin
  v_actor := bullmatch.require_admin();
  select * into v_before from bullmatch.matches where id=p_match_id and archived_at is null for update;
  if not found then raise exception 'active match not found'; end if;
  update bullmatch.matches set published_at=case when p_publish then coalesce(published_at,now()) else null end,updated_at=now() where id=p_match_id returning * into v_after;
  perform bullmatch.audit_domain_change(v_actor,case when p_publish then 'MATCH_PUBLISHED' else 'MATCH_UNPUBLISHED' end,'MATCH',p_match_id,jsonb_build_object('before',to_jsonb(v_before),'after',to_jsonb(v_after)));
  return p_match_id;
end;
$$;

create or replace function bullmatch.enforce_match_publication_integrity()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  participant_count integer; v_result bullmatch.match_results%rowtype; mismatch_count integer;
begin
  if new.published_at is null then return new; end if;
  if new.verification_status <> 'VERIFIED' then raise exception 'only VERIFIED matches may be published'; end if;
  select count(*) into participant_count from bullmatch.match_participants where match_id=new.id;
  if participant_count < 2 then raise exception 'published match requires at least two participants'; end if;
  select * into v_result from bullmatch.match_results where match_id=new.id;
  if not found or v_result.result_type='UNKNOWN' then raise exception 'published match requires a known result'; end if;
  if v_result.verified_at is null then raise exception 'published match requires verified result'; end if;
  if (v_result.result_type in ('WIN','DRAW') and new.status <> 'COMPLETED') or (v_result.result_type='NO_RESULT' and new.status <> 'NO_RESULT') or (v_result.result_type='CANCELLED' and new.status <> 'CANCELLED') then raise exception 'published match status is inconsistent with result'; end if;

  select count(*) into mismatch_count from bullmatch.match_participants mp
  where mp.match_id=new.id and mp.participant_result is distinct from case
    when v_result.result_type='WIN' and mp.id=v_result.winner_participant_id then 'WIN'
    when v_result.result_type='WIN' then 'LOSS'
    when v_result.result_type='DRAW' then 'DRAW'
    when v_result.result_type='NO_RESULT' then 'NO_RESULT'
    when v_result.result_type='CANCELLED' then 'CANCELLED'
    else 'UNKNOWN' end;
  if mismatch_count > 0 then raise exception 'participant result state is inconsistent with match result'; end if;
  return new;
end;
$$;

revoke all on function bullmatch.sync_match_result_state() from public, anon, authenticated;
revoke execute on function bullmatch.admin_add_match_participant(uuid,jsonb) from public, anon;
revoke execute on function bullmatch.admin_update_match_participant(uuid,jsonb) from public, anon;
revoke execute on function bullmatch.admin_remove_match_participant(uuid) from public, anon;
revoke execute on function bullmatch.admin_set_match_result(uuid,text,uuid,text) from public, anon;
revoke execute on function bullmatch.admin_set_match_verification(uuid,text) from public, anon;
revoke execute on function bullmatch.admin_set_match_published(uuid,boolean) from public, anon;

grant execute on function bullmatch.admin_add_match_participant(uuid,jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_update_match_participant(uuid,jsonb) to authenticated, service_role;
grant execute on function bullmatch.admin_remove_match_participant(uuid) to authenticated, service_role;
grant execute on function bullmatch.admin_set_match_result(uuid,text,uuid,text) to authenticated, service_role;
grant execute on function bullmatch.admin_set_match_verification(uuid,text) to authenticated, service_role;
grant execute on function bullmatch.admin_set_match_published(uuid,boolean) to authenticated, service_role;
