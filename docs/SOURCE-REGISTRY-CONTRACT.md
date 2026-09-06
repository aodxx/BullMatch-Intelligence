# Source Registry & Connector Contract v0.1

Status: **REVIEW READY**
Task: `BMI-P0-006`
Depends on: `BMI-P0-002`, `BMI-P0-003`

## 1. Purpose

Define the operational boundary between an approved information source and BullMatch Intelligence ingestion.

A connector may retrieve/normalize source material, but it may not:
- create or update canonical bulls/matches directly
- bypass evidence persistence
- publish statistics
- store credentials in source metadata
- reinterpret platform restrictions as permission to scrape

Connector output flows into `NormalizedIngestionEnvelope` and the existing candidate/verification pipeline.

## 2. Source Registry Responsibilities

One registry entry represents one logical source/feed/channel/configuration monitored by the system.

The registry answers:
- What is the source?
- How may it be accessed?
- Which connector handles it?
- Is polling approved?
- How often may it run?
- What rate limits apply?
- Which non-secret options configure the connector?
- Which secrets are required by name (never value)?
- Is the source healthy/paused/blocked?

## 3. Source Registry Entry

Machine-readable shape: `packages/contracts/schemas/source-registry-entry.schema.json`.

Core fields:

- `schema_version`
- `source_id`
- `name`
- `source_type`
- `base_url`
- `connector_key`
- `access_method`
- `reliability_tier`
- `policy_status`
- `status`
- `polling`
- `rate_limit`
- `connector_config`
- `secret_requirements`
- `tags`

### Source type

Initial values:
- `WEBSITE`
- `RSS`
- `SITEMAP`
- `API`
- `YOUTUBE`
- `OPERATOR_UPLOAD`
- `SEARCH_DISCOVERY`
- `OTHER`

A source type describes the information surface. It does not grant permission.

### Access method

Examples:
- `PUBLIC_PAGE`
- `RSS_FEED`
- `PUBLIC_API`
- `AUTHENTICATED_API`
- `OPERATOR_UPLOAD`
- `SEARCH_RESULT`
- `UNKNOWN`

### Reliability tier

- `OFFICIAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

Reliability affects verification signals only. It does not determine legal/access permission and does not automatically override contradictory evidence.

## 4. Policy State

`policy_status`:
- `APPROVED`
- `REVIEW_REQUIRED`
- `BLOCKED`

Polling may run only if all are true:

```text
policy_status = APPROVED
status = ACTIVE
polling.enabled = true
```

An unknown or changed access policy moves the source to `REVIEW_REQUIRED` or `BLOCKED` rather than attempting a workaround.

## 5. Operational Source Status

`status`:
- `ACTIVE`
- `PAUSED`
- `ERROR`
- `RETIRED`

This is separate from policy status.

Examples:
- API credentials expired -> `ERROR`, policy may still be `APPROVED`
- operator temporarily disables source -> `PAUSED`
- platform forbids required access method -> `BLOCKED` policy
- abandoned source -> `RETIRED`

## 6. Polling Configuration

Initial scheduling is source-driven configuration rather than hard-coded connector behavior.

Fields:
- `enabled`
- `interval_minutes` (minimum baseline 60 minutes in v0.1)
- optional `timezone`
- optional active windows
- `max_items_per_run`

Scheduler rules:
- scheduler selects due approved/active sources
- scheduler supplies current cursor/runtime state
- connector does not decide its own global schedule
- operator-upload sources normally have polling disabled

GitHub Actions may initially provide coarse orchestration; the contract remains portable to another scheduler/queue.

## 7. Rate-Limit Configuration

Each source/connector can declare conservative limits:
- `min_request_interval_ms`
- `max_requests_per_run`
- `max_concurrency`
- `cooldown_seconds`
- `respect_retry_after`

Rules:
- platform/API limits take precedence over local maxima
- a connector may voluntarily operate slower than the source limit
- HTTP/API `Retry-After` is respected when applicable
- repeated rate-limit errors change health to `RATE_LIMITED/DEGRADED`; they do not trigger tight retry loops

## 8. Secret Boundary

Registry entries may declare secret **names/requirements**, never secret values.

Example:

```json
{
  "key": "YOUTUBE_API_KEY",
  "required": true,
  "purpose": "YouTube Data API access"
}
```

Actual secret values live in repository/platform secret stores or another approved secret manager.

Never store in Git/database source metadata:
- API keys
- service-role keys
- passwords
- access/refresh tokens
- session cookies
- private auth headers

Connectors receive resolved secrets only at runtime through the trusted execution environment.

## 9. Connector Interface

Conceptual language-neutral interface:

```text
getCapabilities() -> ConnectorCapabilities
validateSource(sourceRegistryEntry) -> SourceValidationResult
poll(connectorPollRequest) -> ConnectorPollResult
```

A connector implementation is selected by `connector_key`.

Example keys:
- `generic-rss`
- `generic-public-web`
- `youtube-data-api`
- `operator-upload`

Connector key/version must appear in produced ingestion envelopes.

## 10. Connector Capabilities

A connector should declare, at minimum:
- supported source types
- whether authentication is required
- supported cursor strategies
- whether incremental polling is supported
- whether binary evidence may be emitted
- maximum practical batch size

Capabilities are implementation metadata, not source authorization.

## 11. Poll Request

Machine-readable shape: `connector-poll-request.schema.json`.

The orchestrator sends:
- `schema_version`
- `correlation_id`
- `run_id`
- `source`
- `cursor`
- `window`
- `limits`

### Cursor strategies

Initial strategies:
- `NONE`
- `TIMESTAMP`
- `EXTERNAL_ID`
- `PAGE_TOKEN`
- `ETAG`
- `CUSTOM`

Cursor content is connector-owned opaque state after strategy declaration.

## 12. Cursor Commit Rule

This is a critical integrity rule.

```text
poll source
 -> produce batch + proposed next_cursor
 -> validate envelopes
 -> persist source items/evidence idempotently
 -> COMMIT
 -> persist next_cursor
```

The stored cursor must not advance before the corresponding ingestion transaction/safe persistence succeeds.

If a batch partially fails:
- successful items remain persisted
- failed items are recorded
- cursor advances only to a safe connector-defined checkpoint
- retry must not duplicate already committed source items because `(source_id, dedupe_key)` remains idempotent

## 13. Poll Result

Machine-readable shape: `connector-poll-result.schema.json`.

Output includes:
- `items`: `NormalizedIngestionEnvelope[]`
- `next_cursor`
- `has_more`
- `health`
- `rate_limit_state`
- `metrics`
- `errors`

A successful poll may legally produce zero items.

## 14. Dedupe Key Ownership

The connector owns `dedupe_key` because it understands source-native identity.

Preferred strategy:
1. native item/post/video ID
2. stable canonical URL identity
3. stable source-specific composite identity
4. content identity fallback

`dedupe_key` must not depend on AI semantic interpretation such as extracted bull names/winner.

Examples:

```text
YouTube video: video:<video_id>
RSS entry: rss:<feed-guid>
Official result page: result:<provider-record-id>
Stable page fallback: url:<normalized-url-hash>
```

## 15. Canonical URL Rules

When possible:
- remove known tracking parameters
- preserve identifiers needed to reopen the source
- avoid session/user-specific URL state
- do not invent a URL for API-only items

`canonical_url` may be null if the source has no stable public item URL.

## 16. Source Health

Connector poll result health:
- `HEALTHY`
- `DEGRADED`
- `RATE_LIMITED`
- `AUTH_REQUIRED`
- `POLICY_BLOCKED`
- `ERROR`
- `PAUSED`

Health includes structured reason codes and recommended operator action where applicable.

Examples:
- transient single timeout with successful retry may remain `HEALTHY`
- repeated partial fetches -> `DEGRADED`
- exhausted quota -> `RATE_LIMITED`
- invalid credential -> `AUTH_REQUIRED`
- source access no longer approved -> `POLICY_BLOCKED`

## 17. Retry Rules

Connector retries follow the AI Agent Specification error policy.

- bounded retries
- exponential backoff + jitter where appropriate
- respect source retry instructions
- no infinite retries
- permanent errors surface to operators
- ambiguous data is not a connector infrastructure error

## 18. HTTP/Web Safety Rules

For web connectors:
- follow configured redirect limits
- do not access local/private network addresses supplied by untrusted source content
- apply request timeouts and response-size limits
- validate content type before expensive processing
- avoid executing arbitrary page scripts unless a specifically reviewed browser connector requires it
- treat page content as untrusted data/prompt-injection input

## 19. Operator Upload Connector

Manual/operator-submitted URL, text, image, or file is modeled as a connector too.

Advantages:
- same provenance pipeline
- same evidence handling
- same extraction contract
- same verification/review controls

Operator upload does not mean automatically verified. Manual **verified match entry** is a separate controlled domain workflow.

## 20. Search Discovery Connector Boundary

Search/discovery may identify candidate sources/items, but discovery results should not masquerade as the original evidence.

Where possible:
- discovery result stores discovery metadata
- source monitoring/retrieval opens the original permitted source
- claims cite original source evidence rather than only a search snippet

If only a search snippet is available, it remains lower-quality evidence and is clearly marked.

## 21. Runtime State

Runtime state may include:
- current cursor
- last attempted time
- last success time
- consecutive failures
- cooldown-until
- last item published time
- ETag / Last-Modified metadata
- connector-specific opaque state

This is mutable operational data and is distinct from source policy/configuration.

### Database impact note

The finalized database contract currently defines `private.sources` plus `private.agent_runs`. Phase 1 migrations should add either:

- `private.source_runtime_state` as a one-to-one operational table, **recommended**, or
- equivalent explicitly separated runtime-state storage.

Do not overload canonical source policy fields with rapidly changing cursors/error counters.

Proposed `source_runtime_state`:
- `source_id uuid primary key references private.sources(id)`
- `cursor_strategy text`
- `cursor jsonb`
- `last_attempt_at timestamptz`
- `last_success_at timestamptz`
- `consecutive_failures integer`
- `cooldown_until timestamptz`
- `last_health text`
- `last_error_code text`
- `state jsonb`
- `updated_at timestamptz`

This is a downstream schema addition for `BMI-P1-002`, not production DDL in Phase 0.

## 22. Non-Secret Connector Configuration

`connector_config` may contain safe options such as:
- feed path
- locale/language
- permitted category filters
- public channel ID
- parser selector
- pagination mode

It must not contain credentials.

Where configuration becomes complex, prefer a versioned config schema per connector while preserving this shared registry wrapper.

## 23. First Connector Selection Criteria

The first production connector should optimize for trust and testability rather than reach.

Preferred characteristics:
- official/public source or clearly permitted feed/API
- stable URLs/IDs
- results are available in text/structured metadata
- no login/session circumvention
- predictable rate limits
- historical sample items available for fixtures
- clear date/participant/result fields

Avoid choosing the hardest social platform as the first connector merely for coverage.

## 24. First Connector Definition of Done

A connector is production-ready only when:

1. source registry entry is `APPROVED + ACTIVE`
2. connector key/version is registered
3. source validation succeeds
4. deterministic `dedupe_key` strategy is documented/tested
5. cursor strategy is documented/tested
6. rate-limit behavior is defined
7. retries are bounded
8. sample source fixtures exist where permitted
9. output validates against `NormalizedIngestionEnvelope`
10. repeated identical poll does not duplicate source items
11. raw evidence is preserved
12. zero-new-item polling succeeds normally
13. source health/errors are recorded
14. secrets are absent from payload/logs
15. prompt-injection/source text cannot change trusted instructions
16. policy/access failure stops the connector instead of triggering a bypass

## 25. Team Boundary

### Connector team owns
- source-specific retrieval
- native pagination/cursor logic
- dedupe key generation
- canonical URL normalization
- source-specific safe config
- production of valid normalized envelopes

### Orchestrator owns
- scheduling
- loading registry/runtime state
- resolving runtime secrets
- persisting items/evidence
- committing cursor after persistence
- retries across job boundaries
- agent-run metrics

### AI team owns
- extraction after source item/evidence persistence

### Database/domain team owns
- schema, constraints, runtime-state persistence, verification/publish boundaries

Connector teams never write canonical sports tables directly.
