-- BMI-APP-004: additive verified/public participant-image read contract.
-- Keeps the original service-only API RPC intact and adds a v2 wrapper.
-- Browser roles must not execute this function directly.

create or replace function public.bullmatch_api_public_query_v2(
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
  v_resource text := upper(coalesce(p_resource, ''));
  v_result jsonb;
begin
  v_result := public.bullmatch_api_public_query(p_resource, p_id, p_search, p_limit, p_offset);

  if v_resource = 'MATCH' and v_result is not null then
    select jsonb_set(
      v_result,
      '{participants}',
      coalesce(jsonb_agg(
        jsonb_set(
          p.value,
          '{primary_image_ref}',
          coalesce(
            to_jsonb(case
              when b.verification_status = 'VERIFIED' and b.archived_at is null
                then b.primary_image_ref
              else null
            end),
            'null'::jsonb
          ),
          true
        )
        order by p.ordinality
      ), '[]'::jsonb),
      true
    )
    into v_result
    from jsonb_array_elements(coalesce(v_result->'participants', '[]'::jsonb))
      with ordinality as p(value, ordinality)
    left join bullmatch.bulls b on b.id = (p.value->>'bull_id')::uuid;

  elsif v_resource = 'MATCHES' then
    select coalesce(jsonb_agg(
      jsonb_set(
        m.value,
        '{participants}',
        coalesce((
          select jsonb_agg(
            jsonb_set(
              p.value,
              '{primary_image_ref}',
              coalesce(
                to_jsonb(case
                  when b.verification_status = 'VERIFIED' and b.archived_at is null
                    then b.primary_image_ref
                  else null
                end),
                'null'::jsonb
              ),
              true
            )
            order by p.ordinality
          )
          from jsonb_array_elements(coalesce(m.value->'participants', '[]'::jsonb))
            with ordinality as p(value, ordinality)
          left join bullmatch.bulls b on b.id = (p.value->>'bull_id')::uuid
        ), '[]'::jsonb),
        true
      )
      order by m.ordinality
    ), '[]'::jsonb)
    into v_result
    from jsonb_array_elements(coalesce(v_result, '[]'::jsonb))
      with ordinality as m(value, ordinality);
  end if;

  return v_result;
end;
$$;

revoke all on function public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)
from public, anon, authenticated;

grant execute on function public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)
to service_role;
