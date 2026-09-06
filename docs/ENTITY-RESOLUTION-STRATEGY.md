# Entity Resolution Strategy v0.1

Status: **REVIEW READY**
Task: `BMI-P0-007`
Applies to: bulls, camps, owners, venues, events

## 1. Why this subsystem exists

BullMatch Intelligence cannot treat a name as identity.

The same bull may appear as:
- a canonical name
- a spelling variant
- a name with or without a title/prefix
- a source-specific display label
- a former name
- a name combined with camp/province context

Different bulls may also share the same or highly similar name.

Therefore entity resolution must answer:

> "Which existing canonical entity, if any, does this source mention most likely refer to?"

It must never turn similarity into irreversible truth without enough evidence.

## 2. Core safety rules

1. Name similarity alone never authorizes a destructive merge.
2. Exact normalized name alone is insufficient for automatic bull identity when duplicate names are possible.
3. Verified aliases are stronger signals than unreviewed source labels.
4. Context signals must be considered independently: camp/owner, geography, event, opponent, lineage/physical metadata, chronology, and source history.
5. Strong contradictory evidence overrides a high aggregate similarity score and routes to review.
6. Auto-link is reversible and auditable; merge/split is stricter and always creates review/audit history.
7. Unknown data is not a negative signal by default.
8. Missing context must not be invented to make a candidate match.
9. Thresholds are versioned and calibrated from reviewed examples, not treated as universal constants.
10. Every resolution result explains its signal breakdown and reason codes.

## 3. Resolution pipeline

```text
Extracted entity mention
    |
    v
Safe text normalization
    |
    v
Candidate generation
    |
    v
Feature / signal calculation
    |
    v
Hard-conflict checks
    |
    v
Entity-specific scoring / policy
    |
    +--> AUTO_LINK
    +--> REVIEW
    +--> NO_MATCH / NEW ENTITY CANDIDATE
    |
    v
Reviewer feedback / alias history / calibration dataset
```

## 4. Thai text normalization

Normalization is for **candidate search**, not proof of identity.

### Safe baseline

For Thai and mixed-language names:

1. Unicode normalize to NFC.
2. Trim leading/trailing whitespace.
3. Collapse repeated whitespace to one space.
4. Normalize common non-breaking/zero-width formatting characters where safe.
5. Normalize ASCII letter case for Latin text.
6. Preserve Thai vowels, tone marks, consonants, digits, and semantic punctuation unless a separately reviewed rule says otherwise.
7. Preserve the original source string alongside every normalized form.

### Do not do globally

Do not globally:
- remove Thai tone marks
- remove vowels
- transliterate Thai to Latin and treat the result as unique identity
- strip all punctuation blindly
- strip tokens such as `เจ้า`, `ไอ้`, camp labels, province labels, or honorific-like prefixes and then assume equality

These transformations may create **search aliases/features**, but never become canonical equality rules by themselves.

## 5. Name representation

Each entity mention should retain:
- `raw_name`
- `normalized_name`
- optional tokenized/search representation
- source item/evidence reference
- source-specific context

Canonical entities retain:
- canonical name
- normalized canonical name
- verified aliases
- revoked/unverified aliases where useful for audit

Alias types already include concepts such as:
- alternate name
- spelling
- title/prefix variation
- source label
- former name
- other

## 6. Candidate generation

Candidate generation should prefer high recall without deciding identity yet.

For bulls, candidate pool may come from:
- exact normalized canonical name
- exact verified alias
- fuzzy canonical/alias similarity
- same camp + similar name
- same owner + similar name
- same province + similar name
- known source-specific historical label mapping
- recent opponent/event co-occurrence

Candidate generation returns a bounded top-N set. It does not auto-link.

## 7. Signal model for bulls

### Strong positive signals

Examples:
- exact verified alias match
- stable source-native entity identifier previously verified for this bull
- exact normalized name plus verified same camp/owner context
- same rare lineage/physical attributes plus compatible name/context
- repeated historically verified source-label mapping

### Medium positive signals

Examples:
- exact normalized name
- high fuzzy name similarity
- same camp
- same owner
- same province/district
- compatible opponent/event context
- compatible chronology

### Weak positive signals

Examples:
- broad geographic similarity
- common name token overlap
- same source category

Weak signals should never drive auto-link alone.

### Strong negative/conflict signals

Examples:
- two differently identified bulls appear in the same event/match context where they cannot be the same participant
- candidate entity has a verified different stable source-native ID for the same source namespace
- incompatible camp/owner evidence at the same time with strong provenance
- impossible chronology
- incompatible lineage/physical facts when those facts are strongly verified
- reviewer previously split/rejected the exact identity pair

Strong conflicts force `REVIEW` or `NO_MATCH` regardless of a high name score.

### Soft negative signals

Examples:
- different current camp where historical transfer is possible
- different province when relocation is possible
- mild age/weight discrepancy

These reduce confidence but do not prove non-identity.

## 8. Entity-specific context

### Bulls
Use:
- name/aliases
- camp/owner at relevant time
- province
- opponent/event/date
- lineage/appearance when known
- verified source mapping
- identity history

### Camps
Use:
- name/aliases
- owner relationship
- province/district
- associated bulls
- historical naming patterns

### Owners
Use:
- name/aliases
- camp relationships
- geography
- carefully protected contact metadata only in authorized backend matching when product-necessary; never expose private contact data to public matching output

### Venues
Use:
- name/aliases
- province/district/address
- coordinates
- event history

### Events
Use:
- event name
- venue
- date/time precision
- participating matches
- organizer/source context

## 9. Scoring architecture

The score is a decision aid, not truth.

Conceptual score:

```text
positive weighted evidence
- soft contradiction penalties
=> raw score
=> calibrated probability-like score 0..1
```

Hard conflicts are evaluated separately and may override the score.

Do not encode every signal into one opaque LLM score. Prefer deterministic feature calculations where possible, with AI used only for tasks that genuinely require semantic interpretation.

## 10. Initial conservative policy

The policy is machine-readable and versioned. Initial values are intentionally conservative until real reviewed Thai data exists.

### Bull auto-link

Auto-link requires **all**:
- score at or above the configured bull auto-link threshold
- no hard conflict
- at least two independent positive signal groups
- at least one strong identity/context signal beyond plain fuzzy name similarity
- candidate margin over the second-best candidate at or above configured minimum

An exact normalized name by itself never satisfies this rule.

### Review

Route to review when:
- score falls in the review band
- top candidates are too close
- a hard/important conflict exists
- stable identifier disagrees with name/context
- source mapping is new/unverified
- merge/split is proposed

### No match / new entity candidate

Use when:
- no plausible candidate meets the candidate floor
- strong evidence supports a distinct entity
- reviewer previously rejected the exact association and no materially new evidence exists

## 11. Initial threshold defaults

These are starting points only and must be calibrated before broad automation.

For `BULL`:
- candidate floor: `0.55`
- review floor: `0.72`
- auto-link threshold: `0.97`
- minimum top-vs-second margin for auto-link: `0.10`
- minimum independent positive signal groups: `2`

For `CAMP`, `OWNER`, `VENUE`, `EVENT`, initial auto-link remains conservative and configurable independently.

No automatic **merge** threshold exists. Merge is a controlled review/domain operation.

## 12. Independent signal groups

To avoid double-counting correlated features, signals are grouped.

Suggested groups:
- `NAME`
- `VERIFIED_ALIAS_OR_STABLE_ID`
- `CAMP_OWNER`
- `GEOGRAPHY`
- `EVENT_OPPONENT`
- `LINEAGE_PHYSICAL`
- `SOURCE_HISTORY`
- `CHRONOLOGY`
- `REVIEW_HISTORY`

For example, exact name + fuzzy name similarity still count as one `NAME` group, not two independent confirmations.

## 13. Candidate margin

High top score is unsafe when two candidates are nearly tied.

Example:

```text
Bull A candidate: 0.98
Bull B candidate: 0.96
```

This should not auto-link merely because 0.98 exceeds threshold. The small margin means ambiguity remains.

## 14. Stable source mapping

If a source provides a stable entity identifier, store a verified mapping only after review or trustworthy deterministic confirmation.

Conceptual mapping:

```text
source namespace + source-native entity id -> canonical entity id
```

Once verified, this becomes one of the strongest future resolution signals.

A later contradictory mapping creates a review case; it must not silently remap history.

## 15. Alias lifecycle

Alias states should conceptually distinguish:
- observed/unverified
- verified
- revoked/rejected

Current database schema has `verified` on alias tables; Phase 1 may extend alias decision metadata if implementation needs richer lifecycle.

Every verified alias should be traceable to:
- evidence and/or
- review action

If an alias is later revoked, preserve the history rather than deleting the fact that it was once used.

## 16. Merge policy

Merge means two canonical records are determined to represent the same real entity.

Merge requires:
1. explicit review case
2. side-by-side evidence/context
3. selection of surviving canonical entity
4. impact preview: matches, aliases, camps/owners, evidence, stats
5. reviewer confirmation
6. append-only `identity_events` record
7. provenance preserved
8. safe reassignment/redirect strategy

Do not physically destroy the source canonical identity immediately. Prefer a tombstone/redirect/merged status strategy so historical references and rollback remain possible.

## 17. Split policy

Split is needed when one canonical entity was incorrectly used for multiple real entities.

Split requires:
1. explicit review case
2. identify which matches/aliases/facts belong to each resulting entity
3. create/choose target canonical records
4. preview statistics impact
5. reviewer confirmation
6. append-only identity event
7. migrate affected references through a controlled transaction
8. recompute derived stats from canonical match data

Split is never performed automatically by an AI score.

## 18. Reversibility

Every entity-resolution decision must be explainable later from:
- policy version
- signal values
- candidate list
- score/margin
- evidence refs
- review action when applicable
- identity event for merge/split

Auto-links should retain enough metadata to be re-evaluated under a newer policy.

## 19. Reviewer UX requirements generated by this strategy

For an entity-match review, the UI must show:
- raw source name
- normalized/search form
- candidate canonical names/aliases
- score and top-candidate margin
- signal groups, with positive/negative/conflict reasons
- camp/owner/geography context
- relevant event/opponent/date context
- source/evidence links
- previous reviewer decisions for the same pair

Reviewer actions:
- link to candidate
- create new entity
- reject candidate
- mark alias verified where appropriate
- propose merge/split through a separate destructive workflow

## 20. Feedback and calibration dataset

Every reviewed resolution becomes labeled training/calibration data:
- mention/context
- candidate set
- feature values
- algorithm recommendation
- reviewer decision
- policy version

This dataset is used to measure precision/recall and tune thresholds.

Do not train directly on reviewer labels without preserving time/version splits; otherwise evaluation may leak future decisions into historical tests.

## 21. Evaluation metrics

Primary metric for automatic linking: **precision**.

A false auto-link can corrupt an entire bull history, so initial system should accept lower recall in exchange for very high precision.

Track at least:
- auto-link precision
- review precision / acceptance rate
- false-link rate
- new-entity false creation rate
- top-1 accuracy
- top-k candidate recall
- calibration by score band
- reviewer disagreement rate
- decisions by source/entity type

## 22. Golden fixtures

Before enabling auto-link broadly, build a fixture set containing:
- exact same bull + exact name
- same bull + alternate spelling
- same bull + changed camp
- same bull + source-specific prefix
- different bulls + same name
- different bulls + similar name + same province
- rematch cases
- contradictory stable IDs
- merge and split historical corrections
- Thai Unicode/spacing variants

Fixtures must include both positive and adversarial negative cases.

## 23. Policy configuration

Machine-readable policy shape:
`packages/contracts/schemas/entity-resolution-policy.schema.json`

The policy records:
- version
- entity-specific thresholds
- required signal groups
- candidate margin
- hard conflict behavior

Scoring weights themselves may evolve in an implementation-specific config, but the decision boundary remains auditable/versioned.

## 24. Implementation boundary

### Entity Resolution service owns
- candidate generation
- deterministic feature calculation
- scoring/calibration
- hard-conflict detection
- `EntityMatchResult` production

### Review/domain service owns
- final reviewed link decision
- alias verification
- canonical entity creation
- merge/split execution

### AI provider adapter may assist with
- semantic spelling/name interpretation
- context extraction already represented as claims

It may not directly execute merge/split or override deterministic conflict rules.

## 25. Definition of Done

`BMI-P0-007` is complete when:
- Thai-safe normalization behavior is explicit
- same-name ambiguity is explicitly handled
- positive/negative signal model is documented
- auto-link requires more than a name score
- top-candidate margin is considered
- hard conflicts override score
- merge/split is human-controlled and reversible
- reviewed decisions form a calibration dataset
- machine-readable threshold policy exists
- review UI requirements are available to `BMI-P0-008`
