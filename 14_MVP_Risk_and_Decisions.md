# ThriftFlip MVP Risk and Decisions

---

## How to Use This Doc

1. Track key product and platform risks in one place.
2. Record a clear decision for each risk.
3. Update status as assumptions are validated or invalidated.

---

## Risk Register

| ID | Risk | Severity | Current Position | Mitigation | Status |
|---|---|---|---|---|---|
| R1 | Overpromising "scan anything" vs tag-dependent reality | High | MVP messaging must be tag-forward | Confidence UX + explicit low-confidence flow + honest copy | Active |
| R2 | Weak sold-data coverage for long-tail items | High | Start with eBay + sold provider, not full-market coverage | Cache, widen ranges, reduce confidence when comp depth is low | Active |
| R3 | Pricing confidence is not calibrated to real correctness | High | Confidence must map to observed correctness bands | Evaluation harness + calibration iterations + conservative defaults | Active |
| R4 | Premium value depends on policy-fragile automation (Posh/Mercari) | High | Keep out of MVP | Defer to later; keep eBay-first paid path | Deferred |
| R5 | Privacy/trust copy conflicts with actual storage behavior | Medium | Copy must match implementation exactly | Update onboarding and legal copy before release | Active |
| R6 | Support load spikes from wrong estimates | Medium | Expect correction and confusion on edge cases | In-app correction flow + transparent confidence + issue categorization | Active |
| R7 | Unit economics look better on paper than in production | Medium | Use fully loaded cost model | Include app-store fees, affiliate costs, support, vendor costs | Active |

---

## Decision Log

| ID | Decision | Why | Tradeoff | Status |
|---|---|---|---|---|
| D1 | MVP promise is tag-forward, not "scan anything" | Align capability with user expectation | Less flashy marketing, higher trust | Approved |
| D2 | MVP data stack is eBay current + sold provider | Fastest path to real value | Narrower marketplace coverage in v1 | Approved |
| D3 | Poshmark/Mercari automation is deferred | High policy and maintenance risk | Lower feature breadth at launch | Approved |
| D4 | Confidence is first-class UX, not hidden metadata | Prevent overconfident wrong outputs | More complex result UI | Approved |
| D5 | Save/correction loop is part of MVP | Needed for quality improvement flywheel | Additional backend and UX work | Approved |
| D6 | eBay listing publish is optional next package | Official API path is lowest risk monetization step | Not "list everywhere" at launch | Approved |
| D7 | MVP free tier is fixed at 5 scans per day | Balances user value with upgrade pressure | Lower free usage than fully open scanner | Approved |

---

## Open Questions (Must Be Resolved in Product Decisions)

1. What confidence threshold triggers "low confidence" UI?
2. What minimum comp count is required before showing a tight range?
3. Which fields are mandatory for correction submissions?
4. What user-visible copy appears when sold coverage is sparse?

---

## Guardrails

1. Do not ship copy that implies certainty when confidence is low.
2. Do not expand scope to additional marketplaces until MVP gates pass.
3. Do not publish aggressive revenue claims without fully loaded unit costs.
4. Do not let growth messaging outrun measured product accuracy.
