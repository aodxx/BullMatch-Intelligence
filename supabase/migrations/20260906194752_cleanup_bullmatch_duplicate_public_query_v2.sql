-- BMI-APP-004: cleanup duplicate participant-image RPC created by a concurrent autonomous run.
-- The canonical participant-image contract now lives on public.bullmatch_api_public_query(...).
-- Keep exactly one service-only public read bridge and remove the unused v2 surface.

drop function if exists public.bullmatch_api_public_query_v2(text,uuid,text,integer,integer);
