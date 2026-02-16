# ThriftFlip MVP Build Checklist

---

## Workload Size Key

- `S` = small, focused task cluster.
- `M` = medium, cross-component implementation.
- `L` = large, multi-system work with validation.

---

## 1) Product Contract and Spec (`S`)

- [ ] Freeze MVP promise text to tag-forward language.
- [ ] Confirm in-scope and out-of-scope boundaries.
- [ ] Define exact result object returned by backend.
- [ ] Define low-confidence copy and behavior.

**Done when:**
- [ ] Canonical spec is approved and referenced by all build docs.

---

## 2) Mobile UX/UI (`M`)

- [ ] Implement camera-first home screen.
- [ ] Implement scan state with clear progress feedback.
- [ ] Implement result sheet with price range, confidence, comps.
- [ ] Implement low-confidence result variant.
- [ ] Implement "My Finds" list and detail view.
- [ ] Implement empty/error/offline states.

**Done when:**
- [ ] A user can scan, view result, and save item without dev tools.

---

## 3) Scan Input Layer (`M`)

- [ ] Integrate camera capture flow.
- [ ] Integrate OCR for tag extraction.
- [ ] Parse and structure OCR output.
- [ ] Add retry prompts for weak/failed tag capture.
- [ ] Capture optional second image for item context.

**Done when:**
- [ ] Scan payload consistently contains structured OCR + image metadata.

---

## 4) Data Connectors (`L`)

- [ ] Integrate eBay Browse API for current listings.
- [ ] Integrate sold listings provider (Apify first).
- [ ] Normalize provider payloads to one internal schema.
- [ ] Add connector-level retries and fallback handling.
- [ ] Add cache for repeated queries.

**Done when:**
- [ ] Backend returns normalized comps for common categories without manual intervention.

---

## 5) Pricing Engine v1 (`M`)

- [ ] Build comp selection/query builder from OCR + category signals.
- [ ] Implement outlier filtering.
- [ ] Compute low/median/high estimates.
- [ ] Compute confidence score with transparent inputs.
- [ ] Return explanation metadata (comp count, variance, signal quality).

**Done when:**
- [ ] Price output is deterministic and explainable for the same input.

---

## 6) Backend Foundation (`M`)

- [ ] Set up auth and user identity.
- [ ] Set up core entities: scan, item, comps snapshot, corrections.
- [ ] Add API endpoints for scan result and save flow.
- [ ] Add structured logging and error codes.
- [ ] Add basic rate limiting and abuse controls.

**Done when:**
- [ ] End-to-end mobile flow is stable under normal usage.

---

## 7) Trust, Copy, and Privacy (`S`)

- [ ] Align onboarding privacy copy with actual storage behavior.
- [ ] Add confidence disclaimer language in result UI.
- [ ] Add "unknown / not sure" behavior for weak signals.
- [ ] Add delete flow for saved scan records/media.

**Done when:**
- [ ] Product copy is accurate and does not conflict with implementation.

---

## 8) Evaluation Harness (`L`)

- [ ] Build evaluation dataset pipeline.
- [ ] Run segmented accuracy checks (tag visible vs not visible).
- [ ] Track pricing error bands.
- [ ] Track hallucination/overconfident failure rate.
- [ ] Track latency distribution in realistic conditions.

**Done when:**
- [ ] You have a repeatable report that determines readiness to ship.

---

## 9) Analytics and Feedback Loop (`S`)

- [ ] Instrument scan lifecycle events.
- [ ] Instrument confidence distribution and correction actions.
- [ ] Capture top failure categories.
- [ ] Add lightweight in-app feedback path.

**Done when:**
- [ ] You can answer why scans fail and what to improve next.

---

## 10) Optional Next-Step Package: eBay Listing Publish (`M`)

- [ ] Add listing draft generation from scan result.
- [ ] Integrate eBay Inventory API publish path.
- [ ] Add publish success/failure states and retry.
- [ ] Record listing linkage back to source scan.

**Done when:**
- [ ] A saved scan can become a live eBay listing with clear status.

---

## Dependency Order (No Dates)

1. Product contract and spec
2. Mobile UX/UI + scan input layer
3. Data connectors + backend foundation
4. Pricing engine
5. Trust copy and privacy alignment
6. Evaluation harness
7. Analytics loop
8. Optional eBay listing publish

---

## Explicitly Deferred

- Poshmark/Mercari automation
- Depop integration
- Widget, gamification, public sharing loops
- Advanced growth mechanics

These remain deferred until MVP quality and reliability gates are met.
