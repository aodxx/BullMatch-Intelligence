-- BMI-APP-004 verified/public participant image contract.
-- This test does not fabricate Bull/Match rows.

begin;

select plan(6);

select ok(
  to_regprocedure('public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)') is not null,
  'v2 public query function exists'
);

select is(
  has_function_privilege('anon', 'public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)', 'EXECUTE'),
  false,
  'anon cannot execute v2 public query directly'
);

select is(
  has_function_privilege('authenticated', 'public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)', 'EXECUTE'),
  false,
  'authenticated cannot execute v2 public query directly'
);

select is(
  has_function_privilege('service_role', 'public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)', 'EXECUTE'),
  true,
  'service_role can execute v2 public query'
);

select is(
  public.bullmatch_api_public_query_v2('DASHBOARD', null, null, 50, 0),
  public.bullmatch_api_public_query('DASHBOARD', null, null, 50, 0),
  'non-match public resources retain v1 behavior'
);

select jsonb_typeof(public.bullmatch_api_public_query_v2('MATCHES', null, null, 50, 0)) = 'array' as matches_is_array \gset
select ok(:'matches_is_array'::boolean, 'MATCHES remains a JSON array without adding fake records');

select * from finish();
rollback;
