# Database Schema v0.2 — Additive Migration & Compatibility Plan

Task: `BMI-P1-011`  
Status: **DESIGN COMPLETE / SQL IMPLEMENTATION DEFERRED UNTIL CONTRACT MERGE**  
Target: shared Supabase project, BullMatch-owned schemas only

## 1. Goal

Convert the v0.2 schema contract into production migrations without breaking the active BullMatch API, admin workflow, existing statistics, shared-Supabase isolation or evidence history.

This plan is intentionally migration-oriented. It does not authorize direct production DDL during P1-011.

## 2. Production assumptions verified before design

The deployed application currently depends on:

- `bullmatch.bulls`
- `bullmatch.camps`
- `bullmatch.owners`
- `bullmatch.venues`
- `bullmatch.events`
- `bullmatch.matches`
- `bullmatch.match_participants`
- `bullmatch.match_results`
- existing statistics/views
- `bullmatch.app_users`
- service-only `public.bullmatch_api_*` bridge functions

The bridge currently reads current bull owner/camp summary columns and the established match tables. Therefore v0.2 must not rename/drop those objects or alter required function signatures.

The existing private pipeline has two assumptions that must be generalized:

1. `bullmatch_private.evidence.source_item_id` is mandatory.
2. `bullmatch_private.claims.extraction_run_id` is mandatory.

Those assumptions block first-class community evidence and manually confirmed community claims.

## 3. Migration slices

### Slice A — Community origins + claim generalization

Create:

- `bullmatch_private.community_submissions`

Alter:

- `bullmatch_private.evidence`
- `bullmatch_private.extraction_runs`
- `bullmatch_private.claims`

Required order:

1. create `community_submissions`
2. add nullable new columns to evidence/extraction/claims
3. backfill existing rows with explicit source-extraction origin where needed
4. replace old NOT NULL/FK/delete behavior only after backfill
5. add new origin-integrity constraints as `NOT VALID` where useful
6. validate constraints after compatibility tests
7. add indexes

Safety:

- existing source-ingestion rows remain valid without data rewrite
- existing extraction/claims preserve IDs
- no existing evidence is deleted

### Slice B — Contributor identity + trust event foundation

Create:

- `bullmatch.contributor_profiles`
- `bullmatch_private.contributor_reputation_events`
- `bullmatch.contributor_reputation`

Security:

- private event ledger: service role only
- contributor aggregate: RLS default-deny; only intentional self/public projections later
- authenticated user ID for writes always derived server-side

Do not alter `app_users.role` in this slice.

### Slice C — Temporal bull identity/affiliations

Create:

- `bullmatch.people`
- optional `bullmatch.person_aliases`
- `bullmatch.bull_affiliations`
- `bullmatch.bull_media`
- `bullmatch_private.bull_external_identifiers`

Compatibility:

- `bulls.current_owner_id` and `current_camp_id` stay unchanged
- no automatic backfill from current columns unless a separate reviewed migration creates explicitly marked inferred/current-summary rows
- historical rows must not be fabricated from present-day convenience values

### Slice D — Trait/style observations + verified lineage

Create:

- `bullmatch.bull_trait_observations`
- `bullmatch.bull_style_observations`
- `bullmatch.bull_parentage`

Rules:

- no source-free migration of `color_description` into verified trait rows
- no parsing of `lineage_notes` into canonical parentage without evidence/review
- old summary text fields remain readable for API compatibility

### Slice E — Comparison and pairing lifecycle

Create:

- `bullmatch.comparison_sessions`
- `bullmatch.comparison_entries`
- `bullmatch.pairings`
- `bullmatch.pairing_participants`

Alter:

- add nullable `pairing_id` to `bullmatch.matches`

Compatibility:

- all existing matches remain valid with `pairing_id = null`
- no existing match is assumed to have a historical comparison/pairing record

### Slice F — Program versioning + rules

Create:

- `bullmatch.event_programs`
- `bullmatch.event_program_versions`
- `bullmatch.event_program_entries`
- `bullmatch.rule_profiles`
- `bullmatch.rule_profile_versions`

Optional nullable links:

- `events.rule_profile_version_id`
- `matches.rule_profile_version_id`
- `comparison_sessions.rule_profile_version_id`

No hard-coded global bullfighting rule is introduced.

### Slice G — Resolution/review type expansion + hardening

Alter constrained values for:

- entity-match candidate types
- duplicate candidate types
- claim statuses/origins

Review workflow:

The current `review_cases.subject_type + subject_ref + context` structure can already address claim/submission/candidate subjects. Do not replace review tables in P1-011.

BMI-P1-008 later adds stronger normalized links only if actual queries/commands require them.

Then add:

- FK indexes
- partial indexes
- RLS/grants
- isolation tests
- advisor checks

## 4. High-risk DDL changes

### 4.1 Evidence origin

Current:

`evidence.source_item_id NOT NULL ... ON DELETE CASCADE`

Target:

- nullable `source_item_id`
- optional `submission_id`
- preserve evidence when source linkage is removed

Migration caution:

Changing FK delete action requires dropping/recreating the FK. Verify no application relies on deleting source items to cascade evidence. In production policy, source/evidence should normally be retained rather than hard-deleted.

### 4.2 Extraction origin

Current `extraction_runs.source_item_id` is mandatory.

Target allows community submission/evidence input.

The existing FK should become preservation-oriented (`ON DELETE SET NULL`) when generalized so an extraction audit row cannot vanish because an origin row is removed.

### 4.3 Claim origin

Current `claims.extraction_run_id NOT NULL ... ON DELETE CASCADE` is inappropriate once manual/community claims exist.

Target:

- nullable extraction run
- `submission_id`
- `created_by_user_id`
- explicit `origin_type`
- preservation-oriented FK semantics

Existing source-extracted claims should be backfilled with `origin_type='SOURCE_EXTRACTION'` before the new check is validated.

## 5. No-fabrication migration rule

Do not synthesize historical facts merely to populate new tables.

Specifically, migration must not:

- turn `bulls.current_owner_id` into a claimed historical start date
- infer old camp timelines
- parse free-text lineage into sire/dam rows
- infer `วันเปรียบ` from match date
- create pairing records for every existing match
- translate free-text color into controlled verified traits

Null/unknown is preferable to invented history.

## 6. API compatibility matrix

| Existing production surface | v0.2 requirement |
|---|---|
| Dashboard counts | unchanged |
| Bull list | unchanged |
| Bull profile | unchanged; current summary fields retained |
| Match list/detail | unchanged |
| Venue list | unchanged |
| `/me` | unchanged |
| Admin owner/camp/bull/venue CRUD | unchanged |
| Admin match entry/result/publication | unchanged |
| Existing stats views | unchanged |
| Service-only API bridge function signatures | unchanged |

New temporal/community data is dark to the current API until a later explicit API version/route adds it.

## 7. RLS and privilege test matrix

For every new table, test at least:

### `anon`

- cannot insert/update/delete canonical or private rows
- cannot read private tables

### ordinary `authenticated`

- cannot write canonical facts directly
- cannot read private evidence/claim/reputation-event tables directly
- can only access contributor self-service through controlled server route

### `REVIEWER`

- still cannot bypass controlled review commands through raw browser writes

### `ADMIN`

- existing controlled admin functions still work
- new canonical promotion is only available through later explicit server functions

### `service_role`

- can perform migration/runtime service operations

### unrelated application schemas

- no new grants/objects/DDL outside BullMatch-owned schemas except approved service bridge functions

## 8. Constraint test cases

Implementation tests should cover:

- community submission idempotency key retry
- evidence with source origin only
- evidence with community submission origin only
- evidence with both linked origins when permitted
- evidence with no origin rejected
- source-extracted claim valid
- community/manual claim valid
- inconsistent origin type rejected
- pairing cannot accept with fewer/more than two participants via controlled acceptance function
- pairing participant duplicate rejected
- program version number duplicate rejected
- parentage child=self rejected
- parentage cycle rejected by promotion logic
- current owner/camp summary unaffected by inserting historical affiliation
- overlapping affiliations allowed when legitimate
- community user cannot set claim to VERIFIED directly
- reputation event cannot be written directly by browser

## 9. Transaction and rollback strategy

Each migration slice should run in a transaction where Supabase/PostgreSQL DDL permits.

Before community feature launch, rollback may drop newly created unused objects and restore old constraints after proving no rows depend on new behavior.

After real contribution data exists:

- prefer forward repair migrations
- preserve submissions/evidence/claims/reputation audit
- disable application route/feature rather than deleting history

Any rollback that would restore NOT NULL on `source_item_id` or `extraction_run_id` must first prove all new community-origin rows have been safely migrated elsewhere. Otherwise it is destructive and forbidden.

## 10. Performance plan

Create only predictable B-tree/partial indexes first.

Avoid broad JSONB GIN indexes on:

- raw submission payloads
- `observed_value`
- archival terms
- moderation metadata

until query telemetry demonstrates need.

Reputation and timeline queries should use normalized dimensions/scopes and normal indexes rather than scanning JSON.

## 11. Storage/media plan

Community files and bull images remain outside PostgreSQL.

Database stores:

- storage reference
- hash
- MIME type
- capture time
- uploader association
- moderation/access status
- evidence relationship

Uploads remain non-public by default. A separate verified/public media projection controls profile display.

## 12. Implementation gate

Do not apply the v0.2 production migration merely because this plan exists.

Next sequence:

1. merge P1-011 contract
2. complete P1-012 Contribution & Trust Architecture
3. confirm exact submit/review authorization paths
4. write timestamped SQL migrations + tests
5. run migration/rollback/isolation tests
6. verify current app/API build and production smoke tests
7. apply only after the combined contract is coherent

This avoids committing the database to an incomplete trust model while still fixing the data architecture first.
