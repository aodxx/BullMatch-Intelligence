# Human Review Queue UX Specification v0.1

Status: **REVIEW READY**
Task: `BMI-P0-008`
Primary users: `REVIEWER`, `ADMIN`

## 1. Purpose

The review system is the safety boundary between AI-discovered candidate data and authoritative BullMatch Intelligence history.

Its purpose is not simply to show an "Approve" button. It must help a reviewer answer:

1. What is the AI proposing?
2. Which source/evidence supports it?
3. Is there contradictory evidence?
4. Which canonical entity/match may be affected?
5. What happens to historical statistics if I accept this decision?
6. Can this decision be reversed/audited later?

## 2. UX principles

1. Evidence before action.
2. Uncertainty must remain visible.
3. Destructive identity actions are visually and procedurally separate from ordinary approval.
4. Review actions are append-only/audited.
5. Reviewer should not need to inspect raw database rows.
6. Mobile review must be usable, but complex merge/split flows may require a larger-screen warning/recommendation.
7. AI confidence is context, not authority.
8. Important competing evidence is never hidden behind an aggregate score.
9. The UI must make "create new entity" a first-class safe outcome; reviewers should not be pushed to link to an existing entity merely to clear the queue.
10. Every terminal action requires a current-state check to prevent stale concurrent decisions.

## 3. Queue information architecture

Primary navigation:

- **Needs Review**
- **Assigned to Me**
- **Conflicts**
- **Possible Duplicates**
- **Entity Matching**
- **New Entities**
- **Data Quality**
- **Resolved**

The default landing view is `Needs Review`, sorted by priority then oldest unresolved case.

## 4. Queue card / row

Each case card should show enough information to triage without opening it:

- case type
- short summary
- priority
- age / created time
- assigned reviewer or unassigned
- source/reliability indicator
- AI/verification status
- confidence band when relevant
- conflict badge when present
- primary affected entity names
- number of supporting/contradicting evidence items

Do not show confidence as a large green/red "truth meter". Use it as secondary metadata.

## 5. Filters and search

Queue filters:
- case type
- status
- priority
- assigned/unassigned/reviewer
- source
- reliability tier
- entity type
- venue/province where applicable
- created date / age
- has conflict
- confidence band

Search:
- bull/entity name or alias
- camp
- owner
- venue
- event
- source URL/title where indexed
- review case ID

Saved filters can be added later; not required for MVP.

## 6. Review detail layout

Recommended desktop layout:

```text
+----------------------------------------------------------+
| Case Header: type / priority / assignment / age          |
+-------------------------------+--------------------------+
| Proposal / structured facts   | Evidence & source pane   |
|                               |                          |
| Candidate comparison          | Supporting evidence      |
| Conflict details              | Contradicting evidence   |
| Impact preview                | Source metadata          |
+-------------------------------+--------------------------+
| Previous decisions / audit history                       |
+----------------------------------------------------------+
| Action bar                                               |
+----------------------------------------------------------+
```

Mobile layout becomes stacked sections with a sticky action summary rather than squeezing two columns.

## 7. Global review header

Must show:
- review case ID
- case type
- status
- priority
- assigned reviewer
- created time / aging
- source count
- candidate/subject identity
- policy/agent versions where relevant

Actions:
- claim case
- unclaim
- change priority (Admin or permitted reviewer role)
- add internal note

## 8. Evidence viewer

Evidence is central to every review.

For each evidence item show:
- source name
- source reliability tier
- source URL/reference when available
- published/retrieved timestamp
- evidence type
- minimum relevant excerpt/preview
- video/audio timestamp when available
- whether the item supports, contradicts, or provides context
- evidence hash/reference metadata where useful to audit

### Evidence ordering

Default order:
1. contradictory evidence
2. strongest supporting evidence
3. additional context

Reviewer must be able to switch to chronological/source grouping.

### Media

Images/PDF/video may open in a focused evidence panel. Do not require downloading the source merely to inspect it.

### Copyright/data minimization

Show only the minimum stored excerpt/preview necessary for verification and link/reference back to the source where possible.

## 9. Case type: New Match

Reviewer sees:
- proposed event/date/venue
- participant A/B candidates
- camp/owner snapshots when available
- proposed result/winner
- duration/result details
- extraction confidence per important claim
- source evidence per claim
- duplicate-analysis result
- entity-resolution result for each participant

Actions:
- approve canonical match creation
- edit candidate facts then approve
- reject candidate
- send specific entity field back to identity review
- mark/re-route as possible duplicate
- leave unresolved with note

Approval must fail safely if participant identity or required result fields are still unresolved under policy.

## 10. Case type: New Entity

Reviewer sees:
- raw source name
- normalized/search representation
- entity type
- source/context
- top existing candidates if any
- reason no current candidate passed threshold

Actions:
- create new canonical entity
- link to existing entity
- reject mention/noise
- add or verify alias when linking

Creating a new bull must not require fictional birth date/camp/owner values. Unknown remains unknown.

## 11. Case type: Entity Match / Possible Same Bull

Use requirements from `docs/ENTITY-RESOLUTION-STRATEGY.md`.

Show side-by-side:

### Source mention
- raw name
- normalized name
- camp/owner context
- province/location
- event/opponent/date
- lineage/appearance when available

### Candidate canonical entity
- canonical name
- verified aliases
- current/historical camp/owner context
- recent match history relevant to the decision

### Resolution signals
- total score
- auto-link/review threshold
- second-best candidate score
- candidate margin
- independent positive signal groups
- strong signal(s)
- soft negative signals
- hard conflicts
- policy version

Actions:
- link to this canonical entity
- choose another candidate
- create new entity
- reject mention/noise
- verify alias if appropriate
- open merge proposal (not perform merge directly)

## 12. Case type: Possible Duplicate Match

Reviewer sees canonical candidate vs new candidate side-by-side:
- participants/resolved IDs
- date/time precision
- event/venue
- match number
- result
- duration
- sources already attached to existing match
- new evidence
- differing fields highlighted

Actions:
- confirm duplicate and attach evidence
- not duplicate / create separate match
- keep for review if identity/date conflict remains

Never discard new evidence just because the match is duplicate.

## 13. Case type: Conflicting Result

This is high priority because it directly affects win/loss statistics.

Show a claim matrix:

| Fact | Source A | Source B | Other | Current canonical |
|---|---|---|---|---|
| Winner | ... | ... | ... | ... |
| Result | ... | ... | ... | ... |
| Date | ... | ... | ... | ... |

For each source show reliability and evidence.

Actions:
- choose resolved value with reason
- mark evidence/source as mistaken for this fact
- keep conflict unresolved
- reject candidate group if appropriate

A reviewer resolution must capture:
- selected value
- reason/note
- supporting evidence refs
- contradictory evidence refs retained

Unresolved conflict remains excluded from authoritative statistics where required by publication policy.

## 14. Case type: Low Confidence / Missing Mandatory Fact

Reviewer sees exactly which fields are missing/uncertain.

Actions:
- fill from evidence
- mark fact unknown if allowed by domain policy
- reject incomplete candidate
- request/await additional evidence

The UI must never incentivize guessing just to reach completion.

## 15. Case type: Data Quality

Examples:
- impossible winner relation
- published but unverified match
- same bull in impossible overlapping matches
- suspicious age/weight
- alias collision
- repeated source failures

Show:
- rule ID
- severity
- affected records
- why the rule fired
- evidence/context
- recommended action

Actions vary by rule but all create audit history.

## 16. Merge workflow — destructive

Merge is separate from ordinary review.

Steps:
1. choose source and surviving target entity
2. display side-by-side identity evidence
3. show all dependent objects affected
4. preview changes:
   - matches
   - participant references
   - aliases
   - camps/owners
   - sources/evidence/provenance
   - derived statistics impact
5. require explicit reviewer/Admin confirmation
6. require short reason
7. execute as controlled domain operation
8. create `identity_events` + review action/audit record
9. preserve redirect/tombstone/history for merged entity

No AI recommendation can bypass this confirmation.

## 17. Split workflow — destructive

Split must support correcting prior bad merges/links.

Steps:
1. identify incorrectly combined canonical entity
2. create/select resulting entities
3. classify affected aliases/facts/matches to targets
4. show unresolved items separately
5. preview statistical impact
6. require explicit confirmation and reason
7. execute transactionally
8. record identity event + provenance/audit
9. recompute derived statistics

Do not offer one-click automated split.

## 18. Impact preview

Before actions that can affect historical statistics, show an impact preview.

Examples:
- `This approval will add 1 verified match to Bull A.`
- `This result change changes Bull A record from 10-2 to 9-3.`
- `This merge will combine 14 historical matches and 4 aliases.`

Impact preview is informational; calculations must come from deterministic domain logic, not generated prose alone.

## 19. Action model

Common actions align with `public.review_actions`:
- `CLAIM`
- `UNCLAIM`
- `APPROVE`
- `REJECT`
- `EDIT`
- `LINK_ENTITY`
- `CREATE_ENTITY`
- `CONFIRM_DUPLICATE`
- `MARK_NOT_DUPLICATE`
- `RESOLVE_CONFLICT`
- `MERGE`
- `SPLIT`
- `COMMENT`
- `REOPEN`

The UI issues controlled commands; it does not perform ad-hoc direct table updates.

## 20. Review command integrity

Every state-changing request includes:
- `command_id` UUID generated once per user action
- review case ID
- action
- expected current case status/version
- payload
- reviewer note where required

Server rules:
- `command_id` is idempotent
- stale expected version returns a conflict and reload instruction
- duplicate submission returns the already-created action result rather than executing twice
- destructive commands require role/policy checks

Machine-readable shape: `packages/contracts/schemas/review-command.schema.json`.

## 21. Concurrency

Two reviewers may open the same case.

Minimum controls:
- case assignment/claim indicator
- optimistic version on case state
- stale-write rejection
- visible "updated by another reviewer" notice
- refresh/reconcile before final action

Assignment reduces collision but does not replace optimistic concurrency.

## 22. Notes and audit history

The detail page includes chronological history:
- AI/verification case creation
- assignments
- comments
- edits
- approvals/rejections
- entity links
- conflict resolutions
- merge/split events
- reopen events

History must show actor + timestamp + action + short summary.

Do not silently rewrite prior review actions.

## 23. Reopen behavior

Resolved cases may be reopened when:
- materially new evidence appears
- a later source conflicts with the resolution
- identity merge/split changes the underlying context
- Admin detects an error

Reopen appends a `REOPEN` action. Prior resolution remains visible.

## 24. Bulk review

MVP should be conservative.

Allowed candidate for bulk action later:
- clearly low-risk duplicate/noise cases with identical deterministic rule outcome

Not bulk-approved:
- winner/result conflicts
- entity merge/split
- ambiguous bull identity
- new canonical entity creation where identity context is material

Phase 0 does not require bulk action implementation.

## 25. Keyboard/mobile/accessibility

### Mobile
- cards use large touch targets
- evidence opens in stacked viewer
- sticky bottom action button opens action sheet
- critical actions require a second explicit confirmation
- long tables transform to comparison cards

### Accessibility
- status is not conveyed by color alone
- action buttons have descriptive labels
- keyboard focus order follows visual order
- evidence relationship uses text labels: Supporting / Contradicting / Context
- dialogs trap focus and return focus correctly
- error messages state what needs correction

## 26. Visual hierarchy

Priority order:
1. conflict / unresolved identity
2. proposed canonical fact
3. contradictory evidence
4. supporting evidence
5. score/confidence metadata
6. technical model/version metadata

Confidence should never visually dominate evidence.

## 27. Empty/loading/error states

Queue:
- empty: `ไม่มีรายการที่ต้องตรวจสอบตามตัวกรองนี้`
- load failure: explain retryability and preserve filters

Detail:
- evidence unavailable: show source reference and explicit unavailable reason
- stale case: block submit and reload current state
- action failure: preserve reviewer note/form input where safe

Do not show generic silent failures.

## 28. Reviewer performance metrics

Track system/process quality, not simplistic reviewer speed ranking.

Useful metrics:
- open cases by type/age
- median time to first review
- median time to resolution
- reopen rate
- conflict backlog
- auto-link later overturned rate
- reviewer disagreement/reversal rate
- cases blocked by missing evidence

Avoid optimizing only for cases/hour because that can encourage unsafe approvals.

## 29. MVP screens

Phase 1/2 review MVP needs:

1. `/admin/review` — queue
2. `/admin/review/:caseId` — detail/evidence/action
3. merge impact flow/modal/page
4. split impact flow/modal/page
5. audit/history panel

Additional dashboards are optional later.

## 30. Required backend/API operations

UI will need controlled operations conceptually:
- list/filter review cases
- fetch case detail + evidence + candidates + history
- claim/unclaim
- submit review command
- preview merge impact
- preview split impact
- execute authorized merge/split command

Implementation may use server routes/RPC/domain services, but direct unrestricted client writes to canonical tables are out of scope.

## 31. Security

- reviewer/admin routes require authenticated authorized roles
- private evidence is fetched only through authorized server/domain paths
- private contact data is not exposed merely because it was used as a backend resolution signal
- service-role/secret credentials never enter browser bundles
- source content displayed in the UI is escaped/sanitized as untrusted content
- source HTML/script never executes with application privileges

## 32. Definition of Done

`BMI-P0-008` is complete when:
- queue and detail information architecture are explicit
- each mandatory review case has a safe action path
- evidence and contradictions are visible before action
- entity-resolution signals/margin/context are reviewable
- duplicate evidence is preserved
- conflict resolution records reasons and evidence
- merge/split is separated, impact-previewed, human-confirmed, and auditable
- review commands are idempotent and reject stale state
- mobile/accessibility requirements exist
- backend operations needed by UI are clear
- machine-readable review command contract exists
