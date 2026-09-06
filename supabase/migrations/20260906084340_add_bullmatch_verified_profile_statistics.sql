create view bullmatch.published_bull_match_history
with (security_invoker = true)
as
select
  mp.bull_id,
  mp.id as participant_id,
  mp.display_name_snapshot,
  mp.camp_id_snapshot,
  mp.owner_id_snapshot,
  mp.weight_kg,
  mp.age_months_estimate,
  mp.participant_result,
  m.id as match_id,
  m.match_date,
  m.date_precision,
  m.match_number,
  m.duration_seconds,
  m.result_detail,
  m.event_id,
  case when e.verification_status = 'VERIFIED' and e.archived_at is null then e.name else null end as event_name,
  case when e.verification_status = 'VERIFIED' and e.archived_at is null then e.event_date else null end as event_date,
  m.venue_id,
  case when v.verification_status = 'VERIFIED' and v.archived_at is null then v.name else null end as venue_name,
  case when v.verification_status = 'VERIFIED' and v.archived_at is null then v.province else null end as venue_province,
  mr.result_type,
  mr.result_reason,
  mr.verified_at as result_verified_at,
  m.published_at
from bullmatch.match_participants mp
join bullmatch.matches m on m.id = mp.match_id
join bullmatch.match_results mr on mr.match_id = m.id
join bullmatch.bulls b on b.id = mp.bull_id
left join bullmatch.events e on e.id = m.event_id
left join bullmatch.venues v on v.id = m.venue_id
where m.verification_status = 'VERIFIED'
  and m.published_at is not null
  and m.archived_at is null
  and mr.verified_at is not null
  and mr.result_type in ('WIN','DRAW','NO_RESULT','CANCELLED')
  and mp.participant_result in ('WIN','LOSS','DRAW','NO_RESULT','CANCELLED')
  and b.verification_status = 'VERIFIED'
  and b.archived_at is null;

create view bullmatch.published_bull_opponent_history
with (security_invoker = true)
as
select
  h.bull_id,
  h.match_id,
  h.match_date,
  h.date_precision,
  h.match_number,
  h.participant_result,
  h.result_type,
  h.event_id,
  h.event_name,
  h.venue_id,
  h.venue_name,
  h.venue_province,
  opp.bull_id as opponent_bull_id,
  opp.display_name_snapshot as opponent_display_name_snapshot,
  opp.camp_id_snapshot as opponent_camp_id_snapshot,
  opp.owner_id_snapshot as opponent_owner_id_snapshot,
  opp.weight_kg as opponent_weight_kg,
  opp.age_months_estimate as opponent_age_months_estimate,
  h.published_at
from bullmatch.published_bull_match_history h
join bullmatch.match_participants opp
  on opp.match_id = h.match_id
 and opp.id <> h.participant_id
join bullmatch.bulls opponent_bull
  on opponent_bull.id = opp.bull_id
 and opponent_bull.verification_status = 'VERIFIED'
 and opponent_bull.archived_at is null;

create view bullmatch.bull_basic_stats
with (security_invoker = true)
as
select
  b.id as bull_id,
  b.canonical_name,
  b.status as bull_status,
  b.current_camp_id,
  b.current_owner_id,
  count(h.match_id)::integer as published_matches,
  count(h.match_id) filter (where h.participant_result in ('WIN','LOSS','DRAW'))::integer as statistical_matches,
  count(h.match_id) filter (where h.participant_result = 'WIN')::integer as wins,
  count(h.match_id) filter (where h.participant_result = 'LOSS')::integer as losses,
  count(h.match_id) filter (where h.participant_result = 'DRAW')::integer as draws,
  count(h.match_id) filter (where h.participant_result = 'NO_RESULT')::integer as no_results,
  count(h.match_id) filter (where h.participant_result = 'CANCELLED')::integer as cancelled,
  case
    when count(h.match_id) filter (where h.participant_result in ('WIN','LOSS','DRAW')) = 0 then null
    else round(
      100.0 * count(h.match_id) filter (where h.participant_result = 'WIN')
      / count(h.match_id) filter (where h.participant_result in ('WIN','LOSS','DRAW')),
      2
    )
  end as win_rate_pct,
  max(h.match_date) as last_match_at
from bullmatch.bulls b
left join bullmatch.published_bull_match_history h on h.bull_id = b.id
where b.verification_status = 'VERIFIED'
  and b.archived_at is null
group by b.id, b.canonical_name, b.status, b.current_camp_id, b.current_owner_id;

create view bullmatch.bull_recent_form
with (security_invoker = true)
as
with ranked as (
  select
    h.bull_id,
    h.match_id,
    h.participant_result,
    h.match_date,
    h.published_at,
    row_number() over (
      partition by h.bull_id
      order by h.match_date desc nulls last, h.published_at desc, h.match_id desc
    ) as rn
  from bullmatch.published_bull_match_history h
  where h.participant_result in ('WIN','LOSS','DRAW')
)
select
  b.id as bull_id,
  coalesce(
    array_agg(r.participant_result order by r.rn) filter (where r.rn <= 5),
    array[]::text[]
  ) as recent_form,
  coalesce(
    array_agg(r.match_id order by r.rn) filter (where r.rn <= 5),
    array[]::uuid[]
  ) as recent_match_ids,
  count(r.match_id) filter (where r.rn <= 5)::integer as recent_form_count
from bullmatch.bulls b
left join ranked r on r.bull_id = b.id and r.rn <= 5
where b.verification_status = 'VERIFIED'
  and b.archived_at is null
group by b.id;

revoke all on bullmatch.published_bull_match_history from public, anon, authenticated;
revoke all on bullmatch.published_bull_opponent_history from public, anon, authenticated;
revoke all on bullmatch.bull_basic_stats from public, anon, authenticated;
revoke all on bullmatch.bull_recent_form from public, anon, authenticated;

grant select on bullmatch.published_bull_match_history to service_role;
grant select on bullmatch.published_bull_opponent_history to service_role;
grant select on bullmatch.bull_basic_stats to service_role;
grant select on bullmatch.bull_recent_form to service_role;
