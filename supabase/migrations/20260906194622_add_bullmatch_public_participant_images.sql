-- BMI-APP-004: expose canonical bull primary_image_ref in published match participant payloads.
-- This preserves the existing service-role-only RPC boundary and all publication filters.

create or replace function public.bullmatch_api_public_query(
  p_resource text,
  p_id uuid default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
  v_offset integer := greatest(coalesce(p_offset, 0), 0);
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_result jsonb;
begin
  case upper(coalesce(p_resource, ''))
    when 'DASHBOARD' then
      select jsonb_build_object(
        'bulls', (select count(*) from bullmatch.bull_basic_stats),
        'published_matches', (select count(*) from bullmatch.matches m where m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null),
        'venues', (select count(*) from bullmatch.venues v where v.verification_status='VERIFIED' and v.archived_at is null),
        'last_published_at', (select max(m.published_at) from bullmatch.matches m where m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null)
      ) into v_result;

    when 'BULLS' then
      select coalesce(jsonb_agg(to_jsonb(q) order by q.canonical_name, q.id), '[]'::jsonb) into v_result
      from (
        select s.bull_id as id,s.canonical_name,b.home_province,b.home_district,b.color_description,b.breed_description,b.status,
          case when c.verification_status='VERIFIED' and c.archived_at is null then c.name else null end as camp_name,
          case when o.verification_status='VERIFIED' and o.archived_at is null then o.name else null end as owner_name,
          s.published_matches,s.statistical_matches,s.wins,s.losses,s.draws,s.no_results,s.cancelled,s.win_rate_pct,s.last_match_at,
          coalesce(f.recent_form,array[]::text[]) as recent_form
        from bullmatch.bull_basic_stats s
        join bullmatch.bulls b on b.id=s.bull_id
        left join bullmatch.camps c on c.id=b.current_camp_id
        left join bullmatch.owners o on o.id=b.current_owner_id
        left join bullmatch.bull_recent_form f on f.bull_id=b.id
        where v_search is null or b.canonical_name ilike '%'||v_search||'%' or coalesce(b.home_province,'') ilike '%'||v_search||'%' or coalesce(c.name,'') ilike '%'||v_search||'%'
        order by s.canonical_name,s.bull_id limit v_limit offset v_offset
      ) q;

    when 'BULL' then
      if p_id is null then raise exception 'p_id is required for BULL' using errcode='22023'; end if;
      select jsonb_build_object(
        'bull',jsonb_build_object('id',b.id,'canonical_name',b.canonical_name,'birth_date',b.birth_date,'birth_date_precision',b.birth_date_precision,
          'color_description',b.color_description,'breed_description',b.breed_description,'home_province',b.home_province,'home_district',b.home_district,
          'status',b.status,'primary_image_ref',b.primary_image_ref,
          'camp',case when c.verification_status='VERIFIED' and c.archived_at is null then jsonb_build_object('id',c.id,'name',c.name,'province',c.province,'district',c.district) else null end,
          'owner',case when o.verification_status='VERIFIED' and o.archived_at is null then jsonb_build_object('id',o.id,'name',o.name,'province',o.province,'district',o.district) else null end),
        'stats',to_jsonb(s),'recent_form',coalesce(to_jsonb(f.recent_form),'[]'::jsonb),
        'history',coalesce((select jsonb_agg(jsonb_build_object(
          'match_id',h.match_id,'match_date',h.match_date,'date_precision',h.date_precision,'match_number',h.match_number,'result',h.participant_result,
          'result_type',h.result_type,'event_id',h.event_id,'event_name',h.event_name,'venue_id',h.venue_id,'venue_name',h.venue_name,
          'venue_province',h.venue_province,'opponent_bull_id',h.opponent_bull_id,'opponent_name',h.opponent_display_name_snapshot,
          'opponent_weight_kg',h.opponent_weight_kg,'opponent_age_months_estimate',h.opponent_age_months_estimate,'published_at',h.published_at)
          order by h.match_date desc nulls last,h.published_at desc,h.match_id desc) from bullmatch.published_bull_opponent_history h where h.bull_id=b.id),'[]'::jsonb)
      ) into v_result
      from bullmatch.bulls b join bullmatch.bull_basic_stats s on s.bull_id=b.id
      left join bullmatch.bull_recent_form f on f.bull_id=b.id left join bullmatch.camps c on c.id=b.current_camp_id left join bullmatch.owners o on o.id=b.current_owner_id
      where b.id=p_id and b.verification_status='VERIFIED' and b.archived_at is null;

    when 'MATCHES' then
      select coalesce(jsonb_agg(q.item order by q.match_date desc nulls last,q.published_at desc,q.match_id desc),'[]'::jsonb) into v_result
      from (
        select m.id as match_id,m.match_date,m.published_at,
          jsonb_build_object('id',m.id,'match_date',m.match_date,'date_precision',m.date_precision,'match_number',m.match_number,'status',m.status,
            'duration_seconds',m.duration_seconds,'result_detail',m.result_detail,'published_at',m.published_at,
            'event',case when e.verification_status='VERIFIED' and e.archived_at is null then jsonb_build_object('id',e.id,'name',e.name,'event_date',e.event_date) else null end,
            'venue',case when v.verification_status='VERIFIED' and v.archived_at is null then jsonb_build_object('id',v.id,'name',v.name,'province',v.province,'district',v.district) else null end,
            'result',jsonb_build_object('type',mr.result_type,'reason',mr.result_reason,'verified_at',mr.verified_at),
            'participants',coalesce((select jsonb_agg(jsonb_build_object(
              'id',mp.id,'bull_id',mp.bull_id,'side',mp.side,'display_name',mp.display_name_snapshot,
              'primary_image_ref',pb.primary_image_ref,
              'weight_kg',mp.weight_kg,'age_months_estimate',mp.age_months_estimate,'result',mp.participant_result
            ) order by mp.side,mp.id)
              from bullmatch.match_participants mp
              join bullmatch.bulls pb on pb.id=mp.bull_id and pb.verification_status='VERIFIED' and pb.archived_at is null
              where mp.match_id=m.id),'[]'::jsonb)) as item
        from bullmatch.matches m join bullmatch.match_results mr on mr.match_id=m.id and mr.verified_at is not null and mr.result_type<>'UNKNOWN'
        left join bullmatch.events e on e.id=m.event_id left join bullmatch.venues v on v.id=m.venue_id
        where m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null
          and not exists(select 1 from bullmatch.match_participants mp0 join bullmatch.bulls b0 on b0.id=mp0.bull_id where mp0.match_id=m.id and (b0.verification_status<>'VERIFIED' or b0.archived_at is not null))
        order by m.match_date desc nulls last,m.published_at desc,m.id desc limit v_limit offset v_offset
      ) q;

    when 'MATCH' then
      if p_id is null then raise exception 'p_id is required for MATCH' using errcode='22023'; end if;
      select jsonb_build_object('id',m.id,'match_date',m.match_date,'date_precision',m.date_precision,'match_number',m.match_number,'status',m.status,
        'duration_seconds',m.duration_seconds,'result_detail',m.result_detail,'published_at',m.published_at,
        'event',case when e.verification_status='VERIFIED' and e.archived_at is null then jsonb_build_object('id',e.id,'name',e.name,'event_date',e.event_date,'start_time',e.start_time) else null end,
        'venue',case when v.verification_status='VERIFIED' and v.archived_at is null then jsonb_build_object('id',v.id,'name',v.name,'province',v.province,'district',v.district) else null end,
        'result',jsonb_build_object('type',mr.result_type,'winner_participant_id',mr.winner_participant_id,'reason',mr.result_reason,'verified_at',mr.verified_at),
        'participants',coalesce((select jsonb_agg(jsonb_build_object(
          'id',mp.id,'bull_id',mp.bull_id,'side',mp.side,'display_name',mp.display_name_snapshot,
          'primary_image_ref',pb.primary_image_ref,
          'camp_id_snapshot',mp.camp_id_snapshot,'owner_id_snapshot',mp.owner_id_snapshot,
          'weight_kg',mp.weight_kg,'age_months_estimate',mp.age_months_estimate,'result',mp.participant_result
        ) order by mp.side,mp.id)
          from bullmatch.match_participants mp
          join bullmatch.bulls pb on pb.id=mp.bull_id and pb.verification_status='VERIFIED' and pb.archived_at is null
          where mp.match_id=m.id),'[]'::jsonb)) into v_result
      from bullmatch.matches m join bullmatch.match_results mr on mr.match_id=m.id and mr.verified_at is not null and mr.result_type<>'UNKNOWN'
      left join bullmatch.events e on e.id=m.event_id left join bullmatch.venues v on v.id=m.venue_id
      where m.id=p_id and m.verification_status='VERIFIED' and m.published_at is not null and m.archived_at is null
        and not exists(select 1 from bullmatch.match_participants mp0 join bullmatch.bulls b0 on b0.id=mp0.bull_id where mp0.match_id=m.id and (b0.verification_status<>'VERIFIED' or b0.archived_at is not null));

    when 'VENUES' then
      select coalesce(jsonb_agg(to_jsonb(q) order by q.name,q.id),'[]'::jsonb) into v_result
      from (select id,name,province,district,status from bullmatch.venues where verification_status='VERIFIED' and archived_at is null
        and (v_search is null or name ilike '%'||v_search||'%' or coalesce(province,'') ilike '%'||v_search||'%') order by name,id limit v_limit offset v_offset) q;
    else raise exception 'unsupported public resource: %',p_resource using errcode='22023';
  end case;
  return v_result;
end;
$$;

revoke all on function public.bullmatch_api_public_query(text,uuid,text,integer,integer) from public,anon,authenticated;
grant execute on function public.bullmatch_api_public_query(text,uuid,text,integer,integer) to service_role;
