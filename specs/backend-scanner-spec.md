# ThriftFlip Backend Scanner Specification

**Version:** 1.0 | **Date:** February 16, 2026
**Authority:** This spec consolidates research from 4 reports into actionable build decisions. For product scope, `12_MVP_Canonical_Plan.md` takes precedence.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [On-Device Pipeline (iOS)](#2-on-device-pipeline-ios)
3. [Backend Stack](#3-backend-stack)
4. [Data Sources](#4-data-sources)
5. [Pricing Engine](#5-pricing-engine)
6. [Confidence Scoring](#6-confidence-scoring)
7. [Database Schema](#7-database-schema)
8. [Image Storage](#8-image-storage)
9. [Rate Limiting & Quotas](#9-rate-limiting--quotas)
10. [Background Jobs](#10-background-jobs)
11. [User Correction Loop](#11-user-correction-loop)
12. [Cost Projections](#12-cost-projections)
13. [Brand Tier Database](#13-brand-tier-database)
14. [Constants & Configuration](#14-constants--configuration)

---

## 1. System Overview

### End-to-End Flow

```
[iPhone Camera] ──capture──> [On-Device Pipeline ~340ms]
                                 ├── Apple Vision OCR (.accurate) ──> brand, RN, size, material
                                 ├── YOLOv8n ──> garment type (13 classes)
                                 └── MobileCLIP-S1 ──> 512-dim visual embedding
                                          │
                                          ▼
                              [Multimodal Fusion + Confidence]
                                          │
                                          ▼
                              [POST /api/v1/scan] ──network──> [FastAPI on Render]
                                                                    │
                                          ┌─────────────────────────┤
                                          ▼                         ▼
                                   [eBay Browse API]     [eBay Marketplace Insights]
                                   (active listings)     (90-day sold data)
                                          │                         │
                                          └──────────┬──────────────┘
                                                     ▼
                                              [Pricing Engine]
                                              (filter → weight → separate sold/active → compute ranges)
                                                     │
                                                     ▼
                                              [Market Insights]
                                              (sell-through rate, days to sell, demand)
                                                     │
                                                     ▼
                                              [Platform Fee Calculator]
                                              (eBay, Poshmark, Mercari, Depop, Whatnot)
                                                     │
                                                     ▼
                                              [Buy/Pass Signal Engine]
                                              (user settings + margins + sell-through → green/yellow/red)
                                                     │
                                                     ▼
                                              [ScanResult Response]
                                              (pricing + market insights + platform comparison + buy signal)
```

### Latency Budget

| Step | Time | Where |
|------|------|-------|
| Image preprocessing | ~20ms | Device |
| Apple Vision OCR (.accurate) | ~300ms | Device (Neural Engine) |
| Text parsing + brand matching | ~5ms | Device (CPU) |
| YOLOv8n garment detection | ~8ms | Device (Neural Engine) |
| MobileCLIP-S1 embedding | ~6ms | Device (Neural Engine) |
| Confidence scoring + fusion | ~1ms | Device (CPU) |
| **Total on-device** | **~340ms** | |
| Network + API processing | ~200-500ms | Network + Server |
| **Total end-to-end** | **~540-840ms** | |

---

## 2. On-Device Pipeline (iOS)

### 2.1 OCR: Apple Vision Framework

**Engine:** `VNRecognizeTextRequest` with `.accurate` recognition level.

**Critical configuration:**
- **`customWords`**: Preload 500+ clothing brand names so OCR does not "autocorrect" unusual brands (e.g., "BAPE" → "BAKE"). Include: Patagonia, Arc'teryx, Lululemon, The North Face, Supreme, Bape, Carhartt, Stone Island, CP Company, Acne Studios, Maison Margiela, Issey Miyake, Comme des Garcons, Burberry, Barbour, Canada Goose, Moncler, etc.
- **`recognitionLanguages`**: `["en"]` (add `"fr"`, `"es"` for Canadian bilingual labels).
- **`minimumTextHeight`**: `0.02-0.05` to filter background noise.
- Request `topCandidates(3)` for ambiguous text.

**Regex post-processing on OCR output:**
```
RN:       RN\s*\d{4,6}
CA:       CA\s*\d{5}
Fiber:    \d{1,3}%\s*(Cotton|Polyester|Nylon|Wool|Rayon|Spandex|Elastane|Silk|Linen|Acrylic|Viscose|Modal|Cashmere|Merino)
Size:     (Size\s*)?(XXS|XS|S|M|L|XL|XXL|XXXL|\d{1,2})
Country:  Made\s+in\s+(\w+(\s\w+)?)
Style#:   Style\s*#?\s*(\w+)
```

**Preprocessing before OCR:**
1. Crop to tag region (user-guided ROI or YOLO tag detection).
2. 2x bicubic upscale on small crops.
3. Target 300 DPI equivalent.
4. Adaptive thresholding (Otsu's or adaptive Gaussian).
5. Gentle bilateral denoising.
6. Deskew via bounding box angle detection.

### 2.2 Garment Detection: YOLOv8n

**Model:** YOLOv8n nano variant, fine-tuned on DeepFashion2 (13 classes).

| Spec | Value |
|------|-------|
| Parameters | ~3.2M |
| Size (INT8) | ~2 MB |
| Inference | ~8ms on Neural Engine |
| Input | 640x640 px |
| Format | `.mlpackage` (ML Program) |

**13 garment classes:** short_sleeved_shirt, long_sleeved_shirt, short_sleeved_outwear, long_sleeved_outwear, vest, sling, shorts, trousers, skirt, short_sleeved_dress, long_sleeved_dress, vest_dress, sling_dress.

### 2.3 Visual Embedding: MobileCLIP-S1

**Model:** Apple MobileCLIP-S1 (official CoreML from `apple/coreml-mobileclip` on HuggingFace).

| Spec | Value |
|------|-------|
| Total params | 84.9M |
| Image encoder | 21.5M params |
| Total latency | ~5.8ms on iPhone 12 Pro Max |
| ImageNet zero-shot | 72.6% |
| Output | 512-dim float vector |
| Format | `.mlpackage` |
| Size (INT8) | ~85 MB |

**Why S1 over S0:** +4.8% accuracy for only 2.7ms additional latency. The accuracy gap matters for fine-grained clothing distinctions (henley vs crew neck, bomber vs trucker jacket).

### 2.4 RN Number Lookup

**Strategy:** Local cache bundled with app (~5 MB JSON/SQLite).

- Seed with top 500-1000 common RN→brand mappings from reseller community lists.
- Include parent company → subsidiary brand mapping (e.g., VF Corp → North Face, Vans, Timberland).
- No public FTC API exists; web-only at `rn.ftc.gov`.
- Crowdsource corrections over time.

**Reliability:** When RN is present and readable, it provides the highest-authority brand identification (legally registered).

### 2.5 Model Size Budget

| Model | Size (INT8) | Latency |
|-------|------------|---------|
| Apple Vision OCR | Built-in (0 MB) | ~300ms |
| YOLOv8n (13-class) | ~3 MB | ~8ms |
| MobileCLIP-S1 | ~85 MB | ~6ms |
| Brand name database | ~2 MB | <1ms |
| RN lookup cache | ~5 MB | <1ms |
| **Total** | **~95 MB** | **~315ms** |

---

## 3. Backend Stack

### Chosen Services

| Service | Provider | Why |
|---------|----------|-----|
| **Auth** | Supabase Auth | 50K MAU free, native Swift SDK, anonymous→Apple upgrade, RLS integration |
| **Database** | Supabase Postgres + pgvector | Bundled with auth, RLS, 512-dim HNSW vector search |
| **Image Storage** | Supabase Storage | Bundled with Supabase, 1GB free, auth-integrated, CDN via Supabase transforms |
| **API Hosting** | Render | Free tier (750 hrs/mo), auto-deploy from GitHub, cold starts ~30s on free |
| **Cache / Rate Limit** | Upstash Redis | 500K commands free, serverless, slowapi rate limiting |
| **Task Queue** | ARQ | Native asyncio (matches FastAPI), lightweight, uses same Redis |

### Architecture Diagram

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  iOS App     │     │  FastAPI          │     │  Supabase        │
│  (SwiftUI)   │◄───►│  on Render       │◄───►│  Postgres+Auth   │
│              │     │                  │     │  + pgvector      │
│ supabase-    │     │ Uvicorn          │     │  + Storage       │
│ swift SDK    │     │ slowapi          │     │  + RLS           │
│ Apple Sign-In│     │ ARQ workers      │     └──────────────────┘
└──────────────┘     └────────┬─────────┘              │
                              │                        │
                              ▼                        │
                     ┌──────────────────┐              │
                     │ Upstash Redis    │              │
                     │ (rate limits +   │──────────────┘
                     │  job queue)      │
                     │ 500K free/mo     │
                     └──────────────────┘
```

### Auth Flow

1. **Anonymous start:** `supabase.auth.signInAnonymously()` — user gets real UID, can use RLS-protected tables, 5 scans/day.
2. **Upgrade prompt:** After 3+ scans or when saving to collection.
3. **Apple Sign-In:** `supabase.auth.linkIdentity(provider: .apple)` — UID persists, all data transfers.
4. **Backend validation:** FastAPI validates Supabase JWT on every request via middleware.

---

## 4. Data Sources

### Tiered Data Pipeline

Priority order — fall through to next tier if current tier fails or returns insufficient data:

| Tier | Source | Data Quality | Cost | Access |
|------|--------|-------------|------|--------|
| **1** | eBay Marketplace Insights API | Highest (90-day sold) | Free if approved | Restricted — apply for access |
| **2** | Apify eBay sold listings scraper | High (actual sold prices) | ~$25/1K results | Pay-per-use |
| **3** | eBay Browse API | Medium (active listings only) | Free (5K calls/day) | Open to all developers |
| **4** | Brand-based local estimates | Low (static multiplier tables) | Free | Bundled in app |

### eBay Browse API (Always Available)

- **Endpoint:** `GET https://api.ebay.com/buy/browse/v1/item_summary/search`
- **Auth:** OAuth 2.0 client credentials (application token, no user login).
- **Limit:** 5,000 calls/day (expandable to 1.5M after growth check).
- **Limitation:** Active listings only — no sold/completed data.
- **Image search:** `searchByImage` endpoint available.

### eBay Marketplace Insights API (Apply for Access)

- **Endpoint:** `GET https://api.ebay.com/buy/marketplace_insights/v1_beta/item_sales/search`
- **Returns:** Actual sold prices, quantity, bids, 90-day history, up to 10K items/query.
- **Access:** Limited Release, case-by-case eBay approval. Apply with detailed use case.

### Apify Scrapers (Fallback for Sold Data)

- **marielise.dev:** `$25/1K results` — returns avg/median sold prices, days to sell, market demand.
- **caffein.dev:** Normalized sale price, currency, end date, title, URL.
- **dtrungtin:** `$2/1K results` — general purpose, active + completed.

### Legal Note

eBay's June 2025 ToS update prohibits using API data to train AI/ML models. Real-time lookups (query → display) are likely permissible. Caching for extended periods or building training datasets from eBay data may violate the license. Display results with eBay attribution.

### Query Construction (Tiered)

```
Input: brand="Patagonia", type="jacket", subtype="fleece", size="M", color="blue", style="Better Sweater"

Tier 1 (most specific):
  Query: "Patagonia Better Sweater fleece jacket"
  Filters: Size=M, Color=Blue, Condition=Pre-owned
  Expected: <20 results, highly relevant

Tier 2 (if Tier 1 < 3 results):
  Query: "Patagonia fleece jacket"
  Filters: Size=M, Condition=Pre-owned
  Expected: 20-100 results

Tier 3 (broadest fallback):
  Query: "Patagonia jacket"
  Filters: Condition=Pre-owned
  Expected: 100+ results
```

Best practices:
- Lead with brand + most specific product identifier (style name or style number).
- Use aspect filters for size/color (not keywords) to avoid false negatives.
- If style number exists (e.g., "#39174"), include it — most precise identifier.
- Exclude: `-lot -bundle -wholesale -"for parts"`

---

## 5. Pricing Engine

### 5.1 Pipeline

```
[Raw eBay Comps] → [Outlier Filtering] → [Weighting] → [Trimmed Mean + Percentiles] → [Price Range]
```

### 5.2 Outlier Filtering (3-Step)

**Step 1: Keyword exclusion**
Remove listings containing: `lot`, `bundle`, `wholesale`, `parts`, `repair`, `damaged`, `broken`, `stain`, `as-is`, `for parts`, `read description`, `salvage`. Remove multi-quantity listings (qty > 1).

**Step 2: Price floor/ceiling**
- Floor: Remove listings below $2.00.
- Ceiling: Remove listings above 5x the preliminary median.

**Step 3: IQR statistical filter**
```
Q1 = percentile(prices, 25)
Q3 = percentile(prices, 75)
IQR = Q3 - Q1
Lower bound = Q1 - (1.5 * IQR)
Upper bound = Q3 + (1.5 * IQR)
Remove any price outside [lower_bound, upper_bound]
```

If fewer than 3 comps remain after filtering → return "insufficient data."

### 5.3 Comp Weighting

**Recency (exponential decay):**
```
recency_weight = e^(-0.03 * days_old)

Examples:
  Today:      1.000
  7 days:     0.810
  14 days:    0.657
  30 days:    0.407
  60 days:    0.165
  90 days:    0.067
```

**Condition:**
```
exact_condition_match:  1.0
one_grade_off:          0.7
two_grades_off:         0.4
unknown_condition:      0.5
```

**Size:**
```
exact_size_match:  1.0
one_size_off:      0.8
two_sizes_off:     0.5
different_sizing:  0.6
```

**Combined:** `final_weight = recency_weight * condition_weight * size_weight`

### 5.4 Central Estimate (Weighted Trimmed Mean)

```
if comp_count < 5:    use median (most robust with tiny samples)
elif comp_count < 10: use 10% trimmed mean
elif comp_count >= 10: use 15% trimmed mean with recency weighting
```

Trimmed mean: sort by price, remove bottom N% and top N%, compute `SUM(price * weight) / SUM(weight)` on remaining comps.

### 5.5 Price Range (Adaptive Percentiles)

```
if comp_count >= 20:  low = P10, high = P90
elif comp_count >= 10: low = P15, high = P85
elif comp_count >= 5:  low = P20, high = P80
elif comp_count >= 3:  low = min, high = max (add "Based on limited data" caveat)
else: insufficient data — do not display range
```

Use weighted percentiles (cumulative weight method) when recency weights are applied.

### 5.6 Rounding

- Under $100: round to nearest $1.
- $100-$500: round to nearest $5.
- Over $500: round to nearest $10.
- Never show ranges wider than 5x (if high > 5 * low, add caveats).

### 5.7 Sold vs Active Price Separation

**Critical design decision:** Sold and active prices are computed and displayed separately.

Resellers trust sold prices (what people actually paid) far more than active prices (what sellers are asking). The pricing engine computes ranges independently:

```
sold_comps = [c for c in filtered_comps if c.status == "sold"]
active_comps = [c for c in filtered_comps if c.status == "active"]

sold_range = compute_range(sold_comps)     # Sections 5.2-5.5 applied
active_range = compute_range(active_comps) # Sections 5.2-5.5 applied
combined_range = compute_range(filtered_comps)

# sold_range is the primary price shown to users
# active_range is secondary reference
# combined_range is fallback when sold data is sparse
```

**Display priority:**
1. If sold comps >= 3: show sold range prominently, active as secondary
2. If sold comps < 3 but active >= 3: show active range with caveat "Based on active listings only — no recent sales found"
3. If total comps < 3: insufficient data

### 5.8 Market Insights (Sell-Through Rate)

```
sell_through_rate = sold_count / (sold_count + active_count) * 100

# Demand levels
if sell_through_rate >= 65: demand = "high"
elif sell_through_rate >= 35: demand = "moderate"
else: demand = "low"

# Average days to sell (from sold comps with known dates)
days_to_sell = [comp.days_since_listed for comp in sold_comps if comp.days_since_listed]
avg_days_to_sell = mean(days_to_sell) if days_to_sell else None

# Volume trend (compare recent vs older)
last_30_days_sold = len([c for c in sold_comps if c.days_old <= 30])
prev_30_days_sold = len([c for c in sold_comps if 30 < c.days_old <= 60])
if prev_30_days_sold == 0:
    volume_trend = "stable"
elif last_30_days_sold > prev_30_days_sold * 1.2:
    volume_trend = "rising"
elif last_30_days_sold < prev_30_days_sold * 0.8:
    volume_trend = "declining"
else:
    volume_trend = "stable"
```

### 5.9 Multi-Platform Fee Comparison

**No additional data sources needed — this is pure math applied to the same price estimate.**

Platform fee structures (as of February 2026):

| Platform | Fee Structure | Shipping Model | Notes |
|----------|--------------|----------------|-------|
| **eBay** | 13.25% final value fee | Seller pays (~$7.50 clothing) | +$0.30 per order, simplified here |
| **Poshmark** | 20% flat (items >$15), $2.95 (items ≤$15) | Prepaid label included ($7.97) | Shipping is "free" to seller — built into fee |
| **Mercari** | 10% selling fee | Seller pays (~$7.50 clothing) | Simple flat rate |
| **Depop** | 3.3% + $0.45 transaction fee | Seller pays (~$7.50 clothing) | Lowest marketplace fees |
| **Whatnot** | 8% selling fee | Seller pays (~$7.50 clothing) | Live selling focus |

```python
PLATFORM_FEES = {
    "ebay": {
        "fee_percent": 0.1325,
        "fixed_fee": 0.30,
        "shipping_included": False,
    },
    "poshmark": {
        "fee_percent": 0.20,
        "fee_flat_under_15": 2.95,
        "fixed_fee": 0,
        "shipping_included": True,  # buyer pays $7.97 flat
    },
    "mercari": {
        "fee_percent": 0.10,
        "fixed_fee": 0,
        "shipping_included": False,
    },
    "depop": {
        "fee_percent": 0.033,
        "fixed_fee": 0.45,
        "shipping_included": False,
    },
    "whatnot": {
        "fee_percent": 0.08,
        "fixed_fee": 0,
        "shipping_included": False,
    },
}

def compute_platform_estimate(gross_price, platform, shipping_cost, estimated_cost=None):
    config = PLATFORM_FEES[platform]

    if platform == "poshmark" and gross_price <= 15:
        fees = config["fee_flat_under_15"]
    else:
        fees = gross_price * config["fee_percent"] + config.get("fixed_fee", 0)

    shipping = 0 if config["shipping_included"] else shipping_cost
    net_profit = gross_price - fees - shipping
    net_after_cost = (net_profit - estimated_cost) if estimated_cost else None

    return {
        "platform": platform,
        "feePercent": config["fee_percent"] * 100,
        "estimatedShipping": shipping,
        "grossPrice": gross_price,
        "fees": round(fees, 2),
        "netProfit": round(net_profit, 2),
        "netAfterCost": round(net_after_cost, 2) if net_after_cost is not None else None,
    }
```

**Shipping cost by garment type** (user-configurable via settings):

| Garment Type | Default Shipping |
|-------------|-----------------|
| clothing (shirts, pants, dresses) | $7.50 |
| shoes | $12.00 |
| heavy (coats, jackets, suits) | $15.00 |
| accessories (hats, belts, scarves) | $5.00 |

### 5.10 Buy/Pass Signal Algorithm

The traffic light signal combines confidence, sell-through rate, and profit margin into a single actionable recommendation.

```python
def compute_buy_signal(
    confidence_score: int,
    sell_through_rate: int,
    best_net_after_cost: float | None,
    estimated_cost: float | None,
    user_settings: UserSettings,
) -> BuySignal:
    """
    Returns green/yellow/red signal based on:
    1. Confidence in the identification
    2. Sell-through rate (does it actually sell?)
    3. Profit margin vs user's threshold

    estimated_cost comes from user_settings.default_cost_estimate (store type).
    It is always available (set in onboarding quiz), so profit component
    is always computed — no "neutral" fallback needed.
    """

    # Automatic RED conditions
    if confidence_score < 30:
        return BuySignal("red", "Low confidence — identification uncertain")
    if sell_through_rate == 0 and confidence_score < 55:
        return BuySignal("red", "No recent sales found, low confidence")

    # Score components (each 0-100)
    confidence_component = min(confidence_score, 100)

    demand_component = sell_through_rate  # 0-100 directly

    # Profit component (always available — cost comes from settings)
    if estimated_cost and best_net_after_cost is not None:
        min_profit = user_settings.min_profit_dollars or 10
        if best_net_after_cost >= min_profit * 2:
            profit_component = 100
        elif best_net_after_cost >= min_profit:
            profit_component = 70
        elif best_net_after_cost > 0:
            profit_component = 40
        else:
            profit_component = 0  # Loss
    else:
        profit_component = 50  # Fallback (shouldn't happen — cost always set)

    # Weighted composite — profit always matters since cost is always known
    composite = (
        confidence_component * 0.25 +
        demand_component * 0.30 +
        profit_component * 0.45
    )

    # Signal thresholds
    if composite >= 65:
        signal = "green"
    elif composite >= 40:
        signal = "yellow"
    else:
        signal = "red"

    # Generate reason
    reason = generate_signal_reason(signal, sell_through_rate, best_net_after_cost, confidence_score)

    # ROI calculation
    roi = None
    if estimated_cost and estimated_cost > 0 and best_net_after_cost:
        roi = int((best_net_after_cost / estimated_cost) * 100)

    best_platform = find_best_platform(platform_comparison)

    return BuySignal(signal, reason, roi, best_platform)
```

**Signal meanings for users:**

| Signal | Color | Copy | Behavior |
|--------|-------|------|----------|
| Green | `gainGreen` (#5AC53A) | "Good buy" | Large green circle, confident language |
| Yellow | `gold` (#F6C86A) | "Maybe" | Yellow circle, hedged language |
| Red | `warning` (#EB5D2A) | "Pass" | Red circle, cautious language |

### 5.11 Profit Estimation (Updated)

```
Per-platform profit:
  net_profit = gross_price * (1 - fee_percent) - fixed_fee - shipping
  net_after_cost = net_profit - estimated_cost

Best platform = platform with highest net_after_cost
ROI = (net_after_cost / estimated_cost) * 100
```

`estimated_cost` comes from `user_settings.default_cost_estimate` (derived from store type set in onboarding quiz). It is always available — no "if no price" fallback needed. Users can override per-item by setting `purchase_price` on a specific scan.

Shipping estimates are user-configurable (defaults in Section 5.9). Garment type from YOLO detection maps to shipping category automatically.

### 5.12 Seasonal Adjustment (Phase 2)

Not in MVP. When implemented:

```
adjusted_price = raw_comp_price * (current_month_factor / comp_month_factor)
```

Monthly seasonal indices by category (1.0 = annual average):

| Category | Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec |
|----------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Winter Outerwear | 1.30 | 1.15 | 0.85 | 0.70 | 0.65 | 0.60 | 0.60 | 0.70 | 0.90 | 1.20 | 1.35 | 1.40 |
| Sweaters/Knits | 1.20 | 1.10 | 0.90 | 0.75 | 0.70 | 0.65 | 0.65 | 0.75 | 0.95 | 1.15 | 1.25 | 1.30 |
| Swimwear | 0.60 | 0.65 | 0.85 | 1.15 | 1.35 | 1.40 | 1.35 | 1.10 | 0.80 | 0.65 | 0.55 | 0.55 |
| Denim | 1.00 | 0.95 | 0.95 | 0.95 | 0.95 | 0.90 | 0.90 | 1.00 | 1.10 | 1.10 | 1.10 | 1.05 |
| Athleisure | 1.15 | 1.10 | 1.05 | 1.00 | 1.00 | 0.95 | 0.90 | 0.95 | 1.00 | 1.00 | 0.95 | 0.95 |
| Basics | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |

---

## 6. Confidence Scoring

### 6.1 Identification Confidence (On-Device)

Computed from 4 independent signals:

```
identification_confidence = (
    OCR_brand_confidence     * 0.35 +
    RN_lookup_confidence     * 0.25 +
    visual_match_confidence  * 0.25 +
    garment_type_confidence  * 0.15
)
```

**OCR Brand (0.35):** Apple Vision confidence for brand text. Boosted if exact match in `customWords`. Reduced if fuzzy match required. 0.0 if no brand text detected.

**RN Lookup (0.25):** 1.0 if RN maps to known consumer brand. 0.8 if maps to parent company (brand inferred). 0.3 if FTC data outdated. 0.0 if no RN present.

**Visual Match (0.25):** Cosine similarity between MobileCLIP-S1 embedding and candidate product text descriptions. >0.3 = strong, <0.15 = weak.

**Garment Type (0.15):** YOLOv8n detection confidence. Cross-check: if OCR says "Levi's" but YOLO detects "outwear" (not pants), reduce confidence.

**Minimum for high confidence:** At least 2 of 4 signals must independently confirm the identification.

### 6.2 Pricing Confidence (Server-Side)

5-factor weighted score, 0-100:

```
pricing_confidence = (
    comp_count_score    * 0.30 +
    consistency_score   * 0.25 +
    brand_score         * 0.15 +
    recency_score       * 0.15 +
    match_quality_score * 0.15
) * 100
```

**Factor 1 — Comp Count (0.30):**
```
comp_count_score = min(1.0, ln(comp_count + 1) / ln(31))

  0 comps: 0.00    5 comps: 0.50    10 comps: 0.75
  15 comps: 0.85   20 comps: 0.92   30+ comps: 1.00
```

**Factor 2 — Price Consistency (0.25):**
```
CV = StdDev / Mean
consistency_score = clamp(1.0 - (CV * 1.2), 0.1, 1.0)

  CV < 0.10: 1.00    CV 0.20-0.30: 0.70
  CV 0.30-0.50: 0.50  CV > 0.80: 0.10
```

**Factor 3 — Brand Recognition (0.15):**
```
Tier 1 (Luxury):    1.00  — Gucci, Louis Vuitton, Chanel, Prada
Tier 2 (Premium):   0.90  — Lululemon, Patagonia, Nike, Arc'teryx
Tier 3 (Mainstream): 0.75  — Levi's, J.Crew, Zara, H&M
Tier 4 (Budget):    0.55  — Old Navy, Target brands, Shein
Tier 5 (Unknown):   0.30  — Not in database
```

**Factor 4 — Recency (0.15):**
```
recency_score = clamp(1.0 - (days_since_last_sale / 100), 0.1, 1.0)

  0-3 days: 1.00    15-30 days: 0.65    61-90 days: 0.25
```

**Factor 5 — Match Quality (0.15):**
```
Exact brand + model + condition + size: 1.00
Exact brand + model + condition:        0.85
Exact brand + model:                    0.70
Exact brand + similar style:            0.50
Brand only:                             0.30
Category only:                          0.15
```

### 6.3 Confidence Tiers

| Score | Tier | UI Color | UX Behavior |
|-------|------|----------|-------------|
| 80-100 | HIGH | `gainGreen` (#5AC53A) | Direct language: "Patagonia Better Sweater" |
| 55-79 | MEDIUM | `gold` (#F6C86A) | Hedged: "Likely a Patagonia Better Sweater" |
| 30-54 | LOW | `warning` (#EB5D2A) | Cautious: "This might be..." + suggest rescan |
| 0-29 | INSUFFICIENT | gray | "Not enough data" + offer manual entry |

**Rule:** Low confidence must NEVER use assertive language. Always offer tag-focused rescan.

### 6.4 Worked Example

```
Item: Patagonia Better Sweater Fleece, Size M, EUC
22 sold comps after outlier removal
Mean: $50.09, Median: $49, StdDev: $9.12, CV: 0.182
Most recent sale: 2 days ago
Match quality avg: 0.88

comp_count_score    = ln(23)/ln(31) = 0.913
consistency_score   = 1.0 - (0.182 * 1.2) = 0.782
brand_score         = 0.90 (Tier 2: Patagonia)
recency_score       = 1.0 - (2/100) = 0.98
match_quality_score = 0.88

Confidence = (0.30*0.913 + 0.25*0.782 + 0.15*0.90 + 0.15*0.98 + 0.15*0.88) * 100
           = 88.4 → HIGH CONFIDENCE

Price Range: Low $35 (P10) | Typical $49 (weighted trimmed mean) | High $65 (P90)
```

---

## 7. Database Schema

### Supabase Postgres + pgvector

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_url TEXT,
    scan_quota_remaining INT DEFAULT 5,
    quota_reset_at TIMESTAMPTZ DEFAULT (now() + interval '1 day'),
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- User Settings (preferences that affect buy/pass signal and profit calculations)
CREATE TABLE public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    -- Onboarding quiz answers
    experience_level TEXT DEFAULT 'beginner',  -- 'beginner', 'intermediate', 'expert'
    store_type TEXT DEFAULT 'goodwill',        -- 'goodwill', 'salvationArmy', 'consignment', 'vintage', 'garageSale', 'custom'
    default_cost_estimate DECIMAL(10,2) DEFAULT 7.00,  -- derived from store_type, user-adjustable
    -- Profit thresholds
    min_profit_dollars DECIMAL(10,2) DEFAULT 10.00,
    min_profit_percent INT,              -- null = use dollars mode
    profit_mode TEXT DEFAULT 'dollars',  -- 'dollars' or 'percent'
    -- Platform preferences
    preferred_platforms TEXT[] DEFAULT ARRAY['ebay', 'poshmark'],
    -- Shipping defaults (user-adjustable)
    shipping_clothing DECIMAL(10,2) DEFAULT 7.50,
    shipping_shoes DECIMAL(10,2) DEFAULT 12.00,
    shipping_heavy DECIMAL(10,2) DEFAULT 15.00,
    shipping_accessories DECIMAL(10,2) DEFAULT 5.00,
    -- Display preferences
    default_price_source TEXT DEFAULT 'sold',  -- 'sold', 'active', 'combined'
    show_all_platforms BOOLEAN DEFAULT true,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Scans (one row per camera scan — also serves as the item library)
CREATE TABLE public.scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    tag_image_url TEXT,
    thumbnail_url TEXT,
    processing_status TEXT DEFAULT 'pending',  -- pending, processing, completed, failed
    -- Item state (library)
    item_status TEXT DEFAULT 'scanned',  -- 'scanned', 'bought'
    purchase_price DECIMAL(10,2),        -- actual price paid (set when marked as bought)
    -- Identification
    predicted_brand TEXT,
    predicted_item_name TEXT,
    predicted_category TEXT,
    predicted_garment_type TEXT,
    predicted_size TEXT,
    predicted_color TEXT,
    predicted_material TEXT,
    -- Pricing (sold and active separated)
    sold_price_low DECIMAL(10,2),
    sold_price_median DECIMAL(10,2),
    sold_price_high DECIMAL(10,2),
    sold_comp_count INT DEFAULT 0,
    active_price_low DECIMAL(10,2),
    active_price_median DECIMAL(10,2),
    active_price_high DECIMAL(10,2),
    active_comp_count INT DEFAULT 0,
    combined_price_low DECIMAL(10,2),
    combined_price_median DECIMAL(10,2),
    combined_price_high DECIMAL(10,2),
    price_currency TEXT DEFAULT 'USD',
    -- Market insights
    sell_through_rate INT,            -- 0-100 percentage
    avg_days_to_sell INT,
    demand_level TEXT,                -- 'high', 'moderate', 'low'
    volume_trend TEXT,                -- 'rising', 'stable', 'declining'
    -- Buy signal
    buy_signal TEXT,                  -- 'green', 'yellow', 'red'
    buy_signal_reason TEXT,
    -- Profit (using default cost estimate from user settings)
    estimated_cost DECIMAL(10,2),   -- from user_settings.default_cost_estimate
    best_net_profit DECIMAL(10,2),
    best_platform TEXT,
    estimated_roi INT,
    -- Confidence
    confidence_score INT,            -- 0-100
    confidence_level TEXT,           -- high, medium, low, insufficient
    confidence_factors JSONB,        -- [{name, value}]
    -- Tag extraction
    tag_brand TEXT,
    tag_size TEXT,
    tag_material TEXT,
    tag_rn_number TEXT,
    tag_raw_text TEXT,
    -- Metadata
    comp_count INT,
    processing_time_ms INT,
    raw_ml_response JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Corrections (append-only audit log)
CREATE TABLE public.corrections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,         -- 'brand', 'item_name', 'category', etc.
    original_value TEXT,
    corrected_value TEXT NOT NULL,
    confidence_at_prediction FLOAT,
    source TEXT DEFAULT 'user',       -- 'user', 'admin', 'model_v2'
    created_at TIMESTAMPTZ DEFAULT now()
);
-- NEVER UPDATE or DELETE. Only INSERT.

-- Comps (cached comparable listings per scan)
CREATE TABLE public.comps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL,             -- 'sold', 'active'
    sold_date DATE,
    source TEXT DEFAULT 'ebay',
    image_url TEXT,
    listing_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Listing Drafts (eBay listings generated from scan data)
CREATE TABLE public.listing_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    platform TEXT DEFAULT 'ebay',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT,
    condition TEXT DEFAULT 'Pre-owned',
    suggested_price DECIMAL(10,2),
    photos TEXT[] DEFAULT '{}',          -- URLs of listing photos (NOT scan photos)
    status TEXT DEFAULT 'draft',         -- 'draft', 'needsPhotos', 'ready', 'published'
    external_listing_id TEXT,            -- eBay listing ID after publish
    external_listing_url TEXT,           -- eBay URL after publish
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Visual embeddings for similarity search
CREATE TABLE public.scan_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    embedding vector(512),
    model_version TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- HNSW index for fast approximate nearest neighbor search
CREATE INDEX ON public.scan_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Materialized view: latest corrected value per scan per field
CREATE MATERIALIZED VIEW public.scan_corrected_values AS
SELECT DISTINCT ON (scan_id, field_name)
    scan_id,
    field_name,
    corrected_value AS current_value,
    created_at AS corrected_at
FROM public.corrections
ORDER BY scan_id, field_name, created_at DESC;

-- Indexes
CREATE INDEX idx_scans_user_id ON public.scans(user_id);
CREATE INDEX idx_scans_created_at ON public.scans(created_at DESC);
CREATE INDEX idx_scans_processing_status ON public.scans(processing_status);
CREATE INDEX idx_scans_item_status ON public.scans(item_status);
CREATE INDEX idx_scans_user_item_status ON public.scans(user_id, item_status);
CREATE INDEX idx_corrections_scan_id ON public.corrections(scan_id);
CREATE INDEX idx_corrections_field ON public.corrections(field_name, original_value);
CREATE INDEX idx_comps_scan_id ON public.comps(scan_id);
CREATE INDEX idx_listing_drafts_scan ON public.listing_drafts(scan_id);
CREATE INDEX idx_listing_drafts_user ON public.listing_drafts(user_id);
CREATE INDEX idx_corrected_values_scan ON public.scan_corrected_values(scan_id);
```

### Row-Level Security

```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_embeddings ENABLE ROW LEVEL SECURITY;

-- Users: own profile only
CREATE POLICY "own_profile_select" ON public.users FOR SELECT USING (id = auth.uid());
CREATE POLICY "own_profile_update" ON public.users FOR UPDATE USING (id = auth.uid());

-- User settings: own settings only
CREATE POLICY "own_settings_all" ON public.user_settings FOR ALL
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Scans: own scans only
CREATE POLICY "own_scans_select" ON public.scans FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "own_scans_insert" ON public.scans FOR INSERT WITH CHECK (user_id = auth.uid());

-- Corrections: own corrections only
CREATE POLICY "own_corrections_select" ON public.corrections FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "own_corrections_insert" ON public.corrections FOR INSERT WITH CHECK (user_id = auth.uid());

-- Comps: visible to scan owner
CREATE POLICY "own_comps_select" ON public.comps FOR SELECT
    USING (scan_id IN (SELECT id FROM public.scans WHERE user_id = auth.uid()));

-- Listing drafts: own drafts only
CREATE POLICY "own_listing_drafts_all" ON public.listing_drafts FOR ALL
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Service role bypasses RLS for backend pipeline writes
```

---

## 8. Image Storage

### Supabase Storage

**Upload flow (direct from iOS via Supabase Swift SDK):**
```
iOS App                    Supabase Storage
  │                              │
  │ supabase.storage             │
  │   .from("scan-images")      │
  │   .upload(path, data)       │
  │─────────────────────────────>│
  │                              │
  │ public URL returned          │
  │<─────────────────────────────│
  │                              │
  │ POST /api/v1/scan            │
  │   (with image URLs)         │
  │─────────────────────────────>│ FastAPI (on Render)
```

**Bucket structure:**
```
scan-images/
  {user_id}/
    {scan_id}_tag.jpg
    {scan_id}_item.jpg
    {scan_id}_thumb.jpg
```

**Supabase Storage policies:**
- Users can upload to their own folder: `bucket_id = 'scan-images' AND (storage.foldername(name))[1] = auth.uid()`
- Users can read their own images: same policy on SELECT
- Service role can read all (for backend processing)

**Image transforms:** Supabase Image Transformation (on Pro plan). On free tier, generate thumbnails server-side with Pillow in FastAPI.

**JPEG compression:** 0.85 quality on client before upload.

**Free tier limit:** 1GB storage, 2GB bandwidth/month. At ~200KB per image pair, supports ~2,500 scans before hitting limit.

---

## 9. Rate Limiting & Quotas

### Layer 1: API Rate Limiting (slowapi + Upstash Redis)

```python
# Endpoint limits
POST /api/v1/scan:                  10/minute per user
GET  /api/v1/items:                 60/minute per user
GET  /api/v1/items/{id}:            60/minute per user
PUT  /api/v1/items/{id}:            30/minute per user
POST /api/v1/items/{id}/correct:    30/minute per user
POST /api/v1/items/{id}/listing-draft: 10/minute per user
GET/PUT /api/v1/settings:           30/minute per user
Global:                             100/minute per IP
```

### Layer 2: Business Quota (5 Scans/Day)

**Reset:** Calendar day, midnight UTC.

**Implementation:** Redis INCR with auto-expiring key.

```
Key:    quota:{user_id}:{YYYY-MM-DD}
Op:     INCR (atomic, race-condition safe)
Expiry: 25 hours (safety margin)
Limit:  5 per key
```

**Response on exceeded:**
```json
{
  "error": "rate_limited",
  "message": "Daily scan limit reached. Upgrade for unlimited scans.",
  "remaining": 0,
  "resets_at": "midnight UTC"
}
```

### Upstash Free Tier Budget

At 10K users × 5 scans/day × 2 commands/scan = 300K commands/month. Fits within 500K free tier.

---

## 10. Background Jobs

### ARQ (asyncio task queue, Redis broker)

**What runs async (ARQ):**

| Task | Why Async | Timeout |
|------|-----------|---------|
| Full scan processing pipeline | 3-8 seconds total | 300s |
| eBay price lookup + comp fetch | External API, 500ms-2s | 60s |
| FashionCLIP embedding generation | CPU-bound, 1-5s | 120s |
| Image resize for ML inference | CPU-bound, ~500ms | 30s |

**What runs sync (in request):**

| Task | Why Sync |
|------|----------|
| Store scan record (DB write) | <10ms |
| pgvector similarity search | <50ms |
| Presigned URL generation | <20ms |
| Quota check (Redis INCR) | <5ms |

**Retry policy:** 3 attempts, 5s base defer, exponential backoff for rate limit errors (30s → 60s → 120s).

---

## 11. User Correction Loop

### Design: Append-Only Audit Log

Every correction is an INSERT, never UPDATE or DELETE. This preserves:
- Full history for analyzing systematic ML errors.
- Labeled training data: `(image, field, wrong_value, right_value)`.
- Audit trail for compliance.

### API

```
POST /api/v1/collection/{item_id}/correct

Request:
{
  "correctedBrand": "Patagonia",
  "correctedItemName": "Synchilla Snap-T Fleece",
  "correctedCategory": "Outerwear",
  "notes": "It's the snap-t not the better sweater"
}

Response: Updated ScanResult with re-computed pricing.
```

Each field correction creates a separate row in `corrections`.

### Using Corrections to Improve

**Short-term:** Build correction map from aggregate data. If >30% of users correct brand X → brand Y, apply automatically.

**Medium-term:** Export corrections as labeled training data for model fine-tuning.

**Long-term:** Correction-weighted post-processing heuristics on all predictions.

---

## 12. Cost Projections

### 0-100 Users: ~$0/month

All free tiers: Supabase free (auth + 500MB DB + 1GB storage), Render free (750 hrs/mo with cold starts), Upstash free (500K commands), eBay Browse API free (5K/day).

### 100 Users: ~$7-12/month

| Service | Cost |
|---------|------|
| Supabase Auth + DB + Storage (free tier) | $0 |
| Render (Starter, no cold starts) | $7 |
| Upstash Redis (free tier) | $0 |
| eBay Browse API | $0 |

### 1,000 Users: ~$40-55/month

| Service | Cost |
|---------|------|
| Supabase Pro (8GB DB, 100GB storage) | $25 |
| Render (Standard) | ~$15-25 |
| Upstash Redis (~1.5M commands) | ~$3 |
| eBay Browse API | $0 |

### 10,000 Users: ~$150-250/month

Supabase Pro ($50-100), Render Standard+ (~$50-100), Upstash (~$30), eBay may need caching or paid tier.

### Cost Cliffs

| Trigger | Action | Added Cost |
|---------|--------|------------|
| DB > 500MB | Supabase Pro | +$25/mo |
| Storage > 1GB | Supabase Pro | +$25/mo (bundled with DB) |
| Redis > 500K commands | Upstash pay-as-you-go | +$1-30/mo |
| Cold starts unacceptable | Render Starter ($7) | +$7/mo |
| eBay > 5K calls/day | Cache aggressively | Variable |

---

## 13. Brand Tier Database

### Tier 1 — Luxury/Designer (brand_score = 1.00)

Gucci, Louis Vuitton, Chanel, Prada, Burberry, Hermes, Dior, Balenciaga, Versace, Fendi, Saint Laurent, Valentino, Givenchy, Bottega Veneta, Celine, Moncler, Tom Ford, Alexander McQueen, Loro Piana, Brunello Cucinelli, Issey Miyake, Comme des Garcons, Maison Margiela, Stone Island

### Tier 2 — Premium/Athletic (brand_score = 0.90)

Lululemon, Patagonia, The North Face, Arc'teryx, Nike, Adidas, Jordan, New Balance, Carhartt, Ralph Lauren, Tommy Hilfiger, Vineyard Vines, Free People, Anthropologie, Reformation, AllSaints, Ted Baker, Hugo Boss, Coach, CP Company, Acne Studios, Canada Goose, Barbour, Supreme, Bape

### Tier 3 — Mainstream/Known (brand_score = 0.75)

Levi's, J.Crew, Banana Republic, Gap, Zara, H&M, Madewell, American Eagle, Abercrombie, Under Armour, Columbia, Eddie Bauer, Calvin Klein, Michael Kors, DKNY, Guess, Express

### Tier 4 — Value/Budget (brand_score = 0.55)

Old Navy, Target brands (Cat & Jack, A New Day, Universal Thread, Goodfellow), Shein, Forever 21, Primark, Walmart brands (George, Time and Tru), Uniqlo

### Tier 5 — Unknown/Private Label (brand_score = 0.30)

Any brand not in the database. Default tier.

---

## 14. Constants & Configuration

```swift
// MARK: - Pricing Engine Configuration
struct PricingConfig {
    // Outlier Filtering
    static let excludedKeywords = ["lot", "bundle", "wholesale", "parts",
        "repair", "damaged", "broken", "stain", "as-is", "for parts",
        "read description", "salvage"]
    static let priceFloor: Double = 2.00
    static let priceCeilingMultiplier: Double = 5.0
    static let iqrMultiplier: Double = 1.5

    // Recency Weighting
    static let decayLambda: Double = 0.03
    static let maxDaysOld: Int = 90

    // Trimmed Mean
    static let trimPercentage: Double = 0.15

    // Confidence Weights (Pricing)
    static let compCountWeight: Double = 0.30
    static let consistencyWeight: Double = 0.25
    static let brandWeight: Double = 0.15
    static let recencyWeight: Double = 0.15
    static let matchQualityWeight: Double = 0.15

    // Confidence Tiers
    static let highConfidenceThreshold: Double = 80.0
    static let mediumConfidenceThreshold: Double = 55.0
    static let lowConfidenceThreshold: Double = 30.0

    // Minimum Comps
    static let minimumCompsForEstimate: Int = 3
    static let minimumCompsForHighConfidence: Int = 10

    // Percentile Ranges
    static let lowPercentile: Double = 10.0
    static let midPercentile: Double = 50.0
    static let highPercentile: Double = 90.0

    // Identification Confidence Weights (On-Device)
    static let ocrBrandWeight: Double = 0.35
    static let rnLookupWeight: Double = 0.25
    static let visualMatchWeight: Double = 0.25
    static let garmentTypeWeight: Double = 0.15

    // Buy Signal Thresholds
    static let buySignalGreenThreshold: Double = 65.0
    static let buySignalYellowThreshold: Double = 40.0

    // Sell-Through Rate Thresholds
    static let highDemandThreshold: Int = 65
    static let moderateDemandThreshold: Int = 35

    // Default Shipping Costs
    static let shippingClothing: Double = 7.50
    static let shippingShoes: Double = 12.00
    static let shippingHeavy: Double = 15.00
    static let shippingAccessories: Double = 5.00

    // Default Profit Threshold
    static let defaultMinProfitDollars: Double = 10.00
}
```

```python
# Python equivalent for FastAPI backend
class PricingConfig:
    EXCLUDED_KEYWORDS = ["lot", "bundle", "wholesale", "parts",
        "repair", "damaged", "broken", "stain", "as-is", "for parts",
        "read description", "salvage"]
    PRICE_FLOOR = 2.00
    PRICE_CEILING_MULTIPLIER = 5.0
    IQR_MULTIPLIER = 1.5
    DECAY_LAMBDA = 0.03
    MAX_DAYS_OLD = 90
    TRIM_PERCENTAGE = 0.15
    MIN_COMPS_FOR_ESTIMATE = 3

    # Confidence weights
    COMP_COUNT_W = 0.30
    CONSISTENCY_W = 0.25
    BRAND_W = 0.15
    RECENCY_W = 0.15
    MATCH_QUALITY_W = 0.15

    # Confidence tiers
    HIGH_CONFIDENCE = 80
    MEDIUM_CONFIDENCE = 55
    LOW_CONFIDENCE = 30

    # Buy signal thresholds
    BUY_SIGNAL_GREEN = 65
    BUY_SIGNAL_YELLOW = 40

    # Sell-through rate thresholds
    HIGH_DEMAND = 65
    MODERATE_DEMAND = 35

    # Platform fees
    PLATFORM_FEES = {
        "ebay":     {"fee_percent": 0.1325, "fixed_fee": 0.30, "shipping_included": False},
        "poshmark": {"fee_percent": 0.20,   "fee_flat_under_15": 2.95, "fixed_fee": 0, "shipping_included": True},
        "mercari":  {"fee_percent": 0.10,   "fixed_fee": 0, "shipping_included": False},
        "depop":    {"fee_percent": 0.033,  "fixed_fee": 0.45, "shipping_included": False},
        "whatnot":  {"fee_percent": 0.08,   "fixed_fee": 0, "shipping_included": False},
    }

    # Default shipping costs by garment type
    SHIPPING_DEFAULTS = {
        "clothing": 7.50,
        "shoes": 12.00,
        "heavy": 15.00,
        "accessories": 5.00,
    }

    # Default profit threshold
    DEFAULT_MIN_PROFIT_DOLLARS = 10.00
```
