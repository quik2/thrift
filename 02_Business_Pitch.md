# ThriftFlip: Business Pitch (Aligned to Canonical MVP)

**Last updated:** February 16, 2026

---

## Document Role

This file explains the business case and long-term direction.

For implementation scope and build decisions, authority is:
1. `12_MVP_Canonical_Plan.md`
2. `13_MVP_Build_Checklist.md`
3. `14_MVP_Risk_and_Decisions.md`

---

## Executive Summary

ThriftFlip addresses a real workflow pain: thrifters and resellers spend too much time identifying items and checking resale value.

The canonical MVP is intentionally narrow:
1. Scan tag + item photo
2. Return eBay-backed price range with confidence
3. Save to collection
4. Optional next package: eBay listing publish

This is a practical entry point with low platform risk, low infrastructure cost, and fast learning cycles.

---

## 1) Market Context

| Metric | Value |
|--------|-------|
| U.S. secondhand apparel market (2025) | $56B |
| U.S. secondhand apparel market (2029) | $74B |
| Growth rate | 9-13% |
| Market leader reseller-tool revenue | ~$5M/year |
| Estimated reseller tool penetration | 3-10% |

Key takeaway:
- The resale market is large and growing.
- Tool penetration is still early.
- Existing solutions are fragmented across scanning, pricing, and listing workflows.

---

## 2) Problem

Today, users usually do this manually:
1. Read brand tag
2. Search sold listings
3. Compare condition and pricing
4. Decide whether to buy
5. Later, build listings manually

Pain points:
1. Research time per item is high.
2. Confidence is low for unfamiliar brands.
3. Current process is inconsistent and hard to repeat.

---

## 3) Product Strategy

## MVP Product Promise

"Scan the tag and item. Get a confidence-scored resale range fast."

## MVP Capabilities

1. Camera-first scan flow
2. OCR extraction (brand/size/material/RN when visible)
3. eBay current + sold comp retrieval
4. Price range (`low`, `median`, `high`) with confidence
5. Comparable listings display
6. Save to collection
7. Correction input when result is wrong

## Explicitly Out of MVP

1. Multi-platform one-tap listing
2. Poshmark/Mercari automation
3. Depop integration
4. Luxury authentication promises

## Expansion Path

1. Optional next package: eBay listing publish (official API)
2. Later: additional marketplaces, only after reliability and demand are proven

---

## 4) Why This Positioning Works

1. It is honest about capability: tag-forward, confidence-scored outputs.
2. It avoids highest-risk dependency (non-official marketplace automation) in MVP.
3. It gives immediate user value even before cross-listing.
4. It creates a quality flywheel through saved scans and corrections.

---

## 5) Competitive Positioning

Current market split:
1. Scanner tools: identification/pricing focus, weak workflow completion.
2. Cross-listing tools: listing automation focus, weak in-store sourcing help.

ThriftFlip MVP competes by being:
1. Camera-first
2. Trust-first (confidence and uncertainty shown)
3. eBay-data-backed for initial pricing utility

Long term differentiation depends on:
1. Quality of estimates
2. Speed and reliability
3. Correction-driven data improvement
4. Product execution in a specific user niche

---

## 6) Build Strategy (No Timeline Commitments)

Build sequence:
1. Ship scan + pricing loop with reliable UX
2. Validate usefulness and confidence calibration
3. Add eBay listing publish if quality gates pass
4. Evaluate broader platform expansion after proven paid demand

Implementation profile:
1. Mobile app: camera-first scan and result UX
2. Backend: OCR-parsed queries, comp retrieval, pricing engine, caching
3. Data: eBay Browse + sold provider integration
4. Evaluation: segmented quality and latency reporting

---

## 7) Unit Economics (Fully Loaded View)

## Infrastructure-Level Cost (High Margin Component)

The underlying scan/listing operations are cheap at scale.

## Fully Loaded Cost Categories

A realistic model must include:
1. Infrastructure and model/API costs
2. App store fees
3. Affiliate payouts
4. Support and operations
5. Data-provider spend

Example fully-loaded framing per paying user (illustrative):
1. Revenue (ARPU)
2. Minus app store fee
3. Minus affiliate share (where applicable)
4. Minus infra + data + support
5. Remaining contribution margin

Key point:
- Fully-loaded margins are lower than infra-only margins, but still strong for this category if retention and conversion are healthy.

---

## 8) Risk Assessment

| Risk | Impact | MVP Position | Mitigation |
|------|--------|--------------|------------|
| Overpromising scanner capability | High | Avoided with tag-forward messaging | Confidence UX + explicit low-confidence states |
| Weak sold-data coverage in long tail | High | Managed | Comp-depth-aware confidence + wider ranges |
| Automation/TOS risk on non-API platforms | High | Deferred from MVP | eBay-first listing strategy |
| Incorrect confidence calibration | High | Core quality target | Evaluation harness + calibration iterations |
| Inconsistent product claims across docs | Medium | Addressed | Canonical authority docs + consistency checks |

---

## 9) MVP Go-To-Market Position

Core message:
"Scan the tag and item to get a fast resale estimate with confidence."

Early distribution channels:
1. Reseller communities
2. Thrifting creators
3. Build-in-public content showing honest scan behavior

Canonical packaging for MVP:
1. Free tier: 5 scans per day
2. Paid tier: advanced workflow and selling utility

Do not market MVP as:
1. "Scan anything"
2. "List everywhere in one tap"

Those are future-state statements, not MVP claims.

---

## 10) Decision Gates for Expansion

Only expand beyond MVP when:
1. Scan quality is consistently useful to target users
2. Confidence system is calibrated and trustworthy
3. Core flow reliability is stable
4. User retention supports paid feature expansion

Then add:
1. eBay publish workflow
2. Additional marketplaces as separate risk-managed packages

---

## Bottom Line

This is worth pursuing if executed as a narrow, high-integrity MVP.

The strongest strategy is:
1. Build trust and utility first
2. Keep platform risk low in MVP
3. Expand scope only after quality and demand are proven

That approach preserves upside while controlling avoidable early failure modes.
