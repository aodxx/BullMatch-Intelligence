-- BMI-APP-003 controlled API bridge regression test.
-- All fixtures are rollback-only.

DO $$
BEGIN
  if has_function_privilege('anon','public.bullmatch_api_public_query(text,uuid,text,integer,integer)','EXECUTE') then
    raise exception 'anon must not execute service bridge';
  end if;
  if has_function_privilege('authenticated','public.bullmatch_api_public_query(text,uuid,text,integer,integer)','EXECUTE') then
    raise exception 'authenticated must not execute service bridge';
  end if;
  if has_function_privilege('authenticated','public.bullmatch_api_admin_command(uuid,text,jsonb)','EXECUTE') then
    raise exception 'authenticated must not execute admin bridge';
  end if;
  if not has_function_privilege('service_role','public.bullmatch_api_public_query(text,uuid,text,integer,integer)','EXECUTE') then
    raise exception 'service_role needs bridge execute';
  end if;
END;
$$;

begin;
insert into auth.users(id,aud,role,email,is_sso_user,is_anonymous,created_at,updated_at)
values
('20000000-0000-0000-0000-000000000001','authenticated','authenticated','bmi-api-admin@example.invalid',false,false,now(),now()),
('20000000-0000-0000-0000-000000000002','authenticated','authenticated','bmi-api-reviewer@example.invalid',false,false,now(),now());
insert into bullmatch.app_users(user_id,display_name,role,status)
values
('20000000-0000-0000-0000-000000000001','API Test Admin','ADMIN','ACTIVE'),
('20000000-0000-0000-0000-000000000002','API Test Reviewer','REVIEWER','ACTIVE');

DO $$
DECLARE v jsonb; v_owner uuid; v_audits integer;
BEGIN
  v := public.bullmatch_api_member('20000000-0000-0000-0000-000000000001');
  if v->>'role' <> 'ADMIN' or (v->>'active')::boolean is not true then raise exception 'admin member lookup failed: %',v; end if;
  v := public.bullmatch_api_member('20000000-0000-0000-0000-000000000099');
  if (v->>'member')::boolean is not false then raise exception 'unknown member lookup failed: %',v; end if;

  v := public.bullmatch_api_admin_command('20000000-0000-0000-0000-000000000001','create_owner','{"name":"API Bridge Owner","province":"พัทลุง"}'::jsonb);
  v_owner := (v->>'id')::uuid;
  if not exists(select 1 from bullmatch.owners where id=v_owner and normalized_name='api bridge owner') then raise exception 'admin bridge failed'; end if;

  begin
    perform public.bullmatch_api_admin_command('20000000-0000-0000-0000-000000000002','create_owner','{"name":"Reviewer must fail"}'::jsonb);
    raise exception 'reviewer mutation unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;

  select count(*) into v_audits from bullmatch_private.audit_log where actor_id='20000000-0000-0000-0000-000000000001' and entity_id=v_owner;
  if v_audits < 1 then raise exception 'audit trail missing'; end if;
END;
$$;
rollback;
