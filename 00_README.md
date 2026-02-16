# ThriftFlip — Project Overview

**Last updated:** February 16, 2026

---

## Document Authority

For implementation decisions, use these files as authoritative:
1. `12_MVP_Canonical_Plan.md`
2. `13_MVP_Build_Checklist.md`
3. `14_MVP_Risk_and_Decisions.md`

All other docs are research, strategy context, or future-state direction.

---

## What Is This?

ThriftFlip is a mobile app concept centered on one core loop:
1. **Scan the tag + item** — capture photos and extract identifying signals
2. **Price** — pull comparable sold and current listings (eBay-first in MVP)
3. **Act** — save to collection and optionally publish to eBay (multi-platform is post-MVP)

---

## One-Sentence Pitch

**"Scan the tag and item to see what it's worth — then decide whether to buy, save, or sell."**

---

## Target Audiences

**Primary:** Casual thrifters who want to know "is this worth buying to resell?" — the free scanner hooks them in.

**Secondary:** Serious resellers (1-3M in the US) who need to scan, price, and list faster.

The free scanner is the hook. Paid value in MVP is advanced selling workflow (eBay-first), with broader platform expansion after validation.

---

## Current Status

**Stage: Research & Planning (Pre-Development)**

All research, market analysis, competitive intelligence, and technical architecture have been completed. No code has been written yet.

---

## What's In This Folder

| File | What It Contains |
|------|-----------------|
| `00_README.md` | This file — project overview and status |
| `01_Market_Research.md` | Secondhand market data, growth projections, platform stats, reseller community analysis |
| `02_Business_Pitch.md` | Business case aligned to canonical MVP: market, product strategy, risk posture, fully-loaded economics framing, and expansion gates |
| `03_Competitive_Analysis.md` | Deep dive on every competitor (Vendoo, List Perfectly, Flyp, Crosslist, ThriftAI, etc.) with revenue, funding, pricing, and weaknesses |
| `04_Technical_Deep_Dive.md` | Technical architecture reference with explicit MVP implementation profile and post-MVP expansion sections |
| `05_Platform_Feasibility.md` | How Poshmark, Mercari, eBay, and Depop actually work technically — API availability, browser automation, TOS risks, policy changes |
| `06_AI_Scanning_Reality.md` | Honest assessment of what AI vision can and cannot do for clothing identification, with research citations |
| `07_Testing_Plan.md` | Canonical MVP validation plan: quality objectives, component/e2e checks, failure taxonomy, and launch gates (no schedule assumptions) |
| `08_Honest_Assessment.md` | Candid assessment aligned to canonical MVP, with execution model, risk boundaries, and kill criteria |
| `09_UI_UX_and_Growth.md` | MVP-aligned UI/UX and growth strategy focused on trust, clarity, and realistic product claims |
| `10_Current_Thrifter_Workflow.md` | MVP-focused mapping of current thrifter behavior to the specific scan-and-price loop the product replaces |
| `11_MVP_UI_UX_Plan.md` | Build-facing screen-by-screen UI/UX specification for canonical MVP scope (including confidence-first and eBay-first behavior) |
| `12_MVP_Canonical_Plan.md` | Canonical MVP scope and product contract: in-scope, out-of-scope, system behavior, confidence rules, and launch gates |
| `13_MVP_Build_Checklist.md` | Practical build checklist organized by workstream and workload size (S/M/L), with completion criteria and dependencies |
| `14_MVP_Risk_and_Decisions.md` | Risk register and decision log to keep product claims, architecture, and platform strategy internally consistent |
| `15_Document_Authority_Map.md` | Authority map defining which docs control build decisions versus contextual strategy/research references |

---

## Key Numbers At A Glance

| Metric | Value |
|--------|-------|
| U.S. secondhand market (2025) | $56B |
| U.S. secondhand market (2029) | $74B |
| Annual growth rate | 9-13% |
| Market leader revenue (Vendoo) | $5M/year |
| Market leader total funding | ~$500K |
| Estimated reseller tool market penetration | 3-10% |
| Infrastructure cost to launch | Under $350 |
| Monthly infrastructure at 10K users | ~$400 |
| Gross margin (fully loaded, early-stage target) | Healthy SaaS margin; model in `02_Business_Pitch.md` |
| Per-scan cost (blended average) | $0.004 |
| Scan speed (our architecture) | <1 second |
| ThriftAI scan speed (competitor) | 2-3 minutes |
