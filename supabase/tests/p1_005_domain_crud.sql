-- BMI-P1-005 controlled domain CRUD integration test.
-- Creates rollback-only Auth/membership fixtures. No production rows remain.

DO $$
DECLARE
  v_bad integer;
BEGIN
  select count(*) into v_bad
  from information_schema.role_table_grants
  where table_schema='bullmatch'
    and grantee in ('authenticated','anon')
    and privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER');
  if v_bad <> 0 then raise exception 'browser write grants detected: %',v_bad; end if;

  if has_schema_privilege('authenticated','bullmatch_private','USAGE') then
    raise exception 'authenticated unexpectedly has bullmatch_private USAGE';
  end if;

  if has_function_privilege('authenticated','bullmatch.require_admin()','EXECUTE') then
    raise exception 'internal require_admin helper must not be browser callable';
  end if;
  if has_function_privilege('authenticated','bullmatch.audit_domain_change(uuid,text,text,uuid,jsonb)','EXECUTE') then
    raise exception 'internal audit helper must not be browser callable';
  end if;
END;
$$;

begin;

insert into auth.users(id,aud,role,email,is_sso_user,is_anonymous,created_at,updated_at)
values
('10000000-0000-0000-0000-000000000001','authenticated','authenticated','bmi-admin-test@example.invalid',false,false,now(),now()),
('10000000-0000-0000-0000-000000000002','authenticated','authenticated','bmi-reviewer-test@example.invalid',false,false,now(),now()),
('10000000-0000-0000-0000-000000000003','authenticated','authenticated','bmi-viewer-test@example.invalid',false,false,now(),now());

insert into bullmatch.app_users(user_id,display_name,role,status)
values
('10000000-0000-0000-0000-000000000001','Test Admin','ADMIN','ACTIVE'),
('10000000-0000-0000-0000-000000000002','Test Reviewer','REVIEWER','ACTIVE'),
('10000000-0000-0000-0000-000000000003','Test Viewer','VIEWER','ACTIVE');

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',true);

DO $$
DECLARE
  v_owner uuid; v_camp uuid; v_bull uuid; v_venue uuid; v_alias uuid;
  v_norm text; v_status text; v_archived timestamptz;
BEGIN
  v_owner := bullmatch.admin_create_owner('{"name":"  นาย   ทดสอบ  ","province":"พัทลุง"}'::jsonb);
  select normalized_name,verification_status into v_norm,v_status from bullmatch.owners where id=v_owner;
  if v_norm <> 'นาย ทดสอบ' then raise exception 'normalization failed: %',v_norm; end if;
  if v_status <> 'UNVERIFIED' then raise exception 'new owner must be UNVERIFIED'; end if;

  v_camp := bullmatch.admin_create_camp(jsonb_build_object('name','คอก ทดสอบ','owner_id',v_owner,'province','พัทลุง'));
  v_bull := bullmatch.admin_create_bull(jsonb_build_object('canonical_name','  เจ้า   เพชรทอง  ','current_camp_id',v_camp,'current_owner_id',v_owner,'home_province','พัทลุง'));
  v_venue := bullmatch.admin_create_venue('{"name":"สนาม ทดสอบ","province":"พัทลุง","latitude":7.62,"longitude":100.08}'::jsonb);
  v_alias := bullmatch.admin_upsert_alias('BULL',v_bull,'เจ้าเพชรทอง','ALTERNATE_NAME',false);

  perform bullmatch.admin_update_owner(v_owner,'{"district":"เมืองพัทลุง"}'::jsonb);
  perform bullmatch.admin_set_entity_verification('OWNER',v_owner,'VERIFIED');
  perform bullmatch.admin_set_alias_verified('BULL',v_alias,true);
  perform bullmatch.admin_archive_entity('VENUE',v_venue,'rollback-only integration test');

  select verification_status into v_status from bullmatch.owners where id=v_owner;
  if v_status <> 'VERIFIED' then raise exception 'explicit verification failed'; end if;
  select archived_at into v_archived from bullmatch.venues where id=v_venue;
  if v_archived is null then raise exception 'archive failed'; end if;
END;
$$;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
DO $$
BEGIN
  begin
    perform bullmatch.admin_create_owner('{"name":"Reviewer must fail"}'::jsonb);
    raise exception 'reviewer mutation unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
END;
$$;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
DO $$
BEGIN
  begin
    perform bullmatch.admin_create_venue('{"name":"Viewer must fail"}'::jsonb);
    raise exception 'viewer mutation unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
END;
$$;

select set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000099","role":"authenticated"}',true);
DO $$
BEGIN
  begin
    perform bullmatch.admin_create_camp('{"name":"Non-member must fail"}'::jsonb);
    raise exception 'non-member mutation unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
END;
$$;

reset role;
DO $$
DECLARE v_audits integer;
BEGIN
  select count(*) into v_audits
  from bullmatch_private.audit_log
  where actor_id='10000000-0000-0000-0000-000000000001';
  if v_audits < 9 then raise exception 'audit trail incomplete: %',v_audits; end if;
END;
$$;

rollback;
