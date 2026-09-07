-- BMI-P2-001 — Source-Agnostic Collection Pipeline Foundation
-- Rollback-only conformance harness for existing bullmatch_private ingestion tables.
--
-- Safety contract:
--   * synthetic UUIDs and .invalid URLs only
--   * no canonical Bull/Match/history writes
--   * intentionally exercises a failed inner transaction
--   * outer transaction ALWAYS rolls back; zero fixture rows may remain

begin;

insert into bullmatch_private.sources(
  id, name, source_type, base_url, connector_key, access_method,
  reliability_tier, policy_status, status, polling_enabled, poll_interval_minutes,
  connector_config, secret_requirements, tags, policy_notes
) values (
  'f2000000-0000-4000-8000-000000000001'::uuid,
  'BMI-P2-001 rollback-only fixture',
  'WEBSITE',
  'https://fixture.invalid',
  'fixture-connector',
  'ROLLBACK_ONLY_TEST',
  'UNKNOWN', 'APPROVED', 'ACTIVE', true, 60,
  '{}'::jsonb, '[]'::jsonb, array['rollback-only'],
  'Synthetic fixture; outer transaction always rolls back'
);

insert into bullmatch_private.source_runtime_state(
  source_id, cursor_strategy, cursor, state
) values (
  'f2000000-0000-4000-8000-000000000001'::uuid,
  'NONE', null, '{}'::jsonb
);

-- Simulate adapter staging that fails after item/evidence/checkpoint mutation.
-- The nested PL/pgSQL block is a PostgreSQL subtransaction: its exception
-- handler must restore every mutation performed inside the nested block.
do $$
declare
  v_item uuid;
  v_before_strategy text;
  v_before_cursor jsonb;
begin
  select cursor_strategy, cursor
    into v_before_strategy, v_before_cursor
  from bullmatch_private.source_runtime_state
  where source_id = 'f2000000-0000-4000-8000-000000000001'::uuid;

  begin
    insert into bullmatch_private.source_items(
      id, source_id, external_id, canonical_url, dedupe_key, published_at,
      retrieved_at, content_hash, title, normalized_text, raw_metadata,
      connector_name, connector_version, ingestion_status
    ) values (
      'f2000000-0000-4000-8000-000000000002'::uuid,
      'f2000000-0000-4000-8000-000000000001'::uuid,
      'fixture-1',
      'https://fixture.invalid/item/1',
      'fixture-dedupe-1',
      null,
      now(),
      null,
      'Rollback fixture',
      'synthetic text',
      jsonb_build_object(
        '_bullmatch',
        jsonb_build_object('normalized_envelope_fingerprint', repeat('a', 64))
      ),
      'fixture-connector',
      '1.0.0',
      'DISCOVERED'
    ) returning id into v_item;

    insert into bullmatch_private.evidence(
      id, source_item_id, evidence_type, storage_ref, content_sha256,
      text_excerpt, metadata, access_class, moderation_status
    ) values (
      'f2000000-0000-4000-8000-000000000003'::uuid,
      v_item,
      'TEXT',
      null,
      null,
      'synthetic excerpt',
      '{}'::jsonb,
      'INTERNAL',
      'PENDING'
    );

    update bullmatch_private.source_runtime_state
       set cursor_strategy = 'TIMESTAMP',
           cursor = '"2026-09-07T02:00:00Z"'::jsonb,
           last_attempt_at = now(),
           updated_at = now()
     where source_id = 'f2000000-0000-4000-8000-000000000001'::uuid;

    raise exception 'intentional rollback-only conformance failure';
  exception when others then
    null;
  end;

  if exists (
    select 1
      from bullmatch_private.source_items
     where id = 'f2000000-0000-4000-8000-000000000002'::uuid
  ) then
    raise exception 'atomicity failure: source item survived failed subtransaction';
  end if;

  if exists (
    select 1
      from bullmatch_private.evidence
     where id = 'f2000000-0000-4000-8000-000000000003'::uuid
  ) then
    raise exception 'atomicity failure: evidence survived failed subtransaction';
  end if;

  if exists (
    select 1
      from bullmatch_private.source_runtime_state
     where source_id = 'f2000000-0000-4000-8000-000000000001'::uuid
       and (
         cursor_strategy is distinct from v_before_strategy
         or cursor is distinct from v_before_cursor
       )
  ) then
    raise exception 'atomicity failure: checkpoint changed after failed subtransaction';
  end if;
end $$;

-- Prove the adapter's successful storage shape satisfies deployed constraints.
insert into bullmatch_private.source_items(
  id, source_id, external_id, canonical_url, dedupe_key, retrieved_at,
  content_hash, title, normalized_text, raw_metadata,
  connector_name, connector_version, ingestion_status
) values (
  'f2000000-0000-4000-8000-000000000004'::uuid,
  'f2000000-0000-4000-8000-000000000001'::uuid,
  'fixture-2',
  'https://fixture.invalid/item/2',
  'fixture-dedupe-2',
  now(),
  null,
  'Success shape fixture',
  'synthetic text',
  jsonb_build_object(
    '_bullmatch',
    jsonb_build_object('normalized_envelope_fingerprint', repeat('b', 64))
  ),
  'fixture-connector',
  '1.0.0',
  'DISCOVERED'
);

insert into bullmatch_private.evidence(
  id, source_item_id, evidence_type, text_excerpt,
  metadata, access_class, moderation_status
) values (
  'f2000000-0000-4000-8000-000000000005'::uuid,
  'f2000000-0000-4000-8000-000000000004'::uuid,
  'TEXT',
  'synthetic excerpt',
  '{}'::jsonb,
  'INTERNAL',
  'PENDING'
);

update bullmatch_private.source_runtime_state
   set cursor_strategy = 'TIMESTAMP',
       cursor = '"2026-09-07T02:00:00Z"'::jsonb,
       last_attempt_at = now(),
       updated_at = now()
 where source_id = 'f2000000-0000-4000-8000-000000000001'::uuid;

-- Prove CollectionRunState's persisted AgentRun mapping satisfies the table.
insert into bullmatch_private.agent_runs(
  id, agent_type, agent_version, source_id, correlation_id, started_at,
  status, items_scanned, items_created, review_cases_created, error_count,
  metrics, errors
) values (
  'f2000000-0000-4000-8000-000000000006'::uuid,
  'SOURCE_MONITORING',
  'collection-foundation/1.0.0',
  'f2000000-0000-4000-8000-000000000001'::uuid,
  'f2000000-0000-4000-8000-000000000007'::uuid,
  now(),
  'RUNNING',
  1,
  1,
  0,
  0,
  jsonb_build_object(
    '_bullmatch_run_refs',
    jsonb_build_object(
      'input_refs', jsonb_build_array(
        'source:f2000000-0000-4000-8000-000000000001'
      ),
      'output_refs', jsonb_build_array(
        'source-item:f2000000-0000-4000-8000-000000000001:fixture-dedupe-2'
      )
    )
  ),
  '[]'::jsonb
);

do $$
begin
  if (select count(*) from bullmatch_private.source_items
      where source_id='f2000000-0000-4000-8000-000000000001'::uuid) <> 1 then
    raise exception 'success-shape conformance failed: expected one staged source item';
  end if;

  if (select count(*) from bullmatch_private.evidence e
      join bullmatch_private.source_items si on si.id=e.source_item_id
      where si.source_id='f2000000-0000-4000-8000-000000000001'::uuid) <> 1 then
    raise exception 'success-shape conformance failed: expected one staged evidence row';
  end if;

  if (select cursor_strategy from bullmatch_private.source_runtime_state
      where source_id='f2000000-0000-4000-8000-000000000001'::uuid) <> 'TIMESTAMP' then
    raise exception 'success-shape conformance failed: checkpoint not staged';
  end if;

  if (select count(*) from bullmatch_private.agent_runs
      where id='f2000000-0000-4000-8000-000000000006'::uuid) <> 1 then
    raise exception 'success-shape conformance failed: AgentRun not staged';
  end if;
end $$;

rollback;

-- These assertions execute after rollback and therefore prove zero fixture retention.
do $$
begin
  if exists (
    select 1 from bullmatch_private.sources
    where id='f2000000-0000-4000-8000-000000000001'::uuid
  ) then
    raise exception 'rollback-only fixture source was retained';
  end if;

  if exists (
    select 1 from bullmatch_private.source_items
    where source_id='f2000000-0000-4000-8000-000000000001'::uuid
  ) then
    raise exception 'rollback-only fixture source item was retained';
  end if;

  if exists (
    select 1 from bullmatch_private.evidence
    where id in (
      'f2000000-0000-4000-8000-000000000003'::uuid,
      'f2000000-0000-4000-8000-000000000005'::uuid
    )
  ) then
    raise exception 'rollback-only fixture evidence was retained';
  end if;

  if exists (
    select 1 from bullmatch_private.agent_runs
    where id='f2000000-0000-4000-8000-000000000006'::uuid
  ) then
    raise exception 'rollback-only fixture AgentRun was retained';
  end if;
end $$;
