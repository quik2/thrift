# ThriftFlip MVP Canonical Plan

**Last updated:** February 16, 2026

---

## Purpose

This is the single source of truth for what the MVP is.

If another doc conflicts with this one, this doc wins.

---

## Product Contract (MVP)

**User promise:**
`Scan the tag and item, then get an eBay-backed price range with confidence.`

**What the MVP must do:**
1. Capture item photos from a camera-first mobile flow.
2. Extract tag text (brand, size, material, RN/CA when present).
3. Fetch comparable current and sold listing data from eBay-based sources.
4. Return a price range (`low`, `median`, `high`) and confidence score.
5. Show supporting comps and let users save to a collection.

**What the MVP does not promise:**
1. Accurate brand identification from plain unbranded garments.
2. Authentication of luxury goods.
3. Multi-platform one-tap cross-listing.
4. Guaranteed sold data coverage for every niche item.

---

## Scope

## In Scope

1. Camera scan flow.
2. OCR extraction from labels/tags.
3. eBay current listing data.
4. eBay sold data via easiest practical provider (Apify first).
5. Price estimation engine v1.
6. Confidence scoring + low-confidence UX state.
7. Save results to "My Finds".
8. Correction input when results are wrong.

## Out of Scope

1. Poshmark/Mercari automation.
2. Depop integration.
3. Advanced gamification, widgets, public social features.
4. Complex subscription packaging experiments.
5. Full vector-database moat buildout as a release blocker.

---

## Packaging Decision (MVP)

1. Free tier: 5 scans per day
2. Paid tier: advanced workflow and selling utility
3. Multi-platform automation is not part of MVP paid value

---

## UX Requirements

1. Camera is default home state.
2. Scanning state is clear and fast; failure states are explicit.
3. Result card always shows:
   - estimated range
   - confidence
   - comps count
   - source context
4. Low-confidence results must use cautious copy:
   - "We think this might be..."
   - prompt user to scan the tag for stronger results
5. Results must be presented as guidance, not certainty.

---

## Data Strategy (MVP)

1. Current listing data source: eBay Browse API.
2. Sold data source: Apify eBay sold listings provider.
3. Cache strategy:
   - normalize query keys (brand + category + key attributes)
   - cache comp sets and summary stats
   - reuse results aggressively for speed/cost
4. If sold coverage is thin:
   - expand query radius
   - widen confidence interval
   - show reduced confidence

---

## Pricing Engine v1

1. Build candidate query from OCR + item type.
2. Pull comps and normalize to comparable condition where possible.
3. Remove outliers using robust rules (example: IQR-based filtering).
4. Compute:
   - `low` = lower percentile
   - `median` = central estimate
   - `high` = upper percentile
5. Attach confidence based on:
   - tag extraction quality
   - comp count
   - comp variance
   - attribute match quality

---

## Confidence Rules

1. High confidence:
   - clear tag extraction
   - enough comps
   - low-to-moderate variance
2. Medium confidence:
   - partial extraction or lower comp depth
3. Low confidence:
   - weak tag signal
   - sparse or noisy comps
   - high variance

Low confidence must trigger conservative UX and no hard claim language.

---

## Trust and Privacy Contract

In-app copy must stay true:
1. Photos are not shared without user action.
2. Photos are stored only when needed for features the user invokes (save/list history).
3. Users can delete saved items and associated media.

Avoid absolute statements that conflict with product behavior.

---

## Launch Gates (No Dates)

MVP is ready only if all are true:
1. Median scan-to-result latency is acceptable in real user conditions.
2. Results are rated useful by beta users at target threshold.
3. Low-confidence behavior prevents overconfident wrong claims.
4. Major crash/error paths are stable.
5. Support burden is manageable with current team bandwidth.

---

## Expansion Triggers

Only expand scope after MVP gates pass.

## eBay Listing Publish (next)

Add when:
1. scanner usefulness is validated,
2. confidence behavior is calibrated,
3. backend reliability is stable.

## Multi-platform Expansion (later)

Add Poshmark/Mercari only after:
1. clear paid demand exists,
2. eBay listing flow is stable,
3. legal/platform risk tolerance is explicitly accepted.
