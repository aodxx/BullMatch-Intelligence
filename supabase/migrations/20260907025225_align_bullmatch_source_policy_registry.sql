alter table bullmatch_private.sources
  add column if not exists polling_timezone text null,
  add column if not exists polling_active_windows jsonb null,
  add column if not exists max_items_per_run integer null,
  add column if not exists rate_limit jsonb null;

alter table bullmatch_private.sources
  add constraint sources_max_items_per_run_check
    check (max_items_per_run is null or max_items_per_run >= 1),
  add constraint sources_polling_active_windows_array_check
    check (polling_active_windows is null or jsonb_typeof(polling_active_windows) = 'array'),
  add constraint sources_rate_limit_object_check
    check (rate_limit is null or jsonb_typeof(rate_limit) = 'object');

comment on column bullmatch_private.sources.polling_timezone is
  'Optional persisted source-registry polling timezone. APPROVED runtime rows must satisfy shared contract validation before polling.';
comment on column bullmatch_private.sources.polling_active_windows is
  'Optional source-registry active windows JSON. No values are backfilled or invented by this migration.';
comment on column bullmatch_private.sources.max_items_per_run is
  'Optional source-registry maximum items per collection run. No default is invented for existing rows.';
comment on column bullmatch_private.sources.rate_limit is
  'Optional complete source-registry rate-limit policy JSON. APPROVED runtime rows must validate before polling.';
