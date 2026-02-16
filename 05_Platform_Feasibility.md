# Platform Feasibility
### How Poshmark, Mercari, eBay, and Depop Actually Work — API Access, Automation, TOS Risks

---

## Document Role

This file is platform feasibility research.

Canonical MVP usage from this research:
1. Use eBay APIs for pricing/listing features in MVP.
2. Treat Poshmark/Mercari automation as post-MVP expansion with explicit risk acceptance.
3. Keep Depop integration out of MVP scope.

Implementation authority remains:
1. `12_MVP_Canonical_Plan.md`
2. `13_MVP_Build_Checklist.md`
3. `14_MVP_Risk_and_Decisions.md`

---

## Platform-by-Platform Breakdown

### eBay — The Easiest

**API Status: Full official API exists.**

| API | What It Does | Access Level |
|-----|-------------|-------------|
| **Browse API** | Search active listings, get item details + images | Open to all developers |
| **Inventory API** | Create, update, publish listings programmatically | Open to all developers |
| **Marketplace Insights API** | 90 days of sold/completed listing data | **Restricted** — approved high-end developers only |
| **Taxonomy API** | Get category trees, required item aspects | Open to all developers |
| **Finding API** | Was the main search API | **Deprecated Feb 2025** |

**For listing creation:** Use the Inventory API. Three calls: create inventory item → create offer → publish. Supports bulk (25 items per call). 100% reliable, sub-second response, free. This is the gold standard — no browser automation needed.

**For pricing data:** The Browse API gives active listing prices (free). Sold data requires Marketplace Insights (restricted) or third-party scraping (Apify ~$49/mo, SerpApi ~$150/mo).

**eBay sold data workarounds:**
- Apify eBay Sold Listings Scraper
- SerpApi eBay Search API
- Direct web scraping (URL: `ebay.com/sch/i.html?_nkw=<term>&LH_Sold=1&LH_Complete=1`)
- Pre-cache popular item comps nightly via batch job

### Poshmark — No API, Browser Automation Required

**API Status: No official public API. Zero. None.**

- APITracker confirms no developer docs, API reference, or webhooks exist
- Poshmark TOS (Section 4.b) explicitly prohibits "any technology, software or automated systems to collect any information or data"
- Unofficial reverse-engineered wrappers exist on GitHub (joshdk/posh, michaelbutler/phposh) and RapidAPI — but these are not official

**How every competitor connects:** Chrome browser extensions that simulate human actions. Vendoo, Crosslist, List Perfectly all:
1. Require the extension installed in Chrome
2. Piggyback on the user's existing logged-in browser session
3. Open tabs, fill forms, upload photos, click submit programmatically
4. Require browser to stay open — if you close Chrome, listing stops

**Listing form fields (16 total):** Photos (up to 16), Title (80 char), Description, Department, Category, Subcategory, Brand (search/autocomplete), Size, Color (up to 4), Condition, Original Price, Listing Price, Style Tags, Quantity, Discounted Shipping

**Automation approach:** Stagehand v3 — ~15-20 `act()` calls + 1 `setInputFiles()`. After caching, runs in 30-60 seconds.

**Ban risk:**
- **Share jail:** Real, well-documented. Temporary restriction when sharing too much (~9,500-12,000 shares in 24 hours). Lasts 1-24 hours.
- **Permanent bans for automation:** Cannot independently verify. Bot vendor sites (Vendoo, Closet Assistant PM) claim it has never happened, but they have financial incentive to say so. Poshmark's official policies prohibit automation. Enforcement appears to be rate-limiting rather than bans.
- **Honest assessment:** Low risk based on industry behavior, but not zero risk. Every cross-listing company operates this way.

**2025 Policy Changes (significant):**
- **May 2025:** New policy penalizing delete/relist within 60 days
- **Oct 2025:** Replaced chronological feed with algorithmic "For You" feed (reduced value of sharing bots)
- **Nov 2025:** Removed bulk sharing from mobile app (restored Dec 2025 after backlash)
- **Context:** Founder/CEO stepped down, Naver (parent) taking more corporate control

### Mercari — No API, Browser Automation Required (Stricter Than Poshmark)

**API Status: No public API for US marketplace.**

- A "Mercari Shops API" exists but is Japan-only, B2B, restricted to merchants with Japanese fixed IPs
- Unofficial scrapers exist on GitHub and RapidAPI
- Engineering blog discusses internal APIs but none are public-facing

**How competitors connect:** Same as Poshmark — Chrome extensions with browser automation.

**Listing form fields (13 total):** Photos (up to 12), Title (80 char), Description (1000 char), Category (nested), Brand, Condition, Size, Color, Tags (up to 5), Price ($1-$2000), Shipping Weight, Shipping Payer, Zip Code

**Automation approach:** Stagehand v3 — ~12-16 `act()` calls + 1 `setInputFiles()`.

**Enforcement — stricter than Poshmark:**
- Mercari Prohibited Conduct page explicitly bans "any robot, spambot, spider, crawler, scraper or other automated means"
- Active rate-limiting: Vendoo's own help docs acknowledge users get "temporarily blocked" from listing when hitting Mercari's limits
- Vendoo advises listing "in a way that is human like"
- Mercari uses algorithmic/behavioral detection — no fixed thresholds
- Login lockouts from multiple locations in short time

**Honest assessment:** Higher enforcement risk than Poshmark. But cross-listing companies still operate. The enforcement is behavioral (rate limiting) not tool-specific (detecting Vendoo extension).

### Depop — Partner API Available

**API Status: Selling API available for partners.**

More accessible than Poshmark/Mercari. Partnership route is the recommended approach.

---

## Technical Approach Summary

| Platform | Listing Method | Pricing Data Method | Difficulty |
|----------|---------------|-------------------|------------|
| **eBay** | Inventory API (official) | Browse API (active) + scraping (sold) | Easy |
| **Poshmark** | Stagehand v3 browser automation | Stagehand extraction | Hard |
| **Mercari** | Stagehand v3 browser automation | Stagehand extraction | Hard |
| **Depop** | Partner Selling API | API | Medium |

---

## Key Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Poshmark UI change breaks automation | High (regular) | Medium (temporary) | Stagehand self-healing |
| Mercari rate-limits heavy listing | High | Low (temporary block) | Human-like pacing, delays |
| Platform permanently bans for automation | Very Low | High | No precedent exists; offer "manual assist" mode |
| eBay sold data API access denied | High (for new developers) | Medium | Use scraping services ($49-150/mo) |
| Platform launches official API | Low-Medium | Positive (easier integration) | Be first to adopt |

---

*Sources: eBay Developer Documentation, Poshmark TOS, Mercari Prohibited Conduct, Vendoo Help Docs, Crosslist Docs, APITracker, App Store reviews, Value Added Resource, CLOSO blog*
