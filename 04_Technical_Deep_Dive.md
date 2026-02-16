# ThriftFlip: Technical Deep Dive
### How to build a scanner that's 1,000x faster than ThriftAI

---

## Document Role

This document contains both:
1. MVP-relevant scanner/pricing architecture, and
2. Post-MVP expansion architecture.

Authoritative MVP scope is defined in:
1. `12_MVP_Canonical_Plan.md`
2. `13_MVP_Build_Checklist.md`
3. `14_MVP_Risk_and_Decisions.md`

---

## MVP Implementation Profile (Current Build Target)

Use this subset for MVP implementation:
1. On-device OCR + scan capture flow
2. eBay current listing retrieval (Browse API)
3. Sold-data provider integration (Apify-first)
4. Pricing engine with confidence scoring
5. Save/correction data loop

Deferred from MVP:
1. Poshmark/Mercari automation
2. Depop integration
3. Multi-platform one-tap listing

Treat cross-listing automation sections below as post-MVP architecture.

---

## The Core Insight

Every existing thrift scanning app does the same thing wrong: they upload a full image to a server, run an expensive AI model from scratch, wait for marketplace API calls, and return results 2-3 minutes later.

**The correct architecture is fundamentally different.** You run fast, cheap models on the phone itself, send a tiny data packet (3KB instead of 3MB) to your server, do a vector similarity search against a pre-built database of millions of products, and return results in under a second.

This is exactly how Google Lens works. It's why Lens returns results in 1-2 seconds while ThriftAI takes 2-3 minutes. The technology to do this on a startup budget became available in the last 6 months.

---

## Table of Contents

1. [Why Existing Scanners Are Bad](#1-why-existing-scanners-are-bad)
2. [The Architecture That Beats Them](#2-the-architecture-that-beats-them)
3. [Component 1: On-Device Intelligence](#3-component-1-on-device-intelligence)
4. [Component 2: The Product Database](#4-component-2-the-product-database)
5. [Component 3: The AI Identification Layer](#5-component-3-the-ai-identification-layer)
6. [Component 4: Price Estimation](#6-component-4-price-estimation)
7. [Component 5: Cross-Listing Automation (Post-MVP)](#7-component-5-cross-listing-automation)
8. [The Full Technical Stack](#8-the-full-technical-stack)
9. [What the Research Actually Proves](#9-what-the-research-actually-proves)
10. [Honest Limitations](#10-honest-limitations)
11. [Cost Analysis](#11-cost-analysis)

---

## 1. Why Existing Scanners Are Bad

### ThriftAI's Architecture (Inferred)

ThriftAI takes 2-3 minutes per scan. Their developers admitted to "temporary server overload from high demand." Based on user reports and the pattern, here's what's happening:

```
User takes photo (full resolution, 2-5MB)
    |
    v
Upload entire image to cloud server        [500ms - 2s on cellular]
    |
    v
Run a large vision model (GPT-4V or similar) [5 - 30s, depends on server queue]
    |
    v
Parse AI output, then SYNCHRONOUSLY call     [1 - 5s per API, multiple APIs]
eBay, Poshmark, etc. for price comps
    |
    v
Format and return results                    [200ms]
    |
TOTAL: 10 seconds best case, 2-3 minutes typical
```

**Every step is wrong:**

1. **Sending the full image** wastes bandwidth and time. You only need a 3KB feature vector.
2. **Running a fresh LLM inference per scan** is slow and expensive. A vector lookup takes 5ms.
3. **Synchronous API calls** to marketplaces mean you wait for the slowest one.
4. **No caching** means the same Nike Air Max query hits eBay's API thousands of times a day.
5. **No on-device processing** means you can't even show preliminary results while waiting.

### User Reviews Confirm This

- "Scans took 2-3 minutes. Not useful for a hardcore thrifter."
- "No way this could be useful in a real-world setting scanning items for resale."
- "Google search and ChatGPT give faster, more accurate results without all the frustration."
- "Values appear formulaic -- gives similar items the same oddly specific values."

---

## 2. The Architecture That Beats Them

```
USER TAPS "SCAN"
    |
    v
=== ON-DEVICE (parallel, ~20ms total) ===

  [MobileCLIP-S0]           [YOLOv8n]              [ML Kit OCR]
  Generate 512-dim          Detect garment,         Read tag/label text:
  image embedding           identify type           brand, size, RN#
  3ms via Core ML           15ms via Core ML        10-50ms on-device
    |                         |                        |
    v                         v                        v

=== SEND TO SERVER (~50-100ms) ===

  Payload: 512 floats + garment type + OCR text = ~3KB
  (NOT a 3MB image)

    |
    v
=== SERVER-SIDE (parallel, ~50ms) ===

  [FAISS Index]             [Text Search]           [Redis Cache]
  Match embedding vs        Brand + style           Pre-computed
  5-10M product             lookup from OCR         sold comps
  embeddings                text                    for top match
  <5ms                      10-20ms                 <5ms

    |
    v
=== RETURN TO PHONE (~50-100ms) ===

  Product: "Patagonia Better Sweater 1/4 Zip"
  Avg sold price: $87 (47 sales in last 90 days)
  Price range: $62 - $115
  Confidence: 94%

TOTAL: 200-500ms
```

### Why This Is 1,000x Faster

| Step | ThriftAI | This Architecture |
|------|----------|-------------------|
| Image upload | 500ms - 2s (2-5MB) | 50-100ms (3KB vector) |
| Item identification | 5-30s (LLM inference) | <5ms (vector similarity) |
| Price lookup | 1-5s (live API calls) | <5ms (pre-cached) |
| **Total** | **10s - 3min** | **200-500ms** |

---

## 3. Component 1: On-Device Intelligence

Three models run simultaneously on the phone when the user taps "scan":

### A. MobileCLIP-S0 (Image Embedding)

**What it does:** Converts the photo into a 512-dimensional vector that captures the visual essence of the item. This vector is what gets sent to the server for matching.

**Speed:** ~3ms on iPhone via Core ML. 4.8x faster and 2.8x smaller than OpenAI's ViT-B/16, with equivalent accuracy.

**Who made it:** Apple. Open source at github.com/apple/ml-mobileclip.

**Why it matters:** This is what makes the "send 3KB instead of 3MB" trick work. Instead of uploading a photo, you upload a compact mathematical representation of the photo. The server can match this against millions of pre-computed vectors in milliseconds.

### B. YOLOv8n (Garment Detection)

**What it does:** Detects and localizes the garment in the photo. Identifies the garment type (shirt, jacket, shoes, etc.) and draws a bounding box. This helps focus the embedding on the actual item, not the background.

**Speed:** ~10-30ms on mobile via Core ML.

**Accuracy:** Fashion-specific YOLOv8 models already exist on HuggingFace (e.g., `kesimeg/yolov8n-clothing-detection`). Garment type classification is a solved problem at 99%+ accuracy.

### C. Google ML Kit OCR (Tag Reading)

**What it does:** Reads text from the brand tag, care label, size label, and any other text visible in the photo. This is often the most reliable way to identify the brand.

**Speed:** 6x faster than Apple Vision for continuous camera feed. Results in milliseconds. Entirely on-device, no server needed.

**What it reads:**
- Brand name from the tag
- Size from the size label
- Material composition from the care label (e.g., "60% Cotton, 40% Polyester")
- Country of manufacture
- RN/CA numbers (FTC registration numbers that identify the manufacturer -- these are a goldmine for brand identification even when the brand name is worn off)

### Combined On-Device Output

Before anything hits the server, the phone already knows:
- A 512-dim visual embedding of the item
- The garment type (shirt, jacket, shoes, etc.)
- Any text from the tag (brand, size, material, RN number)

This takes **~20ms total.** The user doesn't even see a loading spinner.

---

## 4. Component 2: The Product Database

This is the competitive moat. You build a database of millions of products with known resale values, and you match user scans against it.

### What Goes In The Database

For each product:
- A 512-dim embedding (pre-computed using Marqo-FashionSigLIP)
- Brand name
- Product name / style name
- Category and subcategory
- Average sold price (last 90 days)
- Price range (low / median / high)
- Number of recent sales
- Original retail price (if known)

### How To Build It

**Source 1: eBay Sold Listings**
- 90 days of sold clothing data
- eBay Marketplace Insights API (if you get access) or Apify scraper (~$49/month)
- Refresh nightly via batch job
- Estimated volume: 2-5 million unique items

**Source 2: Active Listings Across Platforms**
- eBay Browse API (free, active listings)
- Poshmark/Mercari via Stagehand scraping
- Gives current market prices and availability

**Source 3: User Corrections (Over Time)**
- When users scan an item and correct the identification, that data feeds back into the database
- This is a flywheel: more users = more corrections = better accuracy = more users

### Embedding Generation

Use **Marqo-FashionSigLIP** to generate embeddings for each product image. This is a fashion-specific version of SigLIP that outperforms standard CLIP models by 57% on fashion retrieval tasks.

Processing speed: ~100,000 images per hour on a single GPU. A 5 million item database can be fully indexed in ~50 hours.

### Vector Index

**FAISS (Facebook AI Similarity Search):**
- In-memory, handles billions of vectors
- HNSW index: <5ms query time for 10M+ vectors
- GPU-accelerated options reduce latency by 8x
- Open source, free, battle-tested at Meta scale

**Alternative: Qdrant**
- Managed service option
- 7ms p99 latency in production
- Easier to operate than self-hosted FAISS

### The Key Insight

**ThriftAI treats every scan as a brand-new AI reasoning problem. The correct approach treats it as a similarity search against a pre-computed database.**

When a user scans a Patagonia fleece, you don't need an AI to figure out what Patagonia fleeces are worth. You need to match their photo against the 47 Patagonia fleeces that sold on eBay in the last 90 days and show the price range. That's a database lookup, not an AI inference.

---

## 5. Component 3: The AI Identification Layer

The vector similarity search handles ~80% of items. For the remaining 20% (unusual items, low-confidence matches, items not in the database), you escalate to Claude or GPT-4.

### Multi-Image, Multi-Signal Approach

Claude and GPT-4 both accept **multiple images in a single API call** (up to 100 for Claude). This is a major advantage over apps that analyze a single photo:

```python
response = client.messages.create(
    model="claude-haiku-4-5-20251001",
    max_tokens=1024,
    system=[{
        "type": "text",
        "text": """You are an expert thrift store appraiser. Analyze
        the provided images to identify the item.

        <analysis_steps>
        1. Read all visible text, logos, brand markings from all images
        2. Identify garment type and specific style
        3. Determine brand from visible clues (logo, tag, label font,
           construction, hardware quality, stitching patterns)
        4. Note the RN/CA number if visible (identifies manufacturer)
        5. Assess material from care label and visual texture
        6. Evaluate condition (NWT, excellent, good, fair, poor)
        7. Estimate era/decade of manufacture
        </analysis_steps>""",
        "cache_control": {"type": "ephemeral"}
    }],
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Front of garment:"},
            {"type": "image", "source": {"type": "base64",
             "media_type": "image/jpeg", "data": front_b64}},
            {"type": "text", "text": "Brand tag:"},
            {"type": "image", "source": {"type": "base64",
             "media_type": "image/jpeg", "data": tag_b64}},
            {"type": "text", "text": "Care label:"},
            {"type": "image", "source": {"type": "base64",
             "media_type": "image/jpeg", "data": care_b64}},
            {"type": "text", "text": "Identify this item and estimate
             its resale value."},
        ],
    }],
)
```

### Structured Output (Guaranteed JSON)

Claude's structured output feature (GA across all 4.5+ models) guarantees valid JSON responses:

```python
from pydantic import BaseModel
from typing import List, Optional

class ThriftItem(BaseModel):
    brand: str
    garment_type: str
    style_name: Optional[str]
    color: str
    size: Optional[str]
    material: Optional[str]
    condition: str
    era_estimate: Optional[str]
    notable_features: List[str]
    estimated_resale_low: float
    estimated_resale_high: float
    confidence_score: float

response = client.messages.parse(
    model="claude-haiku-4-5-20251001",
    max_tokens=1024,
    messages=[...],
    output_format=ThriftItem,
)

item = response.parsed_output  # Guaranteed valid, fully typed
```

No `JSON.parse()` errors. No retry loops. No validation code. The model literally cannot produce invalid output.

### When To Use the AI Layer vs. Vector Search

| Scenario | Method | Cost | Speed |
|----------|--------|------|-------|
| Item matches database with >85% confidence | Vector search only | ~$0.001 | <500ms |
| Item matches with 60-85% confidence | Vector search + Claude confirmation | ~$0.01-0.02 | 1-3s |
| Item not in database / low confidence | Full Claude Vision analysis | ~$0.02-0.05 | 3-8s |
| Item with barcode | UPC lookup (exact match) | ~$0.001 | <500ms |

**This is FrugalGPT-style routing:** use the cheapest, fastest method for easy items, escalate to expensive methods only when needed. Average cost stays low because 80% of items take the fast path.

### Prompt Caching (10x Cost Reduction)

The system prompt (with brand knowledge, analysis instructions, few-shot examples) can be **cached** across requests:

- First request: pay 1.25x for cache write
- All subsequent requests (within 5 min): pay **0.1x** for cache read
- A 10,000-token system prompt drops from $0.03 to $0.003 per scan

At thousands of scans per day, this is the difference between $100/day and $10/day in AI costs.

---

## 6. Component 4: Price Estimation

### Data Sources (In Priority Order)

**1. Pre-Cached Sold Comps (Fastest)**
- Nightly batch job pulls 90 days of eBay sold data
- Store in Redis: brand + style + size → {avg_price, median_price, low, high, sale_count}
- Lookup time: <5ms
- Covers ~80% of common items

**2. eBay Browse API (Free, Active Listings)**
- Shows current asking prices for similar items
- Less reliable than sold data but immediately available
- Free, no restrictions

**3. SerpApi Google Lens (Visual Match + Price)**
- Submit photo, get back product matches with prices
- Taps into Google's 50B product Shopping Graph indirectly
- Cost: $150/month for 15,000 searches ($0.01/search)

**4. eBay Marketplace Insights API (Best Data, Restricted)**
- Full 90-day sold history with actual transaction prices
- Requires business-level eBay developer approval
- Apply for access once you have a real product with users

**5. Barcode/UPC Lookup (Exact Match When Available)**
- UPCitemdb: 681M+ products, $99/month for 600K lookups
- When a barcode exists, this gives you the EXACT product — no guessing
- Coverage for clothing: ~30-50% of thrift store items still have barcodes

### Pricing Algorithm

```
IF barcode detected AND UPC match found:
    exact_product = True
    pull sold comps for exact product
    confidence = 95%+

ELIF vector match confidence > 85%:
    likely_product = database match
    pull pre-cached sold comps
    confidence = 80-90%

ELIF OCR brand text detected:
    brand = OCR result
    category = on-device garment type
    pull average comps for brand + category
    confidence = 60-75%

ELSE:
    escalate to Claude Vision for full analysis
    use Claude's estimate + any similar items from database
    confidence = 40-60%
```

---

## 7. Component 5: Cross-Listing Automation

**Status:** Post-MVP expansion package (not in canonical MVP scope)

### The Hybrid Approach

| Marketplace | Method | Why |
|-------------|--------|-----|
| **eBay** | REST API (Inventory API) | Official API exists. 100% reliable. Sub-second. Free. |
| **Poshmark** | Stagehand v3 + Browserbase | No API. Stagehand's self-healing handles UI changes. |
| **Mercari** | Stagehand v3 + Browserbase | No API. Same approach as Poshmark. |
| **Depop** | Selling API (partner access) | Official API available for partners. |

### How Stagehand v3 Works (The Browser Automation)

Stagehand talks directly to the browser via Chrome DevTools Protocol. Three core operations:

**`act(instruction)`** — execute a single action:
```typescript
await stagehand.act("click the 'Sell an Item' button");
await stagehand.act("fill the title field with 'Nike Air Max 90 Women Size 8'");
await stagehand.act("select 'Women' from the department dropdown");
await stagehand.act("select 'Shoes > Athletic' from the category menu");
```

**`extract(instruction, schema)`** — pull structured data from a page:
```typescript
const data = await page.extract({
    instruction: "extract all sold listing prices",
    schema: z.object({
        prices: z.array(z.object({
            title: z.string(),
            sold_price: z.string(),
            date: z.string()
        }))
    })
});
```

**`observe(instruction)`** — preview what actions are available without executing them.

### What "Self-Healing" Actually Means

1. **First run:** Stagehand's LLM analyzes the page DOM to find target elements. It caches the discovered selectors.
2. **Subsequent runs:** Replays from cache. Zero LLM cost, zero latency.
3. **When the site changes:** Cached selector breaks. Stagehand detects the failure, re-parses the current page using the accessibility tree, uses the LLM to find the element by semantic intent ("the submit button"), and caches the new path.

It understands "click the submit button" as a semantic concept, not a rigid CSS selector. When Poshmark renames `#btn-submit-3fa2` to `#publish-listing-btn`, Stagehand finds it anyway because it's looking for "the button that submits the listing."

### File Upload (Critical for Photos)

```typescript
const page = stagehand.page;
await page.setInputFiles('input[type="file"]', [
    './photo1.jpg',
    './photo2.jpg',
    './photo3.jpg'
]);
```

### Poshmark Listing — Full Field List

| Field | Type | Required | Automated |
|-------|------|----------|-----------|
| Photos | File upload | Yes (up to 16) | Yes — setInputFiles |
| Title | Text | Yes (80 char max) | Yes — AI-generated |
| Description | Textarea | Yes | Yes — AI-generated |
| Department | Dropdown | Yes | Yes — from scan data |
| Category | Nested dropdown | Yes | Yes — from scan data |
| Brand | Search/autocomplete | Yes | Yes — from OCR/scan |
| Size | Selection buttons | Yes | Yes — from OCR/scan |
| Color | Multi-select (up to 4) | Yes | Yes — from scan data |
| Condition | Radio buttons | Yes | Yes — from AI assessment |
| Original Price | Number | No | Yes — from database |
| Listing Price | Number | Yes | Yes — from price algorithm |

**Estimated Stagehand steps: ~15-20 `act()` calls + 1 file upload.** After caching, this runs in 30-60 seconds with near-zero LLM cost.

### Mercari Listing — Full Field List

| Field | Type | Required | Automated |
|-------|------|----------|-----------|
| Photos | File upload | Yes (up to 12) | Yes |
| Title | Text | Yes (80 char max) | Yes |
| Description | Textarea | Yes (1000 char max) | Yes |
| Category | Nested dropdown | Yes | Yes |
| Brand | Autocomplete | No | Yes |
| Condition | Dropdown | Yes | Yes |
| Size | Dropdown | Conditional | Yes |
| Tags | Text chips | No (up to 5) | Yes |
| Price | Number | Yes ($1-$2000) | Yes |
| Shipping Weight | Selection | Yes | Yes — estimated from category |
| Shipping Payer | Radio | Yes | Yes — user preference |

**Estimated Stagehand steps: ~12-16 `act()` calls + 1 file upload.**

### eBay Listing — API (No Browser Needed)

```
Step 1: PUT /sell/inventory/v1/inventory_item/{sku}
        → Create the product with images, description, aspects

Step 2: POST /sell/inventory/v1/offer
        → Set price, shipping, return policy

Step 3: POST /sell/inventory/v1/offer/{offerId}/publish
        → Go live
```

Bulk endpoint: `bulkCreateOrReplaceInventoryItem` handles 25 items per call.

### Per-Listing Cost

| Component | eBay | Poshmark/Mercari |
|-----------|------|------------------|
| Browser time (Browserbase) | $0 (API, no browser) | ~$0.003 (30-60 sec) |
| LLM cost (Stagehand) | $0 | ~$0.01 first run, ~$0 cached |
| **Total** | **~$0.001** | **~$0.01-0.05** |

---

## 8. The Full Technical Stack

| Layer | Technology | Cost | Why This One |
|-------|-----------|------|-------------|
| **Mobile App** | React Native 0.84 | Free | Hermes V1 engine, single codebase iOS+Android, TypeScript matches backend |
| **On-Device ML** | MobileCLIP-S0 (Core ML) | Free | 3ms embedding generation, Apple open source |
| **On-Device Detection** | YOLOv8n (Core ML) | Free | 15ms garment detection, fashion models on HuggingFace |
| **On-Device OCR** | Google ML Kit v2 | Free | 6x faster than Apple Vision, entirely on-device |
| **Fashion Embeddings** | Marqo-FashionSigLIP | Free (self-hosted) | +57% better than CLIP on fashion, 512-dim vectors |
| **Vector Database** | FAISS or Qdrant | Free (FAISS) / $25+/mo (Qdrant) | <5ms similarity search across millions of items |
| **AI Identification** | Claude Haiku 4.5 | $1/$5 per MTok | Cheapest vision model, structured output GA |
| **AI Fallback** | Claude Sonnet 4.5 | $3/$15 per MTok | Higher accuracy for ambiguous items |
| **Barcode Lookup** | UPCitemdb | $99/month | 681M+ products, exact match when barcode exists |
| **Active Prices** | eBay Browse API | Free | Current listing prices, no restrictions |
| **Sold Prices** | Apify eBay scraper | $49/month | 90-day sold history |
| **Visual Search** | SerpApi Google Lens | $150/month | Google's 50B product graph, $0.01/search |
| **Cache Layer** | Redis | $0-25/month | <5ms comp lookups for pre-cached prices |
| **Backend** | Node.js / TypeScript | Free | Same language as Stagehand and React Native |
| **eBay Listing** | eBay Inventory API | Free | Official API, 100% reliable |
| **Poshmark/Mercari Listing** | Stagehand v3 | Free (open source) | Self-healing browser automation |
| **Cloud Browsers** | Browserbase | $20-99/month | Native Stagehand integration |
| **Hosting** | Railway or Vercel | $5-20/month | Simple deployment |
| **Database** | Supabase (PostgreSQL) | Free-$25/month | Auth, storage, relational data |

### Monthly Infrastructure Cost Summary

| Stage | Total Monthly | Revenue at this stage |
|-------|--------------|----------------------|
| Development | ~$20 | $0 |
| Beta (500 users) | ~$150 | $0 (free beta) |
| Launch (5K users) | ~$400-600 | ~$5-10K/month |
| Growth (50K users) | ~$2,000-4,000 | ~$50-100K/month |

---

## 9. What The Research Actually Proves

### "On-device clothing recognition works"

- MobileCLIP-S0 matches OpenAI ViT-B/16 zero-shot performance at 4.8x faster (Apple, 2025)
- Fashion-MNIST classification: 99.65% accuracy with CNNs (MDPI Mathematics, 2024)
- DINOv2 achieves 98.53% accuracy on fashion classification datasets (Meta, 2023)
- YOLOv8 clothing detection models exist and are production-ready (HuggingFace)

### "Vector similarity search is fast and accurate for fashion"

- Marqo-FashionSigLIP: +57% MRR improvement over FashionCLIP 2.0 on fashion retrieval (Marqo, 2024)
- FAISS handles billions of vectors with <5ms query time (Meta Engineering, 2017-present)
- FAISS GPU acceleration with NVIDIA cuVS: 8.1x latency reduction (Meta, 2025)
- Fashion similarity search with CLIP embeddings is a documented, working approach (OpenAI Cookbook, Width.ai)

### "Multi-image AI analysis improves accuracy"

- Claude supports up to 100 images per API request (Anthropic documentation)
- Chain-of-thought prompting improves visual reasoning accuracy (CVPR 2025, ACL 2025)
- Structured output guarantees valid JSON responses with vision (Anthropic, GA across 4.5+ models)
- Multi-modal RAG (combine visual embedding + text context) enables "open-world update at inference time" — no retraining needed (VisionRAG, 2025)

### "Browser automation is production-viable for marketplace listing"

- Stagehand v3: 44.11% faster than v2, self-healing via accessibility tree + LLM (Browserbase, 2026)
- Browser Use: 89.1% success rate on WebVoyager benchmark (2026)
- Browserbase: $40M Series B at $300M valuation, 50M sessions in 2025 — this is a real, scaling infrastructure
- Every existing cross-listing company (Vendoo, List Perfectly, Crosslist) already uses browser automation in production

### "The compound AI pipeline approach works"

- "The Shift from Models to Compound AI Systems" — BAIR's seminal blog post defines the paradigm (Berkeley, 2024)
- Google Lens achieves sub-3-second results even on LTE by using edge-first processing + server-side vector search (Google, documented architecture)
- FrugalGPT: route easy queries to cheap models, hard queries to expensive models — reduces costs 95%+ with minimal accuracy loss (Stanford, 2023)

---

## 10. Honest Limitations

### What Still Won't Work

1. **Identifying a brand from a plain, unbranded garment** — A plain black sweater from Prada looks identical to one from Gap. No AI, no vector search, no model can reliably distinguish them without a tag or logo. This is a fundamental limitation of visual information.

2. **Exact fabric composition from a photo** — "60% cotton, 40% polyester" cannot be determined visually. The care label is the only reliable source.

3. **Authentication of luxury items** — Verifying a $2,000 Chanel bag is real vs. counterfeit requires examining hardware, stitching, serial numbers, and material feel. Photo-based authentication is not reliable enough to stake money on.

4. **Size from a photo** — Unless the size label is visible and readable, you can't determine size from the garment's appearance.

### What Works But Isn't Perfect

5. **Brand ID from tag** — OCR is ~90-95% accurate. Worn, faded, or unusual font tags will fail. The user should always be able to correct.

6. **Price estimation** — Based on what similar items sold for. Condition, location, time of year, and listing quality all affect actual sale price. Show a range, not a single number.

7. **Vector similarity matching** — Works great for items in your database. Items not in your database (rare vintage, obscure brands) will return low-confidence or incorrect matches. The AI fallback layer handles these, but it's slower and less reliable.

### How To Handle These Honestly In The App

- Always present results as **suggestions**, not definitive answers
- Show a **confidence score** — "94% match" vs. "43% match — review carefully"
- Let users **correct and confirm** identifications (this data improves the system)
- For low-confidence items, show "We're not sure — here's what we think it might be" with options
- Never claim to authenticate luxury items

---

## 11. Cost Analysis

### Per-Scan Cost Breakdown

**Fast path (80% of scans) — Vector match:**

| Component | Cost |
|-----------|------|
| On-device processing | $0 |
| Network transit (3KB) | $0 |
| FAISS vector search | $0 (self-hosted) or <$0.001 (managed) |
| Redis cache lookup (sold comps) | <$0.001 |
| **Total** | **~$0.001** |

**Medium path (15% of scans) — Vector match + Claude confirmation:**

| Component | Cost |
|-----------|------|
| Fast path costs | $0.001 |
| Claude Haiku 4.5 (1 image, cached prompt) | $0.008-0.012 |
| **Total** | **~$0.01** |

**Slow path (5% of scans) — Full Claude analysis:**

| Component | Cost |
|-----------|------|
| Claude Haiku 4.5 (3-5 images, cached prompt) | $0.02-0.04 |
| SerpApi Google Lens (visual search fallback) | $0.01 |
| **Total** | **~$0.03-0.05** |

### Blended Average Cost Per Scan

```
(0.80 x $0.001) + (0.15 x $0.01) + (0.05 x $0.04)
= $0.0008 + $0.0015 + $0.002
= ~$0.004 per scan (less than half a cent)
```

### Monthly Cost At Scale

| Monthly Scans | Blended Cost | Notes |
|---------------|-------------|-------|
| 10,000 | $40 | Beta / early launch |
| 50,000 | $200 | Growth phase |
| 200,000 | $800 | Scale |
| 1,000,000 | $4,000 | At scale, this is trivial vs. revenue |

### Cross-Listing Cost Per Item

| Marketplace | Cost Per Listing |
|-------------|-----------------|
| eBay (API) | ~$0.001 |
| Poshmark (Stagehand, cached) | ~$0.003-0.01 |
| Mercari (Stagehand, cached) | ~$0.003-0.01 |
| **All 3 platforms** | **~$0.01-0.02** |

### Total Cost Per User Action: "Scan + List on 3 Platforms"

```
Scan: $0.004
List on eBay: $0.001
List on Poshmark: $0.005
List on Mercari: $0.005
Total: ~$0.015 per complete scan-and-list action
```

If a user on a $24.99/month plan does 50 scan-and-list actions per month, your cost per user is $0.75/month. That's **97% gross margin.**

---

## Summary: What Makes This Different From ThriftAI

| Dimension | ThriftAI | ThriftFlip |
|-----------|----------|------------|
| **Architecture** | Monolithic cloud AI | Compound edge-cloud pipeline |
| **Scan speed** | 2-3 minutes | <1 second |
| **What gets sent to server** | 2-5MB image | 3KB vector + text |
| **Item identification** | Fresh LLM inference every time | Pre-computed vector similarity search |
| **Price data** | Live API calls (slow) | Pre-cached + live fallback |
| **On-device intelligence** | None | Garment type + brand OCR + embedding |
| **Works on slow cellular?** | Poorly | Yes (tiny payload) |
| **Cost per scan** | High (full LLM call) | $0.004 average |
| **Cross-listing** | No | Yes (eBay API + Stagehand) |
| **Self-improving** | No | Yes (user corrections feed back) |

The technology advantage is not incremental. It is architectural. ThriftAI is solving the wrong problem (running AI inference) when the right problem is similarity search against a pre-built database. That's a fundamental design difference that cannot be fixed with a faster server.
