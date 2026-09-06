-- BMI-P1-013 — contributor self-service projection.
-- Returns only the authenticated actor's own contribution state and safe public Bull identity.
-- No reviewer identity, private notes, audit history, abuse metadata, evidence internals or other contributors are exposed.

create or replace function public.bullmatch_api_contributor_query(
  p_actor_id uuid,
  p_resource text,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit,50),100));
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_resource text := upper(btrim(coalesce(p_resource,'')));
  v_result jsonb;
begin
  if p_actor_id is null or not exists(select 1 from auth.users u where u.id=p_actor_id) then
    raise exception 'AUTH_ACTOR_NOT_FOUND' using errcode='42501';
  end if;

  if v_resource <> 'MY_SUBMISSIONS' then
    raise exception 'UNSUPPORTED_CONTRIBUTOR_RESOURCE' using errcode='22023';
  end if;

  select jsonb_build_object(
    'total', (select count(*) from bullmatch_private.community_submissions s0 where s0.submitter_user_id=p_actor_id),
    'limit', v_limit,
    'offset', v_offset,
    'items', coalesce(jsonb_agg(q.item order by q.submitted_at desc,q.id desc),'[]'::jsonb)
  ) into v_result
  from (
    select
      s.id,
      s.submitted_at,
      jsonb_build_object(
        'id',s.id,
        'submission_type',s.submission_type,
        'status',s.status,
        'submitted_at',s.submitted_at,
        'updated_at',s.updated_at,
        'resolved_at',s.resolved_at,
        'target',jsonb_build_object(
          'bull_id',case when (s.target_hint->>'bull_id') ~* '^[0-9a-f-]{36}$' then s.target_hint->>'bull_id' else null end,
          'bull_name',case when b.verification_status='VERIFIED' and b.archived_at is null then b.canonical_name else null end
        ),
        'claims',coalesce((
          select jsonb_agg(jsonb_build_object(
            'field_key',c.field_key,
            'proposed_value',c.value_json->>'value',
            'outcome',case c.status
              when 'VERIFIED' then 'ACCEPTED'
              when 'REJECTED' then 'REJECTED'
              when 'CONFLICT' then 'CONFLICT'
              when 'SUPERSEDED' then 'SUPERSEDED'
              when 'WITHDRAWN' then 'WITHDRAWN'
              else 'PENDING_REVIEW'
            end
          ) order by c.created_at,c.id)
          from bullmatch_private.claims c
          where c.submission_id=s.id and c.created_by_user_id=p_actor_id
        ),'[]'::jsonb)
      ) as item
    from bullmatch_private.community_submissions s
    left join bullmatch.bulls b
      on b.id=case
        when (s.target_hint->>'bull_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        then (s.target_hint->>'bull_id')::uuid
        else null
      end
    where s.submitter_user_id=p_actor_id
    order by s.submitted_at desc,s.id desc
    limit v_limit offset v_offset
  ) q;

  return v_result;
end;
$$;

revoke all on function public.bullmatch_api_contributor_query(uuid,text,integer,integer) from public,anon,authenticated;
grant execute on function public.bullmatch_api_contributor_query(uuid,text,integer,integer) to service_role;
