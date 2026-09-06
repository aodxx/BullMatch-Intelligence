drop policy if exists owners_staff_read on bullmatch.owners;
drop policy if exists owners_viewer_read_verified on bullmatch.owners;
create policy owners_authorized_read on bullmatch.owners for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null));

drop policy if exists owner_aliases_staff_read on bullmatch.owner_aliases;
drop policy if exists owner_aliases_viewer_read_verified on bullmatch.owner_aliases;
create policy owner_aliases_authorized_read on bullmatch.owner_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.owners o where o.id=owner_aliases.owner_id and o.verification_status='VERIFIED' and o.archived_at is null)));

drop policy if exists camps_staff_read on bullmatch.camps;
drop policy if exists camps_viewer_read_verified on bullmatch.camps;
create policy camps_authorized_read on bullmatch.camps for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null));

drop policy if exists camp_aliases_staff_read on bullmatch.camp_aliases;
drop policy if exists camp_aliases_viewer_read_verified on bullmatch.camp_aliases;
create policy camp_aliases_authorized_read on bullmatch.camp_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.camps c where c.id=camp_aliases.camp_id and c.verification_status='VERIFIED' and c.archived_at is null)));

drop policy if exists bulls_staff_read on bullmatch.bulls;
drop policy if exists bulls_viewer_read_verified on bullmatch.bulls;
create policy bulls_authorized_read on bullmatch.bulls for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null));

drop policy if exists bull_aliases_staff_read on bullmatch.bull_aliases;
drop policy if exists bull_aliases_viewer_read_verified on bullmatch.bull_aliases;
create policy bull_aliases_authorized_read on bullmatch.bull_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.bulls b where b.id=bull_aliases.bull_id and b.verification_status='VERIFIED' and b.archived_at is null)));

drop policy if exists venues_staff_read on bullmatch.venues;
drop policy if exists venues_viewer_read_verified on bullmatch.venues;
create policy venues_authorized_read on bullmatch.venues for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null));

drop policy if exists venue_aliases_staff_read on bullmatch.venue_aliases;
drop policy if exists venue_aliases_viewer_read_verified on bullmatch.venue_aliases;
create policy venue_aliases_authorized_read on bullmatch.venue_aliases for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verified and exists (select 1 from bullmatch.venues v where v.id=venue_aliases.venue_id and v.verification_status='VERIFIED' and v.archived_at is null)));

drop policy if exists events_staff_read on bullmatch.events;
drop policy if exists events_viewer_read_verified on bullmatch.events;
create policy events_authorized_read on bullmatch.events for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and archived_at is null));

drop policy if exists matches_staff_read on bullmatch.matches;
drop policy if exists matches_viewer_read_published on bullmatch.matches;
create policy matches_authorized_read on bullmatch.matches for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and verification_status='VERIFIED' and published_at is not null and archived_at is null));

drop policy if exists match_participants_staff_read on bullmatch.match_participants;
drop policy if exists match_participants_viewer_read_published on bullmatch.match_participants;
create policy match_participants_authorized_read on bullmatch.match_participants for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and exists (select 1 from bullmatch.matches m where m.id=match_participants.match_id and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null)));

drop policy if exists match_results_staff_read on bullmatch.match_results;
drop policy if exists match_results_viewer_read_published on bullmatch.match_results;
create policy match_results_authorized_read on bullmatch.match_results for select to authenticated
using ((select bullmatch.has_active_role(array['ADMIN','REVIEWER'])) or ((select bullmatch.has_active_role(array['VIEWER'])) and exists (select 1 from bullmatch.matches m where m.id=match_results.match_id and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null)));
