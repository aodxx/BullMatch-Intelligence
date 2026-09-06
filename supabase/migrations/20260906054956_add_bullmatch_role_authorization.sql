create or replace function bullmatch.has_active_role(allowed_roles text[])
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from bullmatch.app_users au
    where au.user_id = (select auth.uid())
      and au.status = 'ACTIVE'
      and au.role = any(allowed_roles)
  );
$$;

comment on function bullmatch.has_active_role(text[]) is
  'Checks current authenticated user against active BullMatch app membership. Uses app_users, not user-editable auth metadata.';

revoke all on function bullmatch.has_active_role(text[]) from public, anon;
grant execute on function bullmatch.has_active_role(text[]) to authenticated, service_role;

grant select on table
  bullmatch.owners,
  bullmatch.owner_aliases,
  bullmatch.camps,
  bullmatch.camp_aliases,
  bullmatch.bulls,
  bullmatch.bull_aliases,
  bullmatch.venues,
  bullmatch.venue_aliases,
  bullmatch.events,
  bullmatch.matches,
  bullmatch.match_participants,
  bullmatch.match_results,
  bullmatch.review_cases,
  bullmatch.review_actions
  to authenticated;

create policy owners_staff_read on bullmatch.owners for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy owner_aliases_staff_read on bullmatch.owner_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy camps_staff_read on bullmatch.camps for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy camp_aliases_staff_read on bullmatch.camp_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy bulls_staff_read on bullmatch.bulls for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy bull_aliases_staff_read on bullmatch.bull_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy venues_staff_read on bullmatch.venues for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy venue_aliases_staff_read on bullmatch.venue_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy events_staff_read on bullmatch.events for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy matches_staff_read on bullmatch.matches for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy match_participants_staff_read on bullmatch.match_participants for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy match_results_staff_read on bullmatch.match_results for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy review_cases_staff_read on bullmatch.review_cases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));
create policy review_actions_staff_read on bullmatch.review_actions for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])));

create policy owners_viewer_read_verified on bullmatch.owners for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null);
create policy owner_aliases_viewer_read_verified on bullmatch.owner_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.owners o where o.id=owner_aliases.owner_id and o.verification_status='VERIFIED' and o.archived_at is null));
create policy camps_viewer_read_verified on bullmatch.camps for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null);
create policy camp_aliases_viewer_read_verified on bullmatch.camp_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.camps c where c.id=camp_aliases.camp_id and c.verification_status='VERIFIED' and c.archived_at is null));
create policy bulls_viewer_read_verified on bullmatch.bulls for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null);
create policy bull_aliases_viewer_read_verified on bullmatch.bull_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.bulls b where b.id=bull_aliases.bull_id and b.verification_status='VERIFIED' and b.archived_at is null));
create policy venues_viewer_read_verified on bullmatch.venues for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null);
create policy venue_aliases_viewer_read_verified on bullmatch.venue_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.venues v where v.id=venue_aliases.venue_id and v.verification_status='VERIFIED' and v.archived_at is null));
create policy events_viewer_read_verified on bullmatch.events for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null);
create policy matches_viewer_read_published on bullmatch.matches for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and published_at is not null and archived_at is null);
create policy match_participants_viewer_read_published on bullmatch.match_participants for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and exists (select 1 from bullmatch.matches m where m.id=match_participants.match_id and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null));
create policy match_results_viewer_read_published on bullmatch.match_results for select to authenticated
using ((select bullmatch.has_active_role(array['VIEWER'])) and exists (select 1 from bullmatch.matches m where m.id=match_results.match_id and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null));

-- Intentionally no VIEWER policy for review_cases/review_actions.
-- Intentionally no authenticated INSERT/UPDATE/DELETE grants on canonical or review tables.
