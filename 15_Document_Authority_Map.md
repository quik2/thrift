# Document Authority Map
### What each file is for, and which files control build decisions

---

## Build Authority (Use These First)

1. `12_MVP_Canonical_Plan.md` — product contract and scope
2. `13_MVP_Build_Checklist.md` — execution work packages and done criteria
3. `14_MVP_Risk_and_Decisions.md` — risk posture and explicit decisions
4. `11_MVP_UI_UX_Plan.md` — screen-level implementation spec
5. `07_Testing_Plan.md` — validation and launch gate criteria

---

## Strategy and Context (Informs, Does Not Override)

1. `00_README.md` — project index and summary
2. `01_Market_Research.md` — market data context
3. `02_Business_Pitch.md` — business rationale aligned to MVP
4. `03_Competitive_Analysis.md` — competitor benchmarking
5. `04_Technical_Deep_Dive.md` — technical reference and post-MVP architecture
6. `05_Platform_Feasibility.md` — platform policy and API feasibility
7. `06_AI_Scanning_Reality.md` — capability constraints and claim boundaries
8. `08_Honest_Assessment.md` — candid strategic assessment
9. `09_UI_UX_and_Growth.md` — UX/growth strategy aligned to MVP
10. `10_Current_Thrifter_Workflow.md` — user workflow context

---

## Consistency Rules

1. If any doc conflicts with `12_MVP_Canonical_Plan.md`, canonical plan wins.
2. MVP claims must remain tag-forward and confidence-scored.
3. MVP scope remains eBay-first for data and selling workflow.
4. Poshmark/Mercari/Depop listing automation is post-MVP.
5. Free-tier policy remains fixed at 5 scans/day unless updated in decision log.

---

## Change Management

When making changes to product scope:
1. update `12_MVP_Canonical_Plan.md`
2. update `14_MVP_Risk_and_Decisions.md`
3. update affected implementation docs (`11`, `13`, `07`)
4. then update strategy context docs (`02`, `09`, `00`)

This prevents contradictory docs from reappearing.
