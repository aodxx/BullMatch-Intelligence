create schema if not exists bullmatch;
create schema if not exists bullmatch_private;

comment on schema bullmatch is 'BullMatch Intelligence canonical application and review data';
comment on schema bullmatch_private is 'BullMatch Intelligence private ingestion, AI, provenance and runtime data';

revoke all on schema bullmatch from public, anon, authenticated;
revoke all on schema bullmatch_private from public, anon, authenticated;

grant usage on schema bullmatch to authenticated;
grant usage on schema bullmatch to service_role;
grant usage on schema bullmatch_private to service_role;

create table bullmatch.app_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text null,
  role text not null check (role in ('ADMIN','REVIEWER','VIEWER')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','SUSPENDED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table bullmatch.app_users is 'BullMatch app-scoped membership and authorization role linked to shared Supabase Auth';

alter table bullmatch.app_users enable row level security;

revoke all on table bullmatch.app_users from public, anon, authenticated;
grant select on table bullmatch.app_users to authenticated;
grant all on table bullmatch.app_users to service_role;

create policy bullmatch_members_read_own_membership
on bullmatch.app_users
for select
to authenticated
using (user_id = (select auth.uid()));

alter default privileges in schema bullmatch revoke all on tables from public, anon, authenticated;
alter default privileges in schema bullmatch revoke all on sequences from public, anon, authenticated;
alter default privileges in schema bullmatch revoke all on functions from public, anon, authenticated;

alter default privileges in schema bullmatch_private revoke all on tables from public, anon, authenticated;
alter default privileges in schema bullmatch_private revoke all on sequences from public, anon, authenticated;
alter default privileges in schema bullmatch_private revoke all on functions from public, anon, authenticated;

alter default privileges in schema bullmatch grant all on tables to service_role;
alter default privileges in schema bullmatch grant all on sequences to service_role;
alter default privileges in schema bullmatch grant execute on functions to service_role;

alter default privileges in schema bullmatch_private grant all on tables to service_role;
alter default privileges in schema bullmatch_private grant all on sequences to service_role;
alter default privileges in schema bullmatch_private grant execute on functions to service_role;
