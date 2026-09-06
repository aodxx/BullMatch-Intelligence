# Contribution & Trust Architecture

Task: `BMI-P1-012`
Status: **IMPLEMENTATION CONTRACT**
Last updated: 2026-09-07
Depends on: PRD v0.3, Thai Bullfighting Domain Model, Database Schema v0.2

## 1. Purpose

BullMatch cannot build useful Big Data by asking people to fill long database forms. The contribution system must make field contribution fast, rewarding and trustworthy while ensuring community users never overwrite canonical history directly.

Target loop:

`Easy Contribution -> Evidence -> Atomic Claims -> Verification -> Visible Impact -> Reputation/Credit -> Better Tools -> More High-Quality Contribution`

The architecture optimizes for **verified useful information**, not submission count.

## 2. Contributor experience principles

1. Mobile-first and field-friendly.
2. Evidence-first whenever practical.
3. AI reduces typing; AI never bypasses verification.
4. Show likely existing bulls/matches/pairings before creating new identities.
5. Let contributors see what happened to their submission.
6. Reward accepted useful claims, not raw uploads.
7. Reputation is scoped by topic/locality and backed by outcomes.
8. First-party owner/camp/venue information is valuable evidence but not absolute authority over historical truth.
9. Keep contribution flows short; expose advanced fields progressively.
10. Never require users to understand internal database terms such as candidate groups or provenance tables.

## 3. Contribution entry points

The public app should eventually expose a prominent **เพิ่มข้อมูล / ส่งหลักฐาน** action with task-oriented choices rather than one giant form.

Primary entry types:

### 3.1 Program / poster / board photo

Use when a contributor has a program image, result board, venue poster or screenshot.

Flow:
1. upload/take photo
2. hash + duplicate check
3. parse OCR/deterministic structure where possible
4. AI extracts candidate venue/date/pairs/names/labels
5. user sees compact row-by-row confirmation
6. system suggests existing bulls/pairings/entities
7. user corrects only uncertain fields
8. submit evidence + atomic claims

### 3.2 Match result

Fast path for someone at the venue.

Minimum confirmation:
- venue/event or current program
- bull A
- bull B
- result
- duration if known
- optional photo/video/result-board evidence

If the pair already exists in a verified program, the user should select the existing pair instead of retyping identities.

### 3.3 Bull identity/profile evidence

Inputs may include:
- bull photo
- name/alias
- owner/camp association
- locality
- physical markings
- horn/yod observation
- lineage claim
- external identifier where permitted

The UI must strongly warn against creating a new bull when likely identity matches exist.

### 3.4 Comparison day / วันเปรียบ

Contributor may submit:
- comparison session/venue/date
- bulls present
- proposed/rejected/accepted pairs
- observed weight/labels/conditions
- photos/program references

Comparison participation does not automatically create a match.

### 3.5 Correction

Every public verified profile/history surface should eventually support **เสนอแก้ไข**.

Correction flow references the exact fact being challenged and asks for replacement value + evidence/reason. It creates a competing claim rather than editing the canonical row directly.

### 3.6 Link / video reference

Contributor submits a URL plus optional note/timestamp. The system stores permitted metadata/reference, detects duplicates, extracts candidate claims if allowed and sends them through normal verification.

## 4. Submission state machine

Recommended `community_submissions.status` lifecycle:

`RECEIVED`
-> `PARSING`
-> `CLAIMS_READY`
-> one of:
- `REVIEW_REQUIRED`
- `PARTIALLY_ACCEPTED`
- `ACCEPTED`
- `REJECTED`
- `DUPLICATE`
- `FAILED`
- `WITHDRAWN`

Rules:
- technical parse failure is not the same as rejected information
- duplicate submissions should still be able to contribute new evidence to an existing claim/candidate
- accepted submission does not imply every claim inside it was accepted

## 5. Claim lifecycle

Atomic claim lifecycle:

`PROPOSED`
-> `REVIEW_REQUIRED` or `CORROBORATED`
-> `VERIFIED`

Alternative terminal/intermediate states:
- `CONFLICT`
- `REJECTED`
- `SUPERSEDED`
- `WITHDRAWN`

Important distinctions:
- `CORROBORATED`: enough independent support exists to route more confidently, but publication policy may still require review.
- `VERIFIED`: policy/review has accepted the claim.
- `CONFLICT`: meaningful contradictory evidence exists.
- `SUPERSEDED`: a later claim/decision replaces this value while preserving history.

Promotion from `VERIFIED` claim to canonical record is a separate controlled operation with provenance and audit.

## 6. AI-assisted confirmation UX

AI should act as a form assistant.

Recommended confirmation UI:

- show original image/reference beside extracted rows
- highlight uncertain fields only
- confidence displayed internally or subtly; do not force users to interpret model probabilities
- likely entity matches shown with real bull photo/name/camp/history when available
- one-tap choices: **ถูกต้อง / แก้ไข / ไม่ทราบ**
- never invent a value to complete a row
- preserve raw source wording for names/labels even when normalized fields are suggested

For a program containing many pairs, support batch confirmation but require explicit review of low-confidence identity matches.

## 7. Identity safety

Creating duplicate bull identities is one of the highest-risk data-quality failures.

Before new bull creation, candidate matching should consider:
- normalized/alias name
- owner/camp/locality context
- real bull imagery/markings/horn morphology when available
- chronology
- known opponents/programs
- external identifiers where permitted

UI outcomes:
- **น่าจะเป็นตัวนี้** — contributor links to existing candidate
- **ไม่ใช่ตัวเดียวกัน** — record negative signal for future matching
- **ยังไม่แน่ใจ** — keep unresolved candidate
- **สร้างวัวใหม่** — allowed only after candidate check

Name similarity alone never auto-merges bulls.

## 8. Evidence quality model

Evidence quality should be classified independently from contributor reputation.

Suggested dimensions:
- source proximity: first-party/venue/on-site/secondary/repost/unknown
- media clarity: clear/partial/unreadable
- temporal proximity: live/same-day/historical/unknown
- identity specificity: durable ID / clear visual / contextual / name-only
- tamper/duplication signals
- source diversity
- public/restricted rights/access classification

Evidence quality can influence routing but cannot transform a weak claim into truth by itself.

## 9. Contributor reputation model

No single global reputation score should control BullMatch.

Core dimensions:
- `BULL_IDENTITY`
- `MATCH_RESULT`
- `PROGRAM_DATA`
- `LINEAGE`
- `PHYSICAL_STYLE`
- `EVIDENCE_QUALITY`
- `REVIEW_QUALITY`

Context scopes may include:
- venue
- province/region
- time/recency

A contributor can therefore be highly trusted for match results at one venue while remaining low-confidence for lineage assertions.

## 10. Reputation event policy

Reputation changes come from immutable verified outcomes, not self-reported expertise.

Positive event examples:
- verified claim accepted
- evidence resolved an identity conflict
- contributor correctly rejected a false duplicate match
- high-quality venue/program evidence accepted
- community review later agreed with authoritative result

Negative/quality events:
- repeatedly overturned claims
- evidence falsely attributed
- duplicate flooding after warnings
- coordinated abuse
- low-quality copied submissions with no incremental evidence

Do not punish good-faith uncertainty. `ไม่ทราบ` and unresolved claims are preferable to guessing.

## 11. Reputation computation boundaries

The exact score formula is intentionally deferred until real data exists.

Initial production policy should favor transparent bands over misleading precision, for example:
- NEW
- DEVELOPING
- RELIABLE
- HIGHLY_RELIABLE

Each band should require a minimum verified sample size.

A contributor with 1/1 accepted claim must not display the same confidence as someone with 100/105 accepted claims.

Possible future computation can use Bayesian/shrinkage methods, but the schema stores event history so formulas can evolve without rewriting source outcomes.

## 12. Contributor public profile

Opt-in public profile may show:
- display name/handle
- accepted contribution count
- verified evidence impact
- venue/topic expertise badges
- contribution streak/activity where useful
- reputation bands by dimension
- notable verified contributions

Do not expose email, private contact information, internal abuse scores or sensitive identifiers.

## 13. Contributor feedback loop

Every contributor should be able to open **ข้อมูลที่ฉันส่ง** and see:
- submission status
- which claims were accepted
- which were rejected/conflicted and why at a safe level
- whether evidence was duplicate but still useful
- reputation/credit earned from verified outcomes
- request for additional evidence if review needs it

This is essential: contributors must see that their effort improved the shared database.

## 14. Owner / camp / venue profile claims

A registered contributor can request a relationship claim such as:
- owner/representative of bull
- camp representative
- venue operator/staff

Verification may require account evidence, venue confirmation or reviewed documentary evidence.

Verified profile claim may grant scoped tools such as:
- propose/update current profile media
- submit first-party announcements/program versions
- maintain public camp roster metadata
- receive faster routing for relevant first-party claims

It must never grant:
- ability to delete verified losses
- ability to overwrite historical ownership records silently
- authority to resolve identity conflicts unilaterally
- reviewer/admin privileges outside explicit policy

## 15. Venue data partner tier

Venue/operator contributors are strategically important because they can convert BullMatch from secondary scraping to primary data capture.

Future venue workflow:
- create comparison session
- register/confirm pairings
- publish program version
- amend program
- record official result
- attach official evidence

Venue-origin data can receive high source-proximity weight, but still retains provenance and cannot erase contradictory historical evidence.

## 16. Anti-spam and abuse controls

### 16.1 Rate/routing controls

Use server-side controls based on:
- account age/status
- recent verified quality
- submission type
- duplicate rate
- abuse signals

Do not use reputation alone as authorization.

### 16.2 Duplicate flooding

Before accepting a new submission:
- hash uploaded evidence
- normalize source URLs
- compare venue/date/pair context
- detect repeated claims from same contributor

Duplicate evidence may be linked to an existing case rather than stored repeatedly.

### 16.3 Evidence reuse

The same image reused to support contradictory unrelated events is a signal for review.

Content hash is a signal, not proof of abuse: reposted program images may legitimately appear from multiple contributors.

### 16.4 Coordinated manipulation

Future detection may consider:
- clusters of new accounts supporting the same contested claim
- highly correlated submission timing/content
- repeated reciprocal review agreement

Automatic detection should route to moderation, not silently rewrite facts or ban users without policy.

### 16.5 Moderation actions

Possible account states/actions:
- warning/education
- slower review routing
- submission limits
- evidence upload restriction
- suspension
- ban

Historical accepted contributions remain attributable/auditable even after account suspension.

## 17. Community review

Community review may become a useful scale mechanism, but it cannot simply be majority voting.

Review eligibility should depend on scoped track record and task risk.

Low-risk examples suitable for trusted community confirmation:
- program row transcription
- clear venue/date labels
- obvious duplicate source image

High-risk examples retain stronger review requirements:
- bull identity merge/split
- contested result
- lineage parentage
- profile ownership dispute
- irreversible canonical identity operations

Multiple reviews from correlated accounts should not count as independent evidence.

## 18. Review queue routing

Every review case should calculate/rank operational priority from factors such as:
- claim importance to published statistics
- conflict presence
- evidence quality
- contributor track record in relevant dimension
- source diversity
- potential duplicate/identity risk
- age of backlog

Priority affects queue order, not truth.

This architecture becomes the contract for re-scoped `BMI-P1-008`.

## 19. Data Credit

Data Credit is a contributor value mechanism, not money and not a data-trust score.

Credits should be awarded only after useful verified outcomes.

Possible credit events:
- accepted unique match/result evidence
- verified new bull identity information
- accepted program version not already known
- conflict-resolving evidence
- verified lineage/temporal affiliation contribution
- high-quality community review

No credit for:
- raw submission volume
- exact duplicates with no new value
- self-review
- rejected spam

## 20. Contribute to Unlock

Future premium access can exchange verified contribution value for time-limited feature access.

Example architecture only:
- monthly contribution value ledger
- thresholds unlock selected Pro features for a period
- monetary subscription remains an alternative for users who do not contribute

Exact prices, thresholds and conversion rates are intentionally deferred until real contribution/review costs are measured.

Do not create a transferable cash-like token or gambling balance.

## 21. Security/API boundary

Browser clients never write canonical bull/match/history tables directly.

Recommended server command families:
- create submission
- upload/register evidence
- confirm extracted item
- withdraw own unresolved submission
- read own submission status
- request profile claim
- read own contribution/reputation summary

Server derives authenticated user ID from validated token; client never supplies authoritative `submitter_user_id`.

Contributor APIs cannot invoke admin promotion/merge/split operations.

Private evidence access uses signed/authorized delivery according to `access_class` and rights policy.

## 22. Privacy and safety

Avoid collecting unnecessary personal information.

Public contributor identity is opt-in.

Private contact details for owners/representatives remain outside public profile tables.

Images may contain people/license plates/private details; upload moderation and access classification should allow restriction before public display.

Evidence retention/deletion policy must distinguish:
- canonical provenance need
- user privacy request
- legal retention requirement
- copyrighted/restricted content

## 23. Notification design

Useful contributor notifications:
- submission parsed and needs confirmation
- claim accepted
- additional evidence requested
- conflict resolved
- reputation badge/band changed
- credit unlocked

Avoid noisy notifications for every internal pipeline state.

## 24. Success metrics

Primary network health metrics:
- verified useful claims per active contributor
- evidence-backed submission rate
- duplicate rate
- time from submission to verified outcome
- percentage of submissions requiring manual re-entry
- contributor return rate after first accepted contribution
- review actions per verified fact
- overturn rate by reputation dimension
- conflict resolution rate
- venue/camp first-party contribution share
- cost/storage/AI usage per verified contribution

Raw submission count is not a success metric by itself.

## 25. Failure modes to avoid

- giant database-style contribution form
- points for every upload
- one global trust score
- direct owner editing of adverse history
- AI auto-publishing because confidence is high
- majority vote deciding bull identity
- creating a new bull whenever spelling differs
- forcing uncertain local terminology into a fixed taxonomy
- storing large media blobs in PostgreSQL
- turning Data Credit into betting currency or wallet value

## 26. Implementation sequencing

Recommended implementation after contract approval:

1. **P1-008 re-scoped Review Backend** — claim decisions, evidence access, idempotent review commands, conflict handling.
2. Community contribution migration slice A/B from Schema v0.2.
3. Controlled submission API.
4. Basic mobile contribution UI: result/program/correction.
5. AI-assisted program/photo extraction.
6. Contributor status/reputation surfaces.
7. Profile claim flow.
8. Community review for low-risk tasks.
9. Data Credit / Contribute-to-Unlock experiment only after quality metrics exist.

Visual rebaseline BMI-APP-004 may proceed in parallel where it does not conflict with these backend contracts.

## 27. Definition of done

BMI-P1-012 is complete when the project has an explicit contract for:
- contribution entry flows
- AI confirmation UX
- submission and claim states
- identity/duplicate safety
- evidence-quality routing
- scoped reputation
- contributor feedback
- owner/camp/venue claims
- anti-spam/abuse controls
- community review boundaries
- Data Credit / Contribute-to-Unlock boundaries
- contributor API/security/privacy rules
- implementation order for the re-scoped review backend and community system

No production migration or credit economy is required in this architecture task.