# Source Evidence Research Notes

Task: `BMI-P2-004`  
Status: research-only evidence log  
Research date: 2026-09-07

## Purpose

This file records what was actually observed while deepening the candidate-source dossiers after the initial shortlist. It is not a source approval record and must not be used to infer permission that is not explicitly evidenced.

The safety rule remains:

`publicly visible != approved for automated collection or reuse`

No Bull/Match facts discovered during this research are retained here as fixtures or canonical data.

## wuachon.co

First-party surfaces reviewed:

- `https://wuachon.co/`
- one already-recorded public article URL from the original dossier, used only to establish browser accessibility

Observed on the homepage snapshot:

- the site is directly browser-accessible
- the homepage exposes program-oriented navigation and recent publication links
- the indexed homepage snapshot did not expose identifiable About, Contact, Terms, Privacy or Copyright text

Search attempts for first-party policy/operator surfaces did not produce a reliable first-party result in this run. A robots.txt result was not independently verified.

Therefore the following remain unresolved and must **not** be inferred:

- legal/operator identity
- authorization for recurring automated access
- robots policy
- API/automation policy
- text/media retention rights
- derivative normalization rights
- attribution requirement
- request frequency, cursor and dedupe rules

Disposition remains `REVIEW_REQUIRED`, `polling_enabled=false`, reliability `UNKNOWN` and cross-check `REQUIRED`.

## Surat Thani Provincial Government

First-party surfaces reviewed:

- `https://suratthani.go.th/home/43-about-us.html`
- the already-recorded official provincial news URL in the dossier

The first-party About surface establishes the provincial-government site/operator context. This materially improves provenance evidence for official provincial content.

It does **not** establish an open-content or automated-collection license. The following remain unresolved:

- terms applicable to recurring automated retrieval
- robots instructions
- reuse/normalization/attribution rights
- safe source-specific polling cadence
- whether a recurring connector is proportionate for an episodic government-news source

Disposition remains `REVIEW_REQUIRED` and `polling_enabled=false`. The candidate is best treated as a possible official corroboration source rather than a primary recurring Bull program/results feed unless later evidence changes that conclusion.

## Thailand Sports Almanac

The initial dossier already records a government operator identity and an `OFFICIAL` provenance proposal. No new first-party automation/reuse policy was established in this follow-up run, so the dossier was intentionally left unchanged rather than turning weak or indirect evidence into a stronger claim.

Disposition remains `REVIEW_REQUIRED` and `polling_enabled=false`.

## Selection implication

No candidate is ready for Production activation.

The current evidence suggests two different future roles:

1. a domain-specialist source may provide useful coverage but needs stronger operator, provenance, rights and automation-policy evidence; and
2. official government sources may provide stronger provenance for facts they actually publish but can have narrower/episodic BullMatch coverage.

The next legitimate gate is not connector implementation. It is resolving enough first-party policy/operator/rights evidence for one candidate, followed by an explicit `OWNER_OR_COMPLIANCE` decision under `source-compliance-evaluation/1.0.0`.
