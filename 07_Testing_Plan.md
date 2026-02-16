# Testing Plan (Canonical MVP)
### How to validate scanner quality and pricing trust before expansion

---

## Document Role

This file defines validation requirements for the canonical MVP.

Scope under test:
1. Scan tag + item
2. eBay-backed comps and price range
3. Confidence behavior
4. Save/correction loop

Out of scope for this file:
1. Poshmark/Mercari automation reliability
2. Depop integration

---

## 1) Validation Objectives

1. Prove results are useful for real sourcing decisions.
2. Prevent overconfident wrong outputs.
3. Quantify where the system fails and why.
4. Create a repeatable report for ship/no-ship decisions.

---

## 2) Dataset Strategy

## Primary dataset

Use eBay listings as a labeled benchmark source.

Target coverage:
1. women's tops/sweaters
2. men's shirts
3. dresses
4. jeans/pants
5. shoes
6. jackets/coats
7. activewear
8. accessories
9. deliberate edge cases (unbranded, vintage, damaged, obscure)

Capture fields:
1. images
2. title
3. item specifics
4. category path
5. sold/current price context
6. traceable item id

## Split policy

1. tuning set
2. validation set
3. final holdout test set

Do not use final holdout data for tuning decisions.

---

## 3) Data Sources Under Test

1. eBay Browse API (current listings)
2. Sold-data provider (Apify-first)
3. Internal cache layer

Validation checks:
1. schema consistency across providers
2. duplicate and stale comp handling
3. failure behavior when sold coverage is sparse

---

## 4) Component-Level Tests

## A) OCR / tag extraction

Measure:
1. brand extraction accuracy
2. size extraction accuracy
3. material extraction accuracy
4. RN/CA extraction accuracy
5. extraction failure modes (lighting, angle, stylized fonts)

## B) Comp retrieval and query quality

Measure:
1. whether returned comps match intended brand/category
2. comp depth per query
3. retrieval failures and fallback behavior

## C) Pricing engine

Measure:
1. error bands vs observed sold outcomes
2. overestimation frequency
3. interval quality (does range capture actual outcomes)
4. behavior under low comp counts

## D) Confidence model

Measure:
1. calibration quality (confidence vs actual correctness)
2. false high-confidence rate
3. low-confidence trigger reliability

---

## 5) End-to-End Product Tests

Run full flow from raw user-style photos:
1. capture
2. OCR
3. comp retrieval
4. pricing and confidence
5. result presentation
6. save/correction

Segment all results by:
1. tag visible vs not visible
2. category
3. image quality
4. branded vs unbranded visual distinctiveness

---

## 6) Real-World Validation

## A) Controlled field test

Use real thrift-store captures, not only clean listing images.

Measure:
1. usefulness rating
2. perceived trust
3. correction rate
4. latency under realistic network conditions

## B) Beta-user validation

Recruit target users and collect:
1. scan outcomes
2. correction actions
3. usefulness feedback
4. repeated-use behavior

---

## 7) Launch Gates

MVP should ship only when all gates pass:

1. usefulness gate:
   - users consistently report results are helpful for buy/pass decisions
2. confidence gate:
   - high-confidence results are meaningfully more correct than low-confidence results
3. safety gate:
   - low-confidence state reliably suppresses hard claims
4. latency gate:
   - scan-to-result feels fast enough for in-store use
5. stability gate:
   - crash/error frequency is acceptable in beta usage

---

## 8) Failure Taxonomy

Every failure should be labeled into one bucket:
1. OCR miss
2. no visible tag
3. poor comp retrieval
4. comp mismatch / wrong neighborhood
5. pricing outlier distortion
6. confidence miscalibration
7. UI trust failure (copy/behavior mismatch)

For each bucket, track:
1. frequency
2. severity
3. remediation owner
4. verification result after fix

---

## 9) Reporting Format

Every test cycle should publish:
1. aggregate quality metrics
2. segmented breakdowns
3. top failure buckets
4. regression checks vs previous cycle
5. go/no-go recommendation

---

## 10) Optional Next-Test Package: eBay Listing Publish

Activate only after scanner/pricing gates pass.

Test items:
1. draft creation accuracy
2. field mapping correctness
3. publish success/failure handling
4. listing status reconciliation back to source scan

---

## Summary

This testing plan is designed to prove one thing before scope expansion:

`Can users trust the MVP scan + price loop enough to use it repeatedly in real sourcing contexts?`

If yes, expand. If no, iterate until trust and usefulness are reliable.
