# Thai Bullfighting Domain Model — วัวชนไทย

Version: **0.1 — Domain Rebaseline**
Task: **BMI-P1-009**
Status: **RESEARCH BASELINE / PRODUCT REBASELINE INPUT**
Last reviewed: **2026-09-06**

## 1. Why this document exists

BullMatch Intelligence cannot be designed correctly as a generic `Bull + Match + Winner` sports database.

Thai bullfighting (วัวชน / ชนโค), especially the Southern Thai ecosystem, is a cultural, animal-husbandry, sporting, social, economic, venue-operated and legally regulated domain. A useful information platform must model the real lifecycle around a bull and a match, not only the final result.

This document establishes the domain model that must be understood before BullMatch is opened for public/community contributions.

The product direction is therefore:

> **Open contribution, closed truth.** Anyone may contribute observations, claims, corrections and evidence; nobody writes directly over canonical history merely because they submitted a form.

Canonical history is assembled from evidence-backed, claim-level verification.

---

## 2. Scope and product boundary

BullMatch is an **information, provenance, historical-record and analytics platform** for the Thai bullfighting ecosystem.

It may record source-observed facts such as:

- bull identity and aliases
- lineage claims
- owner/camp/keeper relationships over time
- physical and color descriptors
- horn/yod descriptors
- preparation/training observations
- comparison-day (วันเปรียบวัว) activity
- pairing agreements and program announcements
- venue, event and match information
- match result, duration and result reason
- published prize/financial labels appearing in source programs
- photos, video references and documentary evidence
- corrections, conflicts and provenance

BullMatch is **not** an online bookmaker, bet-taking service, wallet, deposit system, odds engine or payout service. Financial information associated with a match is archival/source metadata only unless a future lawful product scope is separately reviewed.

---

## 3. Domain lifecycle: a match begins before match day

The system should understand a recurring lifecycle rather than treating a bull as moving through one permanent linear state.

### 3.1 Bull lifecycle context

A bull may pass through repeated episodes involving:

1. **Breeding / lineage origin** — birth, sire/dam claims, breeder, farm/camp of origin.
2. **Acquisition / transfer** — purchase, exchange, gifting or change of custodian/owner.
3. **Selection** — evaluation of body structure, temperament, horn form and perceived suitability.
4. **Training / preparation** — exercise, care, sparring/วาง/ซ้อม and observation of `ทางชน`.
5. **Comparison readiness** — owner/camp decides to seek a suitable opponent.
6. **Comparison day — วันเปรียบวัว** — bulls are brought for comparison of size, proportions, horns and perceived advantage/disadvantage.
7. **Pairing / agreement** — a proposed pair becomes an agreed pair; program timing and financial terms may be agreed and/or later published.
8. **Pre-match preparation** — intensified care, travel/temporary housing, local rituals or customary preparation where applicable.
9. **Program publication / amendment** — venue or media publishes the card; pairs can be reordered, changed or cancelled.
10. **Match occurrence** — actual encounter under the venue/event's applicable rules.
11. **Outcome** — win/loss/draw/cancelled/no-result plus duration and reason when known.
12. **Recovery / rest** — health, rest or return to training.
13. **Next cycle / retirement / breeding / sale / death** — a bull's active sporting life and ownership may continue to change.

### 3.2 Critical modeling consequence

`วันเปรียบ` is not merely a note attached to a match. It is a first-class domain event that can create:

- many comparison candidates
- rejected pairings
- accepted pairings
- deposits/conditions described by sources
- later match-day program entries
- subsequent cancellations or substitutions

Therefore `comparison session`, `pairing agreement`, `program entry` and `actual match` must be distinguishable records.

---

## 4. The bull is a temporal identity, not a row of current attributes

### 4.1 Stable identity

A BullMatch `bull_id` identifies the animal, not its name.

Names are evidence-bearing labels attached to an animal. Different bulls may have similar or identical names, and one bull may appear under:

- a long formal/show name
- a nickname in parentheses
- a shortened name
- a color-prefix name
- a source-only spelling
- a former name
- a camp-associated or location-associated label

Current 2026 program pages demonstrate long names such as a color/type prefix plus a formal name and nickname/alias in parentheses. Owner/camp/location strings may also be compressed into the same published row.

A normalized name is useful for retrieval but **must never be identity proof**.

### 4.2 Identity evidence hierarchy

Possible identity signals, from strong to weak depending on context:

- official/external animal identification number, ear tag or other durable ID when available
- verified source-native identity from an authoritative venue/camp/owner record
- multiple clear photographs showing stable markings and horn morphology
- continuous owner/camp/location history
- match-history continuity and opponent/date relationships
- lineage relationship corroborated by breeder/records
- distinctive physical descriptors
- name/alias similarity

Name similarity alone is weak evidence.

The Department of Livestock Development operates animal-identification/NID processes and in 2026 was actively developing/updating identification rules. BullMatch must therefore support external identifiers without assuming every fighting bull has one universal government ID.

### 4.3 Temporal affiliations

`current_owner_id` and `current_camp_id` are only conveniences. Real relationships should be represented with time and evidence:

- OWNER
- CO_OWNER where supported
- BREEDER
- CAMP
- KEEPER / HANDLER / คนเลี้ยง
- TRAINER if the local/source context distinguishes it
- VETERINARY / animal-care association when publicly documented and relevant

Each affiliation needs at least:

- subject bull
- party/person/organization/camp
- relationship type
- valid-from / valid-to or date precision
- source/evidence
- verification state
- contributor who proposed it

A historical match must preserve the owner/camp/label reported at that time even after a later transfer.

---

## 5. Physical vocabulary is first-class data

A single free-text `color_description` is too shallow for Thai bullfighting.

### 5.1 Color and markings

Southern Thai sources use color and marking vocabulary as part of identification and naming. Common source terms include families such as:

- ขาว
- นิล / ดำ
- แดง
- โหนด
- ลังสาด
- ลาย
- นิลแซม
- ดุกด้าง

Sources also contain compound markings and regional/descriptive forms such as `โหนดหลังขาว`, `โหนดหัวแดง`, `หน้าโพ/หน้าใบโพ`, `หน้าจุด`, `หางดอก`, `ตีนด่าง` and many others.

This vocabulary must remain extensible. BullMatch must not declare an early list to be exhaustive or force every regional term into the wrong category.

Recommended observation structure:

- `trait_family` — COLOR / MARKING / BODY / HORN / OTHER
- `normalized_term` — controlled vocabulary when known
- `raw_term` — exact source wording
- `body_region` when applicable
- `observed_value`
- `observation_date` / precision
- `evidence_id`
- `verification_status`

This allows the system to preserve what people actually say while gradually building a reliable vocabulary.

### 5.2 Horn / ยอด terminology

Horn form is not only appearance; traditional domain knowledge links horn form to expected technique and matchup characteristics. Sources use terms including:

- เขาวง
- เขารอม
- เขากุบ
- เขาแทง
- เขาบิด

Traditional descriptions also use `ยอด`/horn form to discuss whether a bull's actual fighting behavior is consistent with the expected form (`ชนสมยอด` / `ชนไม่สมยอด` concepts in historical descriptions).

BullMatch should store horn morphology as observations, not convert traditional expectations into objective fact.

### 5.3 Fighting style / ทางชน

Source terminology includes techniques/behaviors such as:

- แทง
- แทงแล้วบิด / บิด
- ขัดเขา / งัด
- ฟัน
- เอาเพลียง / พาเพลียง
- ขึ้นเหง / ขึ้นขี่

`ทางชน` should not be one permanent enum stamped onto a bull. It is better represented as one or more **observations supported by bouts, sparring, video or qualified reports**, because style can be described differently by different observers and may evolve.

Suggested fields:

- bull
- style term / normalized category
- observed in MATCH / SPARRING / EXPERT_REPORT / OTHER
- source event/match
- confidence
- exact description
- evidence
- verifier

---

## 6. Breeding and lineage require claim-level modeling

A free-text `lineage_notes` field cannot support serious lineage history.

BullMatch should eventually support:

- sire claim
- dam claim
- breeder/source farm
- offspring relationships
- lineage label/line when the community uses one
- genetic/official evidence where available
- confidence and provenance per relationship

Lineage is especially vulnerable to folklore, marketing and repeated unsourced claims. A relationship must therefore be allowed to remain:

`UNVERIFIED -> CORROBORATED -> VERIFIED`, or `CONFLICT`.

The system must never infer parentage from a similar name, camp or color.

---

## 7. People and organizations in the ecosystem

Research and field descriptions show a wider stakeholder network than `owner/camp/venue`.

Core actor types include:

- bull owner
- breeder
- camp/farm
- keeper/handler / คนเลี้ยงวัวชน
- local expert / ปราชญ์
- หมอวัว in cultural/ritual contexts
- venue owner/operator / นายสนาม
- referee/judge / กรรมการ
- livestock/government officials
- veterinarian/animal-care professional when applicable
- spectator/fan
- media/livestream/page operator
- transport and temporary-housing providers
- vendors/services around the venue ecosystem

BullMatch does not need operational tables for every economic actor in MVP, but the ontology must not incorrectly equate `owner = camp = keeper`.

### 7.1 Sensitive relationships

Some social, business or political relationships around venues can be sensitive. The product should:

- publish only relevant sourced information
- avoid inferring affiliations
- keep private contact fields private
- distinguish a person's self-claimed role from a verified venue/camp role
- allow right-of-reply/correction workflows for public entity information

---

## 8. Event ontology

The current generic `events` table needs a type dimension.

Recommended event types:

- `COMPARISON_DAY` — วันเปรียบวัว
- `MATCH_DAY` — วันชน
- `FESTIVAL_MATCH_DAY` where useful as a tagged subtype, not a separate truth system
- `SPARRING` / `TRAINING` only when the product intentionally records it
- `OTHER`

Schedule/calendar sources may also encode non-event context such as `วันพระ (งดชน)`. This should be represented as calendar/venue-availability context rather than fabricated as a match event.

### 8.1 Venue schedule

Venues may operate on recurring/rotating calendars and individual programs can change. Store:

- announced date/time
- actual date/time when known
- source of announcement
- schedule version
- event status
- cancellation/postponement reason
- superseded announcement relationship

Do not overwrite the original announcement when a program changes.

---

## 9. Pairing, program and match are different objects

### 9.1 Comparison record

A comparison-day record may capture:

- bulls compared
- approximate physical observations at that time
- participating owner/camp/keeper labels
- decision: NOT_PAIRED / PAIRED / UNRESOLVED
- reason/notes if publicly documented
- photos/video/source

### 9.2 Pairing agreement

A confirmed pairing may contain:

- bull A / bull B
- agreement date
- intended venue/event/date
- published terms
- status: PROPOSED / AGREED / WITHDRAWN / SUPERSEDED / FULFILLED / UNKNOWN
- source evidence

Pairing does not guarantee a match occurred.

### 9.3 Program entry

A venue/media program is a versioned publication. Real 2026 program sources use fields such as:

- pair order / คู่ที่
- bull side A and B
- nickname/alias
- owner / camp
- prize / `รางวัล`
- `เสมอนอก`
- featured labels such as `คู่เอก`, `คู่เอกพิเศษ`
- announced start time

There may be more than one featured pair in a card. Therefore `is_main_event boolean` is too shallow. Use a `program_label` / `feature_tier` vocabulary with raw source labels.

### 9.4 Actual match occurrence

The actual match record must distinguish what happened from what was announced.

Minimum facts:

- actual participants
- venue
- event
- actual/estimated start time
- program position as announced and actual position when known
- rule profile in force if known
- duration / precision
- result type
- winner/loser where applicable
- result reason
- evidence
- verification state per important fact

---

## 10. Results are richer than WIN/LOSS

Current result pages show at least:

- win/loss
- draw
- cancelled match
- duration in minutes

Traditional rule descriptions also discuss outcomes caused by behavior/conditions such as falling and not resuming, refusing/running, leaving the ring, or horns remaining locked for a specified period.

Recommended separation:

### Result type

- WIN
- DRAW
- CANCELLED
- NO_RESULT
- UNKNOWN

### Result reason

Use normalized categories only when evidence supports them, for example:

- OPPONENT_WITHDREW / REFUSED_TO_ENGAGE
- FALL_NO_RESUME
- LEFT_ARENA
- HORN_LOCK_TIMEOUT
- PRE_MATCH_CANCELLED
- VENUE_DECISION
- OTHER
- UNKNOWN

Always preserve `raw_result_text` because local/venue wording matters.

### 10.1 Do not hardcode one global rulebook

Sources do not perfectly agree on every timeout detail; historical descriptions include different minute thresholds. This means rules must be **versioned and evidence-backed**:

`rule_profile -> venue/event/date range -> rule clauses -> source/evidence`.

A fact such as “5-minute resumption rule” should never silently become a universal database constraint.

---

## 11. Financial terms: record the label, do not invent its meaning

2026 program pages commonly display `รางวัล` and `เสมอนอก` as separate monetary columns. Historical descriptions of comparison day also mention deposits and agreed financial conditions.

BullMatch should not collapse these into one `stake_amount` and should not assume that one venue/source uses a term identically to another.

Recommended `financial_terms` observation model:

- subject: pairing / program entry / match
- `term_type` when safely normalized: PRIZE / OUTSIDE_TERM / DEPOSIT / PENALTY / OTHER
- `raw_label` — exact source label, e.g. `รางวัล`, `เสมอนอก`
- `amount`
- `currency`
- `source_announced_at`
- `evidence`
- `verification_status`
- `notes`

Until field/domain verification establishes a stable semantic definition, `เสมอนอก` must remain a source-observed label, not an odds formula or betting instruction.

---

## 12. Rules, law, permits and animal welfare are separate dimensions

### 12.1 Gambling/venue permission context

Thai administrative materials list animal contests such as `ชนโค` under gambling-law/permission processes and include a government service for requesting permission to use a venue for bull gambling/`การขออนุญาตใช้สถานที่สำหรับเล่นการพนันชนโค`.

Product implication:

- do not describe every bullfight as automatically lawful merely because bullfighting is traditional
- do not describe a venue as unlawful merely because BullMatch cannot find a public license record
- if permit status is stored, it must be a dated evidence-backed claim
- BullMatch itself remains an information platform and does not facilitate wagering transactions

### 12.2 Animal-welfare context

The Prevention of Animal Cruelty and Provision of Animal Welfare Act B.E. 2557 contains an exception for `การจัดให้มีการต่อสู้ของสัตว์ตามประเพณีท้องถิ่น`, while animal welfare obligations remain relevant more broadly.

Product implication:

- distinguish cultural/legal context from a blanket claim that any treatment is acceptable
- support factual health/welfare or match-cancellation evidence where relevant
- avoid performance claims that encourage harmful handling

### 12.3 Legal facts are time-sensitive

Government animal-identification rules are actively evolving in 2026. BullMatch legal/reference data must therefore have:

- jurisdiction
- effective date / date range
- source document
- last checked date
- superseded-by link

Never bury a changing legal rule in application code as timeless truth.

---

## 13. Cultural knowledge must be preserved without converting belief into science

Research on Southern bullfighting documents local ritual and belief contexts, including auspicious timing, หมอวัว, protective ritual practices and customary preparation.

These are culturally significant data but require a separate epistemic label.

BullMatch should be able to classify a statement as:

- OBSERVED_FACT
- OFFICIAL_RECORD
- PARTICIPANT_REPORT
- TRADITIONAL_KNOWLEDGE
- BELIEF_RITUAL
- ANALYTICAL_INFERENCE
- UNKNOWN_BASIS

Example: “this bull has a white marking on its forehead” can be an observed trait. “this marking guarantees good luck” is a traditional belief claim, not an objective performance fact.

The UI must not mix those categories.

---

## 14. Evidence model: trust is claim-specific

A source should not receive one permanent global score that makes all its statements true.

An official venue program may be strong evidence for:

- announced pairing
- program order
- announced prize labels

but may not be authoritative for:

- biological lineage
- exact birth date
- ownership transfer outside that event

Likewise, a breeder/owner may be strong for lineage or identity context but has an interest in claims about their own bull.

### 14.1 Suggested source/evidence dimensions

For each claim evaluate:

- source role: VENUE / OWNER / CAMP / BREEDER / GOVERNMENT / MEDIA / AGGREGATOR / EYEWITNESS / COMMUNITY / OTHER
- claim proximity: FIRST_HAND / DERIVED / REPOST / UNKNOWN
- evidence form: DOCUMENT / PROGRAM_IMAGE / VIDEO / PHOTO / TEXT / OFFICIAL_RECORD / OTHER
- timestamp proximity to event
- independence from corroborating sources
- known conflict of interest
- whether the source is authenticated/officially linked to an entity

### 14.2 Verification is atomic

Do not verify an entire row when only part is known.

For one match, these can have different states:

- participant A identity — VERIFIED
- participant B identity — VERIFIED
- event date — VERIFIED
- owner snapshot — REVIEW_REQUIRED
- duration — CONFLICT
- result — VERIFIED
- `เสมอนอก` amount — UNVERIFIED

Published statistics may use only the verified result/date/identity facts while still showing other fields as uncertain or hiding them.

---

## 15. Open community contribution model

The user's product goal is that **anyone can help create the dataset**. This must be implemented as an evidence/claim system, not open CRUD on canonical tables.

### 15.1 Contribution types

A signed-in community user should eventually be able to submit:

- NEW_BULL_CANDIDATE
- BULL_IDENTITY_EVIDENCE
- BULL_PROFILE_FACT
- LINEAGE_CLAIM
- OWNER_CAMP_AFFILIATION
- COMPARISON_DAY_REPORT
- PAIRING_REPORT
- PROGRAM_IMAGE / PROGRAM_CORRECTION
- MATCH_RESULT_REPORT
- PHOTO / VIDEO / URL EVIDENCE
- CORRECTION_PROPOSAL
- DUPLICATE_REPORT
- VENUE_INFORMATION
- EVIDENCE_ONLY submission without asserting a conclusion

A low-friction `quick result` UI may exist, but internally it still creates claims + evidence/provenance.

### 15.2 No direct overwrite

Community users never execute:

`UPDATE bulls SET ...`

Instead:

`submission -> claims -> evidence -> entity resolution -> corroboration/review -> verified fact projection`.

Existing canonical history remains intact until a verified correction supersedes it.

### 15.3 Reputation must be multidimensional

One global reputation number is too crude.

A contributor may be highly reliable at reporting results from one venue but know little about lineage. Suggested trust dimensions:

- MATCH_RESULT_ACCURACY
- BULL_IDENTITY_ACCURACY
- PROGRAM_REPORT_ACCURACY
- LINEAGE_ACCURACY
- VENUE_INFORMATION_ACCURACY
- EVIDENCE_QUALITY
- REVIEW_QUALITY

Trust also needs scope:

- venue/region
- role relationship
- historical recency

Reputation may prioritize review; it should not grant unlimited canonical write access.

### 15.4 Verified representatives

Later, BullMatch can support verified entity relationships such as:

- verified venue representative
- verified camp representative
- verified bull owner/custodian

Verification of that relationship is itself an evidence-backed fact with dates. It is not equivalent to administrator privilege.

### 15.5 Conflict of interest

A verified owner is a valuable primary source for their bull but is not automatically an independent verifier of a disputed result involving their bull.

High-impact conflicts should prefer independent corroboration or reviewer resolution.

---

## 16. Entity resolution rules specific to Thai bullfighting

### 16.1 Candidate generation

Useful candidate signals:

- Thai-safe name/alias similarity
- same owner/camp in overlapping time period
- same province/district/village context
- photo/marking/horn similarity as advisory evidence
- matching external animal ID
- match-history continuity
- same opponent/date/program references
- lineage/breeder continuity

### 16.2 Merge prohibitions

Never auto-merge solely because:

- names are identical
- nickname is identical
- same color
- same camp
- same owner
- image model returns a high similarity score

A merge must preserve all previous IDs, aliases, source mappings and audit history. A later split must be possible.

### 16.3 Unknown is not false

Use explicit distinctions:

- UNKNOWN — fact not known
- NOT_OBSERVED — source did not provide it
- NOT_APPLICABLE — concept does not apply
- WITHHELD/PRIVATE — known but not publishable where applicable
- CONFLICT — competing supported values exist

This prevents AI and UI forms from inventing data to fill blank fields.

---

## 17. Place model

Current source strings frequently embed place names in owner/camp labels. Plain `province` and `district` columns are insufficient for long-term resolution.

Recommended place hierarchy:

- country
- province
- district/amphoe
- subdistrict/tambon
- village/muban/locality
- venue coordinates/address when public

Store source-raw place text separately from normalized geocoding.

A location may represent different relationships:

- bull home/current location
- owner residence descriptor
- camp location
- venue location
- breeder origin

Do not collapse them into one `home_province`.

---

## 18. Match analytics that become possible only after correct modeling

With verified history, BullMatch can eventually compute useful non-trivial analytics such as:

- verified career W/L/D and duration distribution
- opponent strength/history
- rematches/head-to-head
- performance by venue
- interval between matches / rest period
- historical camp/owner eras
- match-card position and featured-pair history
- fighting-style observations linked to video evidence
- color/horn vocabulary search without claiming causal performance
- lineage network and offspring match histories when verified
- pairing-to-match conversion/cancellation rate
- source disagreement and data quality metrics

Predictive analytics, if ever introduced, must stay clearly separated from verified historical fact and must not convert traditional beliefs into scientific predictors without evidence.

---

## 19. Gap audit against current BullMatch v0.1 schema

The existing schema has a strong provenance/review foundation but its canonical sports domain is too generic in these areas:

| Current concept | Domain gap | Required direction |
| --- | --- | --- |
| `bulls.current_owner_id/current_camp_id` | relationship changes and keeper/breeder roles | temporal affiliations |
| `bulls.color_description` | rich color/marking vocabulary | evidence-backed physical trait observations |
| `bulls.lineage_notes` | cannot represent parentage/provenance/conflict | lineage relationship claims |
| `bull_aliases` | useful but missing richer name role/source period | typed temporal names with evidence |
| `events` | no distinction between วันเปรียบ and วันชน | typed event ontology |
| `matches` | begins too late in lifecycle | comparison -> pairing -> program -> occurrence chain |
| `match_participants` | good snapshots, but owner/camp alone too narrow | richer match-time affiliation/source snapshot |
| `match_results` | result reason is free text only | raw text + normalized, evidence-backed reason |
| no rule entity | risks universal assumptions | versioned venue/event rule profiles |
| no program version entity | announcements can change | immutable versioned program publications |
| no financial term entity | `รางวัล/เสมอนอก` lost or conflated | raw-label financial observations |
| global role model | only ADMIN/REVIEWER/VIEWER | add community contributor identity without canonical write |
| review workflow | mostly operator/AI review | community submissions, corrections, corroboration |
| source reliability tier | too global | claim-specific source-role/reliability signals |
| province/district fields | source geography is richer | normalized place hierarchy + raw locality text |

No production migration should be made from this table alone. It is input to a deliberate PRD/schema revision.

---

## 20. Proposed future domain entities

Names are architectural placeholders, not approved SQL table names yet.

### Bull identity layer

- `bull_names`
- `bull_identifiers`
- `bull_trait_observations`
- `bull_lineage_claims`
- `bull_affiliations`
- `bull_status_periods`
- `bull_media`

### Match lifecycle layer

- `comparison_events`
- `comparison_entries`
- `pairing_agreements`
- `program_publications`
- `program_entries`
- `matches`
- `match_participant_snapshots`
- `match_results`
- `rule_profiles`
- `financial_term_observations`

### Community/provenance layer

- `community_submissions`
- `submission_claims`
- `proposed_corrections`
- `corroborations`
- `contributor_trust_dimensions`
- `entity_representative_claims`

Existing private evidence/claim/provenance tables should be reused and extended instead of building a competing truth system.

---

## 21. Source taxonomy for initial collection

Initial source categories should be captured separately because each is authoritative for different facts:

1. **Government / legal / livestock records** — regulation, permits where publicly available, animal-ID rules.
2. **Venue-issued program/result material** — highest practical priority for program identity, pair order, announced terms and venue events.
3. **Venue official social/media/live streams** — event occurrence and video evidence.
4. **Owner/camp/breeder material** — bull identity, history, lineage and affiliation claims.
5. **Established bullfighting program/result sites** — discovery and corroboration; not automatically canonical.
6. **Academic/local cultural sources** — vocabulary, history, husbandry, ritual and social context; often not event-level evidence.
7. **Community eyewitness submissions** — valuable, especially with original photo/video, but must retain contributor/provenance metadata.
8. **Reposts/affiliate/betting pages** — discovery-only or low-trust by default; never privileged merely because they rank highly in search.

---

## 22. Evidence-first UI implications

The future public contribution UI should feel simple even though the backend is rigorous.

### Example: “รายงานผลวัวชน”

User sees:

1. สนาม
2. วันที่
3. คู่ที่
4. วัว A
5. วัว B
6. ผล
7. เวลา (ถ้าทราบ)
8. แนบรูป/คลิป/ลิงก์
9. ส่ง

Behind the scenes BullMatch creates:

- source/submission record
- participant identity candidates
- atomic claims
- evidence links
- duplicate/event matching candidates
- contributor provenance
- review/corroboration state

### Example: “สร้างข้อมูลวัวใหม่”

Before creating a new canonical bull, search candidates using:

- formal/nickname aliases
- color/physical hints
- owner/camp/location
- photos
- match history

If there is a plausible existing bull, the UI asks the contributor to choose `อาจเป็นตัวเดียวกัน` or `เป็นคนละตัว` and adds evidence rather than forcing a silent merge.

---

## 23. Questions that require field validation before schema lock

Web/academic research is not sufficient for these points. They should be validated with actual current participants from multiple venues/provinces:

1. What exact fields are recorded on a modern `วันเปรียบ` sheet/program by venues?
2. Which attributes actually decide a comparison in current practice: height, body size, horn/yod, weight, age, prior record, style, or informal judgment?
3. How do venues currently use and distinguish `รางวัล`, `เสมอนอก`, deposits, penalties and other local financial labels?
4. Are current resumption/fleeing/horn-lock time rules uniform across venues, or venue-specific? Historical sources conflict on some minute thresholds.
5. What are the current accepted color/marking categories in Songkhla, Phatthalung, Nakhon Si Thammarat, Trang and neighboring provinces, and which terms are synonyms vs genuinely different traits?
6. How are official/formal bull names created and changed in actual venue records?
7. How often do ownership, camp and keeper differ, and how are transfers publicly proven?
8. Which animal identifiers (NID/ear tag/microchip/local records) are actually available for fighting bulls today?
9. How are late substitutions, withdrawals and program reorderings documented?
10. What evidence do experienced people trust most when deciding that two similarly named historical records refer to the same bull?
11. Which facts should remain private for owner/animal safety even if a contributor knows them?
12. What is the current practical permit/document workflow at active venues, and which parts are publicly verifiable?

These are explicitly marked `FIELD_VALIDATION_REQUIRED`; the system must not invent answers.

---

## 24. Architecture decisions from this rebaseline

The following decisions should be treated as strong recommendations for the next PRD/schema revision:

1. **Keep the existing evidence/claims/review architecture.** It is the right foundation.
2. **Do not expose canonical CRUD to the public.** Add a submission/claim layer.
3. **Make verification fact-level, not only row-level.**
4. **Make bull identity temporal and evidence-backed.**
5. **Introduce comparison-day -> pairing -> program -> actual-match lifecycle.**
6. **Version venue/event rules.** Do not hardcode a universal rulebook.
7. **Preserve exact local vocabulary and normalize second.**
8. **Separate observed traits, traditional knowledge and analytical inference.**
9. **Represent owner/camp/keeper/breeder relationships with time.**
10. **Treat program money labels as descriptive archival metadata, not betting functionality.**
11. **Use multidimensional contributor trust with conflict-of-interest awareness.**
12. **Support external animal IDs but never depend on one universal identifier.**
13. **Preserve all program/result versions and corrections instead of overwriting history.**
14. **Model unknown/conflict explicitly.** Missing data is not permission to guess.

---

## 25. Research sources used for the baseline

Priority was given to university/local-information repositories, Thai academic research, Department of Provincial Administration / government material, Department of Livestock Development material, and contemporary program/result pages used as examples of real data formats.

### Cultural/domain/rules

- Prince of Songkla University Southern Information — วัวชน: https://www.clib.psu.ac.th/southerninfo/content/2/84e61c2f
- Walailak University Local Information — วัวชน : สังเวียนต่อสู้แห่งท้องทุ่งภาคใต้: https://library.wu.ac.th/nst_localinfo/bullfighting/

### Contemporary program/result structure

- WuaChonWin — ลานข่อย 18 May 2026: https://wuachonwin.com/โปรแกรมวัวชน-สนามกีฬาชน-12/
- WuaChonWin — บ้านบางกล่ำ 20 June 2026: https://wuachonwin.com/โปรแกรมวัวชน-วันที่-20-มิ-ย-256/
- WuaChonWin — สมหวังสเตเดี้ยม 27 May 2026: https://wuachonwin.com/โปรแกรมวัวชน-สนามกีฬาชน-14/
- Club Wua Chon — result examples including duration/draw/cancellation: https://clubwuachon.com/ผลวัวชนวันนี้/

### Husbandry / community / cultural practice

- Journal of Spatial Development and Policy — ศึกษาผลกระทบของเกษตรกรผู้เลี้ยงวัวชน: https://so16.tci-thaijo.org/index.php/JSDP/article/view/194
- PSU Culture — research notice on rituals/beliefs of bull keepers in Trang: https://culture.psu.ac.th/published-research/34337/
- Journal of Social Science and Cultural paper: https://so06.tci-thaijo.org/index.php/JSC/article/download/277150/185481/1161324
- Silpakorn University local-history thesis — bullfighting and changing lifestyles in Trang: https://sure.su.ac.th/xmlui/handle/123456789/30546
- Journal of Social Development — วัวชนในบริบทการพัฒนาเศรษฐกิจชุมชน: https://so07.tci-thaijo.org/index.php/JSSD/article/view/8720

### Legal / government / animal identification

- Department of Provincial Administration material listing bullfighting venue permission service: https://multi.dopa.go.th/icad/assets/modules/news/uploads/b1e1f8d4961b7cbe28fdb8a52679419568410cc9a7c169103352774878270169.pdf
- DOPA administrative manual referencing Gambling Act list including ชนโค: https://multi.dopa.go.th/tspd/tpad/assets/modules/work_manual/uploads/6ddcd8f3b62f49aa7dbd59be7055f8ee630eda7ce91ac530530403338404329.pdf
- Department of Livestock Development / Gazette copy of Animal Welfare Act: https://pvlo-kbi.dld.go.th/webnew/images/stories/organization/planning/2563-1/B.pdf
- DLD 2026 animal identification/NID development: https://dld.go.th/webnew/index.php/dld-news/head/head-moac/2569/rxth-rak-thiy-pen-prathan-kar-prachum-khna-thangan-phathnakar-tha-kheruxnghmay-praca-taw-satw-prapheth-bexr-hu-laea-rabb-kar-tha-kheruxnghmay-laea-khun-thabeiyn-satw-haeng-chati-nid
- DLD legal office 2026 consultation on animal-identification rules: https://dld.go.th/webnew/index.php/qa/saedng-khwam-khid-hen/kar-rab-fang-khwam-khid-hen-hlak-kar-pheux-cad-tha-rang-prakas-krm-psusatw-reuxng-kahnd-thxng-thi-laea-chnid-satw-thi-txng-tha-kheruxnghmay-praca-taw-satw-laea-hlak-kenth-withi-kar-laea-ngeuxnkhi-ni-kar-tha-kheruxnghmay-praca-taw-satw-ph-s

---

## 26. Handoff / next decision

This task intentionally changes **no production database or API**.

The next architecture task should convert this domain baseline into:

1. **PRD v0.3 — Community Knowledge Platform revision**
2. **Database Schema v0.2 gap design**
3. **Community contribution + verification workflow**
4. **Migration plan that preserves all existing Phase 1 work**
5. **Field-validation checklist/interview form for actual bull owners, keepers and venue operators**

The migration must be additive and backward-compatible wherever possible. Existing verified-match functionality should become one projection of the richer domain, not be discarded and rebuilt blindly.
