-- BMI-APP-004 verified/public participant image contract.
-- This test does not fabricate Bull/Match rows.

begin;

select plan(7);

select ok(
  to_regprocedure('public.bullmatch_api_public_query(text,uuid,text,integer,integer)') is not null,
  'canonical public query function exists'
);

select ok(
  to_regprocedure('public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer)') is null,
  'duplicate v2 public query function is absent'
);

select is(
  has_function_privilege('anon', 'public.bullmatch_api_public_query(text,uuid,text,integer,integer)', 'EXECUTE'),
  false,
  'anon cannot execute canonical public query directly'
);

select is(
  has_function_privilege('authenticated', 'public.bullmatch_api_public_query(text,uuid,text,integer,integer)', 'EXECUTE'),
  false,
  'authenticated cannot execute canonical public query directly'
);

select is(
  has_function_privilege('service_role', 'public.bullmatch_api_public_query(text,uuid,text,integer,integer)', 'EXECUTE'),
  true,
  'service_role can execute canonical public query'
);

select ok(
  position('primary_image_ref' in pg_get_functiondef('public.bullmatch_api_public_query(text,uuid,text,integer,integer)'::regprocedure)) > 0,
  'canonical public query exposes verified participant primary_image_ref'
);

select jsonb_typeof(public.bullmatch_api_public_query('MATCHES', null, null, 50, 0)) = 'array' as matches_is_array \gset
select ok(:'matches_is_array'::boolean, 'MATCHES remains a JSON array without adding fake records');

select * from finish();
rollback;
