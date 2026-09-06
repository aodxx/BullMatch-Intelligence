begin;

do $$
declare
  v_bull uuid;
  v_opp uuid;
  v_unverified_bull uuid;
  v_match uuid;
  v_p1 uuid;
  v_p2 uuid;
  v_stats record;
  v_form text[];
  v_history_count integer;
  v_opp_count integer;
  v_snapshot text;
begin
  insert into bullmatch.bulls(canonical_name, normalized_name, verification_status)
  values ('ทดสอบ วัวหลัก ชื่อใหม่ภายหลัง','ทดสอบ วัวหลัก ชื่อใหม่ภายหลัง','VERIFIED') returning id into v_bull;
  insert into bullmatch.bulls(canonical_name, normalized_name, verification_status)
  values ('ทดสอบ คู่ต่อสู้','ทดสอบ คู่ต่อสู้','VERIFIED') returning id into v_opp;
  insert into bullmatch.bulls(canonical_name, normalized_name, verification_status)
  values ('ทดสอบ วัวยังไม่ยืนยัน','ทดสอบ วัวยังไม่ยืนยัน','UNVERIFIED') returning id into v_unverified_bull;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-01-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'WIN',v_p1,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-02-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'DRAW',null,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-03-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'WIN',v_p2,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-04-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'NO_RESULT',null,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-05-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'CANCELLED',null,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-06-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_bull,'A','ชื่อวัวในวันแข่งขัน','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'WIN',v_p1,now());
  update bullmatch.matches set verification_status='VERIFIED' where id=v_match;

  insert into bullmatch.matches(match_date,date_precision,status,verification_status) values ('2026-07-01T12:00:00Z','EXACT','SCHEDULED','UNVERIFIED') returning id into v_match;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_unverified_bull,'A','วัวยังไม่ยืนยัน snapshot','UNKNOWN') returning id into v_p1;
  insert into bullmatch.match_participants(match_id,bull_id,side,display_name_snapshot,participant_result) values (v_match,v_opp,'B','คู่ต่อสู้ snapshot','UNKNOWN') returning id into v_p2;
  insert into bullmatch.match_results(match_id,result_type,winner_participant_id,verified_at) values (v_match,'WIN',v_p1,now());
  update bullmatch.matches set verification_status='VERIFIED',published_at=now() where id=v_match;

  update bullmatch.bulls set canonical_name='ชื่อปัจจุบันที่แก้แล้ว', normalized_name='ชื่อปัจจุบันที่แก้แล้ว' where id=v_bull;

  select * into v_stats from bullmatch.bull_basic_stats where bull_id=v_bull;
  if v_stats.published_matches <> 5 or v_stats.statistical_matches <> 3 or v_stats.wins <> 1 or v_stats.losses <> 1 or v_stats.draws <> 1 or v_stats.no_results <> 1 or v_stats.cancelled <> 1 or v_stats.win_rate_pct <> 33.33 then
    raise exception 'unexpected stats: %', row_to_json(v_stats);
  end if;

  select recent_form into v_form from bullmatch.bull_recent_form where bull_id=v_bull;
  if v_form <> array['LOSS','DRAW','WIN']::text[] then raise exception 'unexpected recent form: %', v_form; end if;

  select count(*) into v_history_count from bullmatch.published_bull_match_history where bull_id=v_bull;
  if v_history_count <> 5 then raise exception 'history count expected 5, got %', v_history_count; end if;

  select count(*) into v_opp_count from bullmatch.published_bull_opponent_history where bull_id=v_bull and opponent_bull_id=v_opp;
  if v_opp_count <> 5 then raise exception 'opponent history count expected 5, got %', v_opp_count; end if;

  select display_name_snapshot into v_snapshot from bullmatch.published_bull_match_history where bull_id=v_bull order by match_date asc limit 1;
  if v_snapshot <> 'ชื่อวัวในวันแข่งขัน' then raise exception 'historical snapshot was rewritten: %', v_snapshot; end if;

  if exists(select 1 from bullmatch.bull_basic_stats where bull_id=v_unverified_bull) then raise exception 'unverified bull leaked into stats'; end if;
  if exists(select 1 from bullmatch.published_bull_match_history where bull_id=v_unverified_bull) then raise exception 'unverified bull leaked into history'; end if;

  if has_table_privilege('anon','bullmatch.bull_basic_stats','SELECT') or has_table_privilege('authenticated','bullmatch.bull_basic_stats','SELECT') then
    raise exception 'browser role unexpectedly has direct stats view access';
  end if;
  if not has_table_privilege('service_role','bullmatch.bull_basic_stats','SELECT') then raise exception 'service_role missing stats access'; end if;
end $$;

rollback;
