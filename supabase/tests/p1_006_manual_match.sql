-- BMI-P1-006 manual match workflow integration test.
-- Rollback-only; no production data remains.

begin;

insert into auth.users(id,aud,role,email,is_sso_user,is_anonymous,created_at,updated_at)
values
('20000000-0000-0000-0000-000000000001','authenticated','authenticated','bmi-p1006-admin@example.invalid',false,false,now(),now()),
('20000000-0000-0000-0000-000000000002','authenticated','authenticated','bmi-p1006-reviewer@example.invalid',false,false,now(),now()),
('20000000-0000-0000-0000-000000000003','authenticated','authenticated','bmi-p1006-viewer@example.invalid',false,false,now(),now());

insert into bullmatch.app_users(user_id,display_name,role,status)
values
('20000000-0000-0000-0000-000000000001','P1-006 Admin','ADMIN','ACTIVE'),
('20000000-0000-0000-0000-000000000002','P1-006 Reviewer','REVIEWER','ACTIVE'),
('20000000-0000-0000-0000-000000000003','P1-006 Viewer','VIEWER','ACTIVE');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}',true);

DO $$
DECLARE
  v_owner uuid; v_camp uuid; v_venue uuid; v_bull_a uuid; v_bull_b uuid;
  v_event uuid; v_match uuid; v_match2 uuid; v_pa uuid; v_pb uuid; v_p2a uuid; v_p2b uuid;
  v_text text; v_status text; v_verified timestamptz; v_published timestamptz; v_count integer;
BEGIN
  v_owner := bullmatch.admin_create_owner('{"name":"เจ้าของ P1006","province":"พัทลุง"}'::jsonb);
  v_camp := bullmatch.admin_create_camp(jsonb_build_object('name','คอก P1006','owner_id',v_owner));
  v_venue := bullmatch.admin_create_venue('{"name":"สนาม P1006","province":"พัทลุง"}'::jsonb);
  v_bull_a := bullmatch.admin_create_bull(jsonb_build_object('canonical_name','วัวเอ เดิม','current_camp_id',v_camp,'current_owner_id',v_owner));
  v_bull_b := bullmatch.admin_create_bull(jsonb_build_object('canonical_name','วัวบี เดิม','current_camp_id',v_camp,'current_owner_id',v_owner));

  v_event := bullmatch.admin_create_event(jsonb_build_object('venue_id',v_venue,'name','งานทดสอบ P1006','event_date','2026-09-06','date_precision','EXACT'));
  perform bullmatch.admin_set_event_verification(v_event,'VERIFIED');
  v_match := bullmatch.admin_create_match(jsonb_build_object('event_id',v_event,'match_number',1,'match_date','2026-09-06T13:00:00+07:00','date_precision','EXACT'));

  v_pa := bullmatch.admin_add_match_participant(v_match,jsonb_build_object('bull_id',v_bull_a,'side','A','camp_id_snapshot',v_camp,'owner_id_snapshot',v_owner,'weight_kg',520.5,'age_months_estimate',48,'display_name_snapshot','วัวเอ ชื่อวันชน'));
  v_pb := bullmatch.admin_add_match_participant(v_match,jsonb_build_object('bull_id',v_bull_b,'side','B','camp_id_snapshot',v_camp,'owner_id_snapshot',v_owner,'weight_kg',515.0,'age_months_estimate',46,'display_name_snapshot','วัวบี ชื่อวันชน'));

  perform bullmatch.admin_update_bull(v_bull_a,'{"canonical_name":"วัวเอ ชื่อใหม่"}'::jsonb);
  select display_name_snapshot into v_text from bullmatch.match_participants where id=v_pa;
  if v_text <> 'วัวเอ ชื่อวันชน' then raise exception 'historical snapshot changed with bull profile'; end if;

  perform bullmatch.admin_set_match_result(v_match,'WIN',v_pa,'ผลทดสอบ');
  select participant_result into v_text from bullmatch.match_participants where id=v_pa;
  if v_text <> 'WIN' then raise exception 'winner result not synced'; end if;
  select participant_result into v_text from bullmatch.match_participants where id=v_pb;
  if v_text <> 'LOSS' then raise exception 'loser result not synced'; end if;
  select status into v_status from bullmatch.matches where id=v_match;
  if v_status <> 'COMPLETED' then raise exception 'match status not synced'; end if;

  begin
    perform bullmatch.admin_set_match_published(v_match,true);
    raise exception 'publish before verification unexpectedly succeeded';
  exception when raise_exception then
    if sqlerrm='publish before verification unexpectedly succeeded' then raise; end if;
  end;

  perform bullmatch.admin_set_match_verification(v_match,'VERIFIED');
  select verified_at into v_verified from bullmatch.match_results where match_id=v_match;
  if v_verified is null then raise exception 'result verification timestamp missing'; end if;
  perform bullmatch.admin_set_match_published(v_match,true);
  select published_at into v_published from bullmatch.matches where id=v_match;
  if v_published is null then raise exception 'publish timestamp missing'; end if;

  begin
    perform bullmatch.admin_update_match_participant(v_pa,'{"weight_kg":521}'::jsonb);
    raise exception 'published participant edit unexpectedly succeeded';
  exception when raise_exception then
    if sqlerrm='published participant edit unexpectedly succeeded' then raise; end if;
  end;

  perform bullmatch.admin_set_match_published(v_match,false);
  perform bullmatch.admin_update_match_participant(v_pa,'{"weight_kg":521}'::jsonb);
  select verification_status into v_status from bullmatch.matches where id=v_match;
  if v_status <> 'REVIEW_REQUIRED' then raise exception 'participant edit did not invalidate verification'; end if;
  select verified_at into v_verified from bullmatch.match_results where match_id=v_match;
  if v_verified is not null then raise exception 'participant edit did not clear result verification'; end if;

  perform bullmatch.admin_set_match_result(v_match,'DRAW',null,'แก้ไขผลเป็นเสมอ');
  select count(*) into v_count from bullmatch.match_participants where match_id=v_match and participant_result='DRAW';
  if v_count <> 2 then raise exception 'DRAW synchronization failed'; end if;
  perform bullmatch.admin_set_match_verification(v_match,'VERIFIED');
  perform bullmatch.admin_set_match_published(v_match,true);
  perform bullmatch.admin_set_match_published(v_match,false);

  v_match2 := bullmatch.admin_create_match(jsonb_build_object('event_id',v_event,'match_number',2));
  v_p2a := bullmatch.admin_add_match_participant(v_match2,jsonb_build_object('bull_id',v_bull_a,'side','A','display_name_snapshot','วัวเอ คู่สอง'));
  v_p2b := bullmatch.admin_add_match_participant(v_match2,jsonb_build_object('bull_id',v_bull_b,'side','B','display_name_snapshot','วัวบี คู่สอง'));

  begin
    perform bullmatch.admin_set_match_result(v_match2,'WIN',v_pa,'cross-match winner must fail');
    raise exception 'cross-match winner unexpectedly succeeded';
  exception when raise_exception then
    if sqlerrm='cross-match winner unexpectedly succeeded' then raise; end if;
  end;

  begin
    perform bullmatch.admin_set_match_result(v_match2,'DRAW',v_p2a,'draw cannot have winner');
    raise exception 'DRAW with winner unexpectedly succeeded';
  exception when raise_exception then
    if sqlerrm='DRAW with winner unexpectedly succeeded' then raise; end if;
  end;
END;
$$;

select set_config('request.jwt.claims','{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
DO $$ BEGIN
  begin perform bullmatch.admin_create_match('{}'::jsonb); raise exception 'reviewer mutation succeeded';
  exception when insufficient_privilege then null; end;
END $$;

select set_config('request.jwt.claims','{"sub":"20000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
DO $$ BEGIN
  begin perform bullmatch.admin_create_event('{}'::jsonb); raise exception 'viewer mutation succeeded';
  exception when insufficient_privilege then null; end;
END $$;

select set_config('request.jwt.claims','{"sub":"20000000-0000-0000-0000-000000000099","role":"authenticated"}',true);
DO $$ BEGIN
  begin perform bullmatch.admin_create_match('{}'::jsonb); raise exception 'non-member mutation succeeded';
  exception when insufficient_privilege then null; end;
END $$;

reset role;
DO $$
DECLARE v_count integer;
BEGIN
  select count(*) into v_count from bullmatch_private.audit_log where actor_id='20000000-0000-0000-0000-000000000001';
  if v_count < 20 then raise exception 'audit trail incomplete: %',v_count; end if;
END $$;

rollback;
