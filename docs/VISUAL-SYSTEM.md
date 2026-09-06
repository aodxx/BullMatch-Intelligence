# BullMatch Visual System — Real Bull / Sports Intelligence / Motion

Task: `BMI-APP-004`
Status: **IMPLEMENTATION BASELINE**
Last updated: 2026-09-07

## 1. Purpose

BullMatch must not look like a cute livestock app or a generic business dashboard. The production visual language should feel closer to live sports analysis / broadcast graphics while remaining credible as an evidence-backed data product.

Core expression:

`REAL ANIMAL + ARENA ATMOSPHERE + STRONG TYPE + DATA + MOTION + EVIDENCE`

## 2. Non-negotiable rules

1. Do not use cartoon/cute bull illustrations as the product identity.
2. A generic bull image must never be presented as if it were the identity of a specific bull.
3. Bull profile identity imagery should use the bull's verified `primary_image_ref` / approved `bull_media` when available.
4. If a specific bull has no verified image, show an explicit no-verified-photo state rather than a substitute animal.
5. Real venue/bull photography may be used as atmosphere only when source/rights permit.
6. Avoid repeating the same rounded card/gradient/icon template on every screen.
7. Data hierarchy comes from type, scale, spacing, lines, contrast and motion before decorative icons.
8. Motion should communicate hierarchy/state/excitement, never hide uncertainty or make weak data look certain.
9. `prefers-reduced-motion` must disable non-essential animation.
10. Mobile performance has priority over heavy effects.

## 3. Visual grammar

### Arena surfaces

- deep charcoal / near-black for matchup and identity stages
- warm off-white for reading/data surfaces
- muted oxide/red for competitive emphasis
- gold/sand signal color for verified/live/high-value data cues
- thin broadcast-style separators instead of excessive floating cards

### Typography

- Thai-first system-safe font stack until a production font decision is made
- high-weight, tight tracking for bull names, matchup names and headline numbers
- tabular numerals for statistics
- uppercase/letter-spaced English labels used only as small technical/broadcast eyebrow text

### Numbers

Statistics should read like scoreboards:
- large numeric value
- short label
- small evidence/context note
- avoid decorative icon per metric

## 4. Image treatment

### Bull identity

Use verified bull photography only for specific bull identity.

When unavailable:
- display `ยังไม่มีภาพยืนยัน` / `NO VERIFIED PHOTO`
- do not use another bull as placeholder
- do not use a cartoon bull portrait

### Atmosphere imagery

Atmosphere photographs may be used for:
- dashboard hero
- venue/event header
- editorial section divider
- future matchup stage backgrounds when not implying participant identity

Apply dark overlays, controlled saturation and contrast so text/data remains readable.

## 5. Current licensed atmosphere asset

Current hero atmosphere source:

- File: `Bull Fighting.jpg`
- Author: Wann Majaw
- Source: Wikimedia Commons
- License: CC0 1.0 Universal / public-domain dedication
- Commons page: `https://commons.wikimedia.org/wiki/File:Bull_Fighting.jpg`
- Production image URL currently loaded from Wikimedia thumbnail CDN.

This image is used as general bull-fighting atmosphere only. It does not represent a BullMatch canonical bull, Thai venue, owner, camp or verified historical event.

Before long-term production scale, prefer storing approved/licensed atmosphere assets in BullMatch-controlled asset storage to reduce external hotlink dependency.

## 6. Motion grammar

### Reveal

Use short vertical/opacity reveal for scoreboard data after loading.

### Arena drift

Large atmospheric hero image may use very slow subtle scale/pan movement. It must stop under reduced-motion preference.

### Matchup pulse

The `VS` center signal may use low-amplitude periodic emphasis. Bull names/statistics should remain stable and easy to read.

### Navigation

Active state should use line/contrast movement rather than bouncy mascot animation.

### Interaction

Hover/tap feedback should be short and directional. Avoid playful elastic/bounce animation.

## 7. Current implementation layer

`apps/web/src/visual-system.css` intentionally loads after legacy styles.

This gives APP-004 an additive, reversible implementation path while existing React/API behavior remains unchanged.

The first implementation changes:
- real-photo atmospheric dashboard hero
- non-mascot typographic brand mark
- scoreboard metric layout
- action rails instead of generic quick cards
- dark verified Bull Profile stage
- explicit missing verified-photo placeholder instead of generic bull portrait
- arena-style Match Detail composition
- explicit missing verified-photo participant placeholders
- sports/broadcast navigation treatment
- reduced-motion handling
- responsive mobile adaptations

## 8. Follow-up implementation

The next APP-004 increment should modify React markup/API view models to:

1. render `bull.primary_image_ref` safely in Bull Profile when available
2. expose participant verified image references through the public API before showing real participant images in Match Detail
3. add image error/fallback states
4. add evidence-strength/data-confidence visual primitives
5. add motion/reveal components at React state transitions where CSS-only treatment is insufficient
6. verify contrast and interaction with real mobile screenshots/browser testing

## 9. Accessibility / performance

- maintain readable text contrast over photographs
- do not encode W/L/D or trust only by color
- honor `prefers-reduced-motion: reduce`
- avoid auto-playing video backgrounds
- prefer compressed responsive images and lazy loading for future bull galleries
- keep effects GPU-light on lower-end Android devices

## 10. Product boundary

Visual excitement must never become a misleading betting/prediction interface. BullMatch presents verified history, evidence quality and explainable intelligence. It does not present guaranteed outcomes, stake controls, payout interfaces or betting-wallet UI.
