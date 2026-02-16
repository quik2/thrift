# ThriftFlip Pricing Algorithm Research Report

> Comprehensive research on resale pricing algorithms, comp-based methodology, confidence scoring, and price range calculation for building ThriftFlip's eBay-backed pricing engine.

---

## Table of Contents

1. [How Existing Platforms Compute Resale Prices](#1-how-existing-platforms-compute-resale-prices)
2. [Comp-Based Pricing Methodology](#2-comp-based-pricing-methodology)
3. [Confidence Scoring Formula](#3-confidence-scoring-formula)
4. [Price Range Calculation](#4-price-range-calculation)
5. [Recommended ThriftFlip Implementation](#5-recommended-thriftflip-implementation)

---

## 1. How Existing Platforms Compute Resale Prices

### 1.1 StockX

**Pricing Model:** Stock-market-style bid/ask system where buyers place bids and sellers list asks. Sales execute automatically when a bid matches an ask.

**Key Metrics (publicly documented):**

- **Last Sale Price:** The actual transaction price of the most recent sale. Displayed prominently on each product page.
- **Price Premium:** `(Average Resale Price - Retail Price) / Retail Price * 100`. A sneaker retailing at $150 with an average resale of $300 has a 100% price premium.
- **Price Volatility:** `Standard Deviation / Average Price`. A sneaker with an average deadstock price of $200 and 40% volatility means the expected price range is $120-$280.
- **Average Deadstock Price:** Average sales price of all deadstock items sold over the past 12 months. StockX removes fakes, outliers, and multi-pair auctions from this calculation.
- **12-Month Trade Range:** The full range of prices observed over 12 months. In one study, the average 12-month trade range for sneakers was approximately $1,578 with average volatility of 27%.

**Pricing Guidance Algorithm:**
- "Sell Faster" price: A lower ask price likely to match a bid quickly.
- "Earn More" price: Based on recent global sales data, optimized for higher return with longer wait.

**Data Weighting:** StockX weights recent global sales rather than just local market data for its "Earn More" guidance. Exact time-decay weighting is proprietary.

**Relevance to ThriftFlip:** StockX's volatility formula (`StdDev / Mean`) is directly applicable for indicating price stability in our estimates.

---

### 1.2 Poshmark

**Pricing Model:** Fixed-price listings with offer/counter-offer negotiation system.

**Price Suggestion Algorithm (announced PoshFest 2025):**
- **Dual-price system:** Poshmark now suggests two prices when creating a listing:
  1. **"Hot Deal" price** -- designed for fast sales. If used, Poshmark applies a "hot deal" label across search, closets, brands, and listing detail pages.
  2. **Estimated selling price** -- higher price for sellers willing to wait longer.
- The algorithm behind these suggestions is proprietary but is described as data from millions of completed transactions.

**Key Pricing Factors:**
- **Original retail price relationship:** Items typically priced at 30-40% off original retail.
- **Markup buffer:** Experienced sellers list at 5-30% above their floor price to accommodate Poshmark's "Offers to Likers" feature (which requires a minimum 10% price reduction + shipping discount).
- **Brand tier:** Luxury brands (Gucci, Louis Vuitton) command higher percentages of retail; fast fashion (Forever 21, Old Navy) sells at steep discounts.
- **Condition:** Major factor in discount depth from retail.
- **Listing freshness:** Newly shared listings get a temporary algorithmic visibility boost.
- **Engagement metrics:** Likes, offers, and buyer history matching affect visibility.

**Relevance to ThriftFlip:** Poshmark's dual-price concept (quick sale vs. max value) maps well to a low/high range estimate. Their 30-40% off retail baseline is useful for validation.

---

### 1.3 eBay Terapeak (Product Research)

**What It Is:** Free research tool built into eBay Seller Hub that provides real-time sold item data.

**Key Metrics Provided:**
- **Average sold price** for any keyword search
- **Sold price range** (low to high)
- **Actual sold price** (including accepted Best Offer prices)
- **Average shipping cost** and shipping terms
- **Number of unique sellers** who sold that item
- **Sell-through rate** (percentage of listings that resulted in sales)
- **Total sales revenue** for a search
- **Upward/downward price trends** over time
- **Free shipping percentage**

**Data Scope:** Historical data spanning up to 365 days. Allows tracking seasonal fluctuations, identifying trends, and predicting demand patterns.

**How It Works:**
1. Search by keyword (e.g., "Patagonia fleece jacket")
2. Filter by condition, price range, listing format, date range
3. Terapeak calculates aggregate metrics across all matching sold listings
4. Shows both active listing analytics AND sold item analytics

**Two Sub-Tools:**
- **Product Research:** Analyze sold items and market demand (free to all sellers)
- **Sourcing Insights:** Analyze supply-side data (requires Basic+ Store subscription)

**eBay Pricing Recommendations Tool:**
- Available on US, UK, and DE sites
- Shows a price range and probability graph indicating likelihood of selling at different price points
- Based on similar items sold in the past 90 days
- More input details = more precise price range suggestion

**Relevance to ThriftFlip:** Terapeak is essentially what we're replicating in a mobile-first, scan-to-price format. The 90-day sold data window and the metrics it surfaces (average price, sell-through rate, price range) are our exact target feature set.

---

### 1.4 ThredUp

**Pricing Model:** Consignment platform where ThredUp sets prices using algorithmic pricing.

**Algorithm Components:**
- **Machine learning from 16+ years of resale data** and millions of listings
- **Computer vision models** analyze photos for brand, color, condition, and category
- **Brand tier system** that segments items into payout brackets:
  - Premium/designer brands (Lululemon, Gucci): up to 80% of sale price returned to seller
  - Mid-tier brands (Theory, Eileen Fisher, Vince): moderate percentages
  - Mass-market brands (Forever 21, Old Navy): no longer accepted or minimal payout
  - Payout range: 3%-80% of sell price depending on brand tier and final price
- **Dynamic markdown strategy:** Items are gradually discounted over time to improve sell-through, with discounts capped at 20% for Premium bag items.
- **Price-based tiers:** The higher an item sells for, the higher the seller's percentage (tiered commission: items over $100 from upscale brands earn 60-80%).

**Relevance to ThriftFlip:** ThredUp's brand-tier pricing system is a useful reference for building our own brand recognition database. Their progressive markdown approach informs how we might show "sell now" vs "wait for more" pricing.

---

### 1.5 Goodwill (shopgoodwill.com)

**Pricing Model:** Online auction platform with proxy bidding.

**How Items Are Priced:**
- **Starting prices** are set low by Goodwill staff to attract bidders
- **Proxy bidding system:** Buyers enter maximum bid; system auto-bids incrementally up to that max
- **Bid increments** are predefined per auction and added to current price (not to max bid)
- **No reserve prices** on most items -- true auction dynamics
- **Buy It Now** option available on some listings (non-auction format)

**Data Availability:** Limited. No public API. No historical pricing database. Auction results are not easily searchable after completion.

**GoodwillFinds (separate site):** Uses a fixed-price model where Goodwill prices items based on past sales data. No auction. Less transparent about methodology.

**Relevance to ThriftFlip:** Goodwill data is not practically accessible for our pricing engine. However, Goodwill retail store pricing (typically $3.99-$12.99 for clothing) is useful context for showing users their potential profit margin.

---

## 2. Comp-Based Pricing Methodology

### 2.1 Selecting Comparable Listings ("Comps")

**Definition:** Comps are recently sold items that closely match the target item in brand, model, condition, size, and other relevant attributes.

**Comp Selection Hierarchy (most important to least):**

| Priority | Attribute | Why It Matters |
|----------|-----------|---------------|
| 1 | Brand + Model/Style | Same brand + same specific item is the strongest match |
| 2 | Condition | NWT vs. EUC vs. Good vs. Fair creates 20-50% price variance |
| 3 | Size | Common sizes (S/M/L) sell closer to median; extreme sizes may sell at discount |
| 4 | Color/Pattern | Rare colorways or sought-after patterns can command premiums |
| 5 | Listing type | Buy It Now vs. Auction can affect final price |
| 6 | Recency | More recent sales better reflect current market value |

**Minimum Comp Counts (recommended for ThriftFlip):**

| Comp Count | Confidence Tier | Reliability |
|------------|----------------|-------------|
| 0-2 comps | Insufficient | Do not display a price estimate; show "not enough data" |
| 3-4 comps | Low | Display with heavy caveats; wide range only |
| 5-9 comps | Medium | Reasonable estimate; display with moderate confidence |
| 10-19 comps | High | Strong estimate; narrow range possible |
| 20+ comps | Very High | Highly reliable; statistical methods fully effective |

These thresholds are derived from real estate appraisal standards (minimum 3-5 comparables per Fannie Mae guidelines) adapted for the higher variability of resale clothing.

**eBay Data Source:**
- **eBay Marketplace Insights API:** Returns sold item data for the last 90 days. Limited Release -- requires eBay approval.
- **eBay Finding API (findCompletedItems):** Legacy API returning completed/sold listings with filtering by keyword, condition, price range, category, and item specifics.
- **Practical data window:** 90 days maximum through eBay APIs. For seasonal analysis, cached/historical data is needed.

---

### 2.2 Filtering Outliers

Outlier removal is critical because eBay sold data contains:
- **Damaged/defective items** sold at steep discounts
- **Bundles/lots** (multiple items sold as one listing)
- **Wrong items** in search results (keyword pollution)
- **Charity/donation listings** priced abnormally
- **Shill bids or price manipulation** on auctions

**Recommended Outlier Filtering Pipeline:**

```
Step 1: Keyword Filtering
  - Exclude listings containing: "lot", "bundle", "wholesale", "parts",
    "repair", "damaged", "broken", "stain", "as-is", "for parts"
  - Exclude multi-quantity listings (quantity > 1)

Step 2: Price Floor/Ceiling
  - Remove listings below $2.00 (likely errors or accessory-only sales)
  - Remove listings above 5x the median (likely different/rarer item variant)

Step 3: IQR Method (Statistical Outlier Removal)
  - Calculate Q1 (25th percentile) and Q3 (75th percentile)
  - IQR = Q3 - Q1
  - Lower bound = Q1 - (1.5 * IQR)
  - Upper bound = Q3 + (1.5 * IQR)
  - Remove any price below lower bound or above upper bound
  - For resale data with heavy right skew, consider using 2.0 * IQR
    instead of 1.5 for more permissive filtering

Step 4: Condition Matching
  - If target condition is known, prefer same-condition comps
  - If mixing conditions, apply adjustment factors:
    NWT (New With Tags): +15-25% above median
    NWOT (New Without Tags): +5-15% above median
    EUC (Excellent Used Condition): baseline (0%)
    Good: -10-20% below median
    Fair/Acceptable: -25-40% below median
```

**IQR Advantages for Resale Data:**
- Does not assume normal distribution (resale prices are typically right-skewed)
- Robust against non-parametric data
- Well-established statistical method
- Simple to implement and explain

---

### 2.3 Weighting Comps

Not all comps are equal. Weighting comps by relevance improves accuracy.

**Recency Weighting (Time Decay):**

Two established approaches:

**Exponential Decay (recommended):**
```
Weight = e^(-lambda * days_old)

Where:
  lambda = decay rate (recommended: 0.02 to 0.05 for 90-day windows)
  days_old = number of days since the sale

Examples with lambda = 0.03:
  Sale today:      Weight = 1.000
  Sale 7 days ago: Weight = 0.810
  Sale 14 days ago: Weight = 0.657
  Sale 30 days ago: Weight = 0.407
  Sale 60 days ago: Weight = 0.165
  Sale 90 days ago: Weight = 0.067
```

**Linear Decay (simpler alternative):**
```
Weight = 1 - (k * days_old)

Where:
  k = decay rate (e.g., 1/90 = 0.0111 for a 90-day window)

Examples:
  Sale today:      Weight = 1.000
  Sale 30 days ago: Weight = 0.667
  Sale 60 days ago: Weight = 0.333
  Sale 90 days ago: Weight = 0.000
```

Exponential decay is preferred because it reflects market reality: a sale 3 days ago is significantly more relevant than one 30 days ago, but a sale 60 days ago vs 90 days ago matters less.

**Condition Matching Weight:**
```
exact_condition_match:  1.0
one_grade_off:          0.7
two_grades_off:         0.4
unknown_condition:      0.5
```

**Size Matching Weight:**
```
exact_size_match:  1.0
one_size_off:      0.8
two_sizes_off:     0.5
different_sizing:  0.6 (e.g., numeric vs letter sizing)
```

**Combined Weight Formula:**
```
final_weight = recency_weight * condition_weight * size_weight
```

**Weighted Price Calculation:**
```
estimated_price = SUM(price_i * weight_i) / SUM(weight_i)
```

---

### 2.4 Trimmed Mean vs. Median vs. Mean

| Method | Best For | Weakness | Recommendation |
|--------|----------|----------|---------------|
| **Mean** | Normal distributions, no outliers | Heavily skewed by outliers ($5 damage sales, $500 rare variants) | Not recommended for resale data |
| **Median** | Highly skewed data, very small samples (n < 5) | Ignores distribution shape, less efficient for normal data | Good fallback for small comp sets |
| **Trimmed Mean (10-20%)** | Moderate outliers, medium-large samples (n >= 10) | Requires enough data to trim; trim percentage is somewhat arbitrary | **Best default for resale pricing** |
| **Weighted Trimmed Mean** | When recency/condition weighting is applied | Most complex to implement | **Best overall approach** |

**Recommended Approach for ThriftFlip:**

```
if comp_count < 5:
    use median (most robust with tiny samples)
elif comp_count < 10:
    use 10% trimmed mean
elif comp_count >= 10:
    use 15-20% trimmed mean with recency weighting
```

A 20% trim removes the bottom 10% and top 10% of values before computing the mean. This effectively handles the most egregious outliers that survive the IQR filter while preserving the distribution shape.

---

### 2.5 Handling Seasonal Variation

**The Problem:** A winter coat scanned in July will have different comps (and prices) than the same coat scanned in November. eBay sold data from the last 90 days in summer will underrepresent winter coat demand.

**Seasonal Price Impact on Clothing Categories:**

| Category | Peak Months | Off-Peak Months | Estimated Seasonal Swing |
|----------|-------------|-----------------|-------------------------|
| Winter coats/jackets | Oct-Jan | Apr-Jul | +30-50% at peak vs off-peak |
| Sweaters/knitwear | Sep-Dec | Mar-Jun | +20-40% |
| Swimwear | Apr-Jul | Oct-Jan | +25-40% |
| Summer dresses | Mar-Jul | Oct-Jan | +15-30% |
| Boots | Sep-Jan | Apr-Jul | +20-35% |
| Sandals | Apr-Aug | Nov-Feb | +20-35% |
| Year-round basics | Minimal | Minimal | +/- 5-10% |
| Athleisure | Jan (New Year) | Minimal | +10-15% |

**Seasonal Adjustment Method:**

```
Multiplicative Seasonal Index:

seasonal_factor = typical_month_demand / average_annual_demand

Where seasonal_factor is near 1.0 for average months:
  - 1.3 means demand is 30% above annual average
  - 0.7 means demand is 30% below annual average

Adjusted Price = raw_comp_price * (current_month_factor / comp_month_factor)
```

**Example:** Winter coat sold in February (factor 1.25) being estimated in July (factor 0.75):
```
If February comps show median of $60:
  Adjusted for July = $60 * (0.75 / 1.25) = $36

If current month is November (factor 1.30):
  Adjusted for November = $60 * (1.30 / 1.25) = $62.40
```

**Practical Implementation for ThriftFlip:**
1. **Primary approach:** Use raw eBay sold data from the last 90 days as-is (it already reflects current seasonal demand).
2. **Enhancement (Phase 2):** Build seasonal indices from 12+ months of cached historical data. Apply adjustment only when the user wants a "sell later" estimate.
3. **User-facing note:** When showing off-season items, add context like "Prices typically increase 30-50% during Oct-Jan for winter coats."

---

## 3. Confidence Scoring Formula

### 3.1 Factors That Affect Confidence

| Factor | Higher Confidence | Lower Confidence |
|--------|------------------|-----------------|
| Number of comps | 20+ sold in 90 days | < 5 sold in 90 days |
| Price consistency | Low coefficient of variation | High coefficient of variation |
| Brand recognition | Well-known brand (Nike, Levi's) | Unknown/private label brand |
| Exact matches | Many same-brand, same-model comps | Only loosely similar items |
| Category type | Common items (basic tee, jeans) | Rare/vintage/unique items |
| Recency | Multiple sales in last 14 days | Last sale was 60+ days ago |
| Condition clarity | Condition clearly stated | Condition unknown/mixed |
| Price range width | Narrow IQR (< 30% of median) | Wide IQR (> 80% of median) |

### 3.2 Confidence Scoring Formula

**Proposed formula: Weighted multi-factor score normalized to 0-100.**

```
confidence_score = (
    w1 * comp_count_score +
    w2 * consistency_score +
    w3 * brand_score +
    w4 * recency_score +
    w5 * match_quality_score
) * 100

Where all weights sum to 1.0:
  w1 = 0.30  (comp count -- most important single factor)
  w2 = 0.25  (price consistency)
  w3 = 0.15  (brand recognition)
  w4 = 0.15  (recency of sales)
  w5 = 0.15  (match quality)
```

### 3.3 Scoring Each Factor (0.0 to 1.0)

**Factor 1: Comp Count Score (w = 0.30)**
```
comp_count_score:
  0 comps:     0.00
  1 comp:      0.10
  2 comps:     0.20
  3 comps:     0.35
  5 comps:     0.50
  8 comps:     0.65
  10 comps:    0.75
  15 comps:    0.85
  20 comps:    0.92
  30+ comps:   1.00

Formula (logarithmic curve):
  comp_count_score = min(1.0, ln(comp_count + 1) / ln(31))
```

**Factor 2: Price Consistency Score (w = 0.25)**
```
Based on Coefficient of Variation (CV = StdDev / Mean):
  CV < 0.10:  1.00  (very tight pricing -- strong market consensus)
  CV 0.10-0.20: 0.85
  CV 0.20-0.30: 0.70
  CV 0.30-0.50: 0.50
  CV 0.50-0.80: 0.30
  CV > 0.80:  0.10  (wild price swings -- unreliable)

Formula (inverse relationship):
  consistency_score = max(0.1, 1.0 - (CV * 1.2))
  Clamped to [0.1, 1.0]
```

**Factor 3: Brand Recognition Score (w = 0.15)**
```
Tier 1 (Premium/Luxury): 1.00
  Examples: Gucci, Louis Vuitton, Chanel, Burberry, Prada
  Rationale: Highly searched, many comps, well-known pricing

Tier 2 (High Street Premium): 0.90
  Examples: Lululemon, Patagonia, North Face, Nike, Adidas

Tier 3 (Mainstream Brands): 0.75
  Examples: Levi's, J.Crew, Banana Republic, Zara, H&M

Tier 4 (Value/Budget Brands): 0.55
  Examples: Old Navy, Target (Cat & Jack, A New Day), Shein

Tier 5 (Unknown/Private Label): 0.30
  Examples: Unrecognized brand, store brand, no brand tag

Implementation: Maintain a brand database (start with top 500 resale
brands) with tier assignments. Default to Tier 5 for unknown brands.
```

**Factor 4: Recency Score (w = 0.15)**
```
Based on days since most recent comp sale:
  0-3 days:    1.00
  4-7 days:    0.90
  8-14 days:   0.80
  15-30 days:  0.65
  31-60 days:  0.45
  61-90 days:  0.25
  90+ days:    0.10

Formula:
  recency_score = max(0.1, 1.0 - (days_since_last_sale / 100))
```

**Factor 5: Match Quality Score (w = 0.15)**
```
Based on how well comps match the target item:
  Exact brand + model + condition + size:  1.00
  Exact brand + model + condition:         0.85
  Exact brand + model:                     0.70
  Exact brand + similar style:             0.50
  Brand only:                              0.30
  Category only (no brand match):          0.15

Implementation: Score each comp individually, then average.
```

### 3.4 Confidence Tiers

```
Score 80-100: HIGH CONFIDENCE
  Display: Solid price estimate with tight range
  UI: Green indicator
  Typical scenario: Popular Nike shoe, 25+ comps, low price variance

Score 55-79:  MEDIUM CONFIDENCE
  Display: Reasonable estimate with moderate range
  UI: Yellow indicator
  Typical scenario: Known brand jacket, 8-15 comps, moderate variance

Score 30-54:  LOW CONFIDENCE
  Display: Rough estimate with wide range, caveat text
  UI: Orange indicator
  Typical scenario: Less common brand, 3-7 comps, high variance

Score 0-29:   INSUFFICIENT DATA
  Display: "Not enough data for reliable estimate"
  UI: Gray indicator
  Typical scenario: Unknown brand, < 3 comps, or extreme variance
```

### 3.5 Worked Example

```
Item: Patagonia Better Sweater Fleece, Size M, EUC

Comp data from eBay (last 90 days):
  22 sold listings found after outlier removal
  Prices: $35, $38, $40, $42, $42, $44, $45, $45, $47, $48,
          $48, $50, $50, $52, $52, $55, $55, $58, $60, $62, $65, $70
  Mean: $50.09, Median: $49, StdDev: $9.12
  CV = 9.12 / 50.09 = 0.182
  Most recent sale: 2 days ago
  Match quality: Exact brand + model for 18 of 22 comps (avg: 0.88)

Factor Scores:
  comp_count_score    = ln(23)/ln(31) = 0.913
  consistency_score   = 1.0 - (0.182 * 1.2) = 0.782
  brand_score         = 0.90 (Tier 2: Patagonia)
  recency_score       = 1.0 - (2/100) = 0.98
  match_quality_score = 0.88

Confidence = (0.30*0.913 + 0.25*0.782 + 0.15*0.90 + 0.15*0.98 + 0.15*0.88) * 100
           = (0.274 + 0.196 + 0.135 + 0.147 + 0.132) * 100
           = 88.4

Result: HIGH CONFIDENCE (88/100)
```

---

## 4. Price Range Calculation

### 4.1 Computing Low / Median / High

**Percentile-Based Approach (recommended):**

```
Low Estimate:   10th percentile of comp prices
Median Estimate: 50th percentile (median) of comp prices
High Estimate:  90th percentile of comp prices
```

**Why Percentiles Over Standard Deviation:**

| Approach | Pros | Cons |
|----------|------|------|
| Percentile (P10/P50/P90) | No distribution assumptions; bounds always within observed data; intuitive ("10% sold below this") | Requires enough data points; can be jumpy with small samples |
| Mean +/- 1 StdDev | Works well for normal distributions; smooth | Resale data is rarely normal; bounds can fall below $0 or above max observed; misleading with skewed data |
| Mean +/- 1.5 StdDev | Wider range, captures more | Same problems as above, even wider ranges |

Percentiles are superior for resale data because:
1. Resale prices are almost always right-skewed (a few high-value sales pull the mean up)
2. Percentiles are bounded by actual observed data (no impossible negative prices)
3. They are intuitive for users: "Most similar items sell for $35-$65, with a typical price of $49"

### 4.2 Handling Small Sample Sizes

When comp count is low, percentile estimates become unreliable. Adaptive strategy:

```
if comp_count >= 20:
    low  = percentile(prices, 10)
    mid  = percentile(prices, 50)
    high = percentile(prices, 90)

elif comp_count >= 10:
    low  = percentile(prices, 15)
    mid  = percentile(prices, 50)
    high = percentile(prices, 85)

elif comp_count >= 5:
    low  = percentile(prices, 20)
    mid  = percentile(prices, 50)
    high = percentile(prices, 80)

elif comp_count >= 3:
    low  = min(prices)
    mid  = median(prices)
    high = max(prices)
    # Add caveat: "Based on limited data"

else:
    # Do not display range; show "insufficient data"
```

The narrower percentile windows for larger datasets prevent extreme outliers from defining the range, while smaller datasets use wider windows (or full range) to avoid overstating precision.

### 4.3 Applying Recency-Weighted Percentiles

For the most accurate ranges, combine percentile calculation with recency weighting:

```
Weighted Percentile Algorithm:

1. Sort comps by price ascending
2. Assign weights (using exponential decay by recency)
3. Normalize weights to sum to 1.0
4. Compute cumulative weight sum
5. P10 = price where cumulative weight reaches 0.10
6. P50 = price where cumulative weight reaches 0.50
7. P90 = price where cumulative weight reaches 0.90
```

### 4.4 Presenting Ranges to Users

**Best Practices:**

1. **Always show three numbers:** Low, Typical, and High
2. **Use "Typical" not "Average":** Users understand "typical" better than statistical jargon
3. **Round to nearest dollar** for prices under $100; nearest $5 for prices $100-$500; nearest $10 for prices $500+
4. **Show as a visual range bar** with the typical price marked prominently
5. **Include context:** "Based on X similar items sold on eBay in the last 90 days"
6. **Never show ranges wider than 5x** (if High > 5 * Low, widen the trim or add caveats)

**User-Facing Display Format:**
```
+--------------------------------------------------+
|  Quick Flip        Typical Price        Top Dollar |
|    $35           >>>  $49  <<<             $65     |
|  [==========|=============|==============]        |
|                                                    |
|  Based on 22 recent eBay sales                    |
|  Confidence: HIGH (88/100)                        |
+--------------------------------------------------+
```

**Alternative simpler format:**
```
Estimated Resale Value: $49
Range: $35 - $65
Confidence: High | 22 comps
```

### 4.5 What About Profit Estimation?

Since ThriftFlip users are scanning items at thrift stores, showing estimated profit is high value:

```
Thrift store price:     (scanned from tag or user-entered)
eBay selling fees:      13.25% final value fee (most categories)
Shipping estimate:      Based on item category weight
                        Clothing: ~$6-8 USPS Priority
                        Shoes: ~$10-14 USPS Priority
                        Heavy items: ~$12-18

Estimated profit = Typical Price - Thrift Price - eBay Fees - Shipping

Display:
  "Buy for $5.99 -> Sell for ~$49 -> Estimated Profit: ~$34"
```

---

## 5. Recommended ThriftFlip Implementation

### 5.1 Architecture Overview

```
[Camera/Tag Scan] -> [Text Extraction (OCR)]
       |
       v
[Brand + Item Identification]
       |
       v
[eBay API Query Builder]
  - Construct search: "{brand} {item_type} {size} {keywords}"
  - Filter: sold items, last 90 days, single-quantity
       |
       v
[Comp Collection & Filtering]
  - Step 1: Keyword-based outlier removal
  - Step 2: Price floor/ceiling removal
  - Step 3: IQR statistical outlier removal
  - Step 4: Condition alignment
       |
       v
[Price Calculation Engine]
  - Apply recency weights (exponential decay, lambda=0.03)
  - Apply condition weights
  - Apply size weights
  - Compute weighted trimmed mean (15% trim)
  - Compute weighted percentiles (P10, P50, P90)
       |
       v
[Confidence Scoring]
  - Compute 5-factor weighted score (0-100)
  - Assign confidence tier (High/Medium/Low/Insufficient)
       |
       v
[User Display]
  - Low / Typical / High range
  - Confidence indicator
  - Number of comps
  - Estimated profit calculation
  - Seasonal context notes (if applicable)
```

### 5.2 Key Constants and Configuration

```swift
// MARK: - Pricing Engine Configuration

struct PricingConfig {
    // Outlier Filtering
    static let excludedKeywords = ["lot", "bundle", "wholesale", "parts",
        "repair", "damaged", "broken", "stain", "as-is", "for parts",
        "read description", "salvage"]
    static let priceFloor: Double = 2.00
    static let priceCeilingMultiplier: Double = 5.0  // 5x median
    static let iqrMultiplier: Double = 1.5

    // Recency Weighting
    static let decayLambda: Double = 0.03  // Exponential decay rate
    static let maxDaysOld: Int = 90

    // Trimmed Mean
    static let trimPercentage: Double = 0.15  // 15% from each end

    // Confidence Weights
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

    // eBay Fees
    static let ebayFinalValueFeePercent: Double = 0.1325  // 13.25%
    static let defaultShippingCost: Double = 7.50

    // Percentile Ranges
    static let lowPercentile: Double = 10.0
    static let midPercentile: Double = 50.0
    static let highPercentile: Double = 90.0
}
```

### 5.3 Brand Tier Database (Starter List)

```
TIER 1 - Luxury/Designer (brand_score = 1.00):
  Gucci, Louis Vuitton, Chanel, Prada, Burberry, Hermes, Dior,
  Balenciaga, Versace, Fendi, Saint Laurent, Valentino, Givenchy,
  Bottega Veneta, Celine, Moncler, Tom Ford, Alexander McQueen

TIER 2 - Premium/Athletic (brand_score = 0.90):
  Lululemon, Patagonia, The North Face, Arc'teryx, Nike, Adidas,
  Jordan, New Balance, Carhartt, Ralph Lauren, Tommy Hilfiger,
  Vineyard Vines, Free People, Anthropologie, Reformation,
  AllSaints, Ted Baker, Hugo Boss, Coach

TIER 3 - Mainstream/Known (brand_score = 0.75):
  Levi's, J.Crew, Banana Republic, Gap, Zara, H&M, Madewell,
  American Eagle, Abercrombie, Under Armour, Columbia, Eddie Bauer,
  Calvin Klein, Michael Kors, DKNY, Guess, Express

TIER 4 - Value/Budget (brand_score = 0.55):
  Old Navy, Target brands (Cat & Jack, A New Day, Universal Thread,
  Goodfellow), Shein, Forever 21, Primark, Walmart brands
  (George, Time and Tru), Uniqlo

TIER 5 - Unknown/Private Label (brand_score = 0.30):
  Any brand not in the database
```

### 5.4 Seasonal Adjustment Table

```
Monthly seasonal indices by category (1.0 = annual average):

Category          Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec
Winter Outerwear  1.30  1.15  0.85  0.70  0.65  0.60  0.60  0.70  0.90  1.20  1.35  1.40
Sweaters/Knits    1.20  1.10  0.90  0.75  0.70  0.65  0.65  0.75  0.95  1.15  1.25  1.30
Swimwear          0.60  0.65  0.85  1.15  1.35  1.40  1.35  1.10  0.80  0.65  0.55  0.55
Summer Dresses    0.70  0.75  0.90  1.15  1.30  1.35  1.25  1.05  0.85  0.70  0.65  0.65
Boots             1.15  1.00  0.85  0.70  0.65  0.60  0.65  0.80  1.10  1.30  1.30  1.20
Sandals           0.55  0.60  0.80  1.15  1.35  1.40  1.35  1.10  0.85  0.65  0.55  0.55
Athleisure        1.15  1.10  1.05  1.00  1.00  0.95  0.90  0.95  1.00  1.00  0.95  0.95
Basics/Year-Round 1.00  1.00  1.00  1.00  1.00  1.00  1.00  1.00  1.00  1.00  1.00  1.00
Denim             1.00  0.95  0.95  0.95  0.95  0.90  0.90  1.00  1.10  1.10  1.10  1.05
Formal/Suits      0.90  0.90  1.05  1.15  1.20  1.15  0.95  0.85  0.90  1.00  1.00  0.95
```

Note: These indices are estimated from general retail seasonality data and resale market observations. They should be validated and refined with actual eBay sold data over a full 12-month period.

### 5.5 Complete Pricing Pipeline (Pseudocode)

```python
def estimate_resale_price(brand, item_type, size, condition, category):
    """
    Main pricing pipeline for ThriftFlip.
    Returns: PriceEstimate(low, typical, high, confidence_score, confidence_tier, comp_count)
    """

    # Step 1: Query eBay for sold comps
    query = build_search_query(brand, item_type, size)
    raw_comps = ebay_api.search_sold_items(
        query=query,
        days_back=90,
        single_quantity_only=True
    )

    # Step 2: Filter outliers
    comps = filter_excluded_keywords(raw_comps, EXCLUDED_KEYWORDS)
    comps = filter_multi_quantity(comps)

    if len(comps) < 3:
        return PriceEstimate.insufficient_data()

    prices = [c.sold_price for c in comps]
    median_price = median(prices)

    # Price floor/ceiling
    comps = [c for c in comps if c.sold_price >= 2.00]
    comps = [c for c in comps if c.sold_price <= median_price * 5.0]

    # IQR filtering
    q1 = percentile(prices, 25)
    q3 = percentile(prices, 75)
    iqr = q3 - q1
    lower_bound = q1 - (1.5 * iqr)
    upper_bound = q3 + (1.5 * iqr)
    comps = [c for c in comps if lower_bound <= c.sold_price <= upper_bound]

    if len(comps) < 3:
        return PriceEstimate.insufficient_data()

    # Step 3: Apply weights
    for comp in comps:
        days_old = (today - comp.sold_date).days
        recency_w = exp(-0.03 * days_old)
        condition_w = condition_weight(comp.condition, target_condition=condition)
        size_w = size_weight(comp.size, target_size=size)
        comp.weight = recency_w * condition_w * size_w

    # Step 4: Calculate weighted trimmed mean
    comps_sorted = sorted(comps, key=lambda c: c.sold_price)
    trim_count = int(len(comps_sorted) * 0.15)
    trimmed = comps_sorted[trim_count : len(comps_sorted) - trim_count] if trim_count > 0 else comps_sorted

    total_weight = sum(c.weight for c in trimmed)
    weighted_mean = sum(c.sold_price * c.weight for c in trimmed) / total_weight

    # Step 5: Calculate price ranges (weighted percentiles)
    prices_clean = [c.sold_price for c in comps]
    n = len(prices_clean)

    if n >= 20:
        low  = weighted_percentile(comps, 0.10)
        high = weighted_percentile(comps, 0.90)
    elif n >= 10:
        low  = weighted_percentile(comps, 0.15)
        high = weighted_percentile(comps, 0.85)
    elif n >= 5:
        low  = weighted_percentile(comps, 0.20)
        high = weighted_percentile(comps, 0.80)
    else:
        low  = min(prices_clean)
        high = max(prices_clean)

    typical = weighted_mean

    # Step 6: Calculate confidence score
    cv = stdev(prices_clean) / mean(prices_clean)
    days_since_last = min(c.days_old for c in comps)
    avg_match_quality = mean(c.match_quality for c in comps)

    comp_count_score = min(1.0, log(n + 1) / log(31))
    consistency_score = clamp(1.0 - (cv * 1.2), 0.1, 1.0)
    brand_score = get_brand_tier_score(brand)
    recency_score = clamp(1.0 - (days_since_last / 100), 0.1, 1.0)
    match_score = avg_match_quality

    confidence = (
        0.30 * comp_count_score +
        0.25 * consistency_score +
        0.15 * brand_score +
        0.15 * recency_score +
        0.15 * match_score
    ) * 100

    # Step 7: Determine confidence tier
    if confidence >= 80:
        tier = "HIGH"
    elif confidence >= 55:
        tier = "MEDIUM"
    elif confidence >= 30:
        tier = "LOW"
    else:
        tier = "INSUFFICIENT"

    # Step 8: Apply seasonal adjustment (optional Phase 2)
    # seasonal_factor = get_seasonal_factor(category, current_month)
    # typical *= seasonal_factor
    # low *= seasonal_factor
    # high *= seasonal_factor

    return PriceEstimate(
        low=round_price(low),
        typical=round_price(typical),
        high=round_price(high),
        confidence_score=round(confidence),
        confidence_tier=tier,
        comp_count=n,
        median=median(prices_clean),
        mean=mean(prices_clean)
    )
```

---

## Sources

### Platform Pricing Research
- [StockX Math Class: Sneakerhead Statistics Defined](https://stockx.com/news/math-class-sneakerhead-statistics-defined/)
- [StockX Pricing Guidance Updates](https://stockx.com/news/pricing-guidance-updates/)
- [StockX Market Insights](https://stockx.com/about/market-insights/)
- [StockX Price Premium Predictive Analysis (GitHub)](https://github.com/danielle707/StockX-Predictive-Modeling)
- [Predicting StockX Sneaker Prices With Machine Learning](https://medium.com/swlh/predicting-stockx-sneaker-prices-with-machine-learning-ec9cb625bec0)
- [Poshmark PoshFest 2025: Price Suggestions & Updates](https://www.valueaddedresource.net/poshmark-poshfest-2025-hackathon/)
- [Poshmark Pricing Strategy (2025)](https://www.exportyourstore.com/blog/poshmark-pricing-strategy)
- [Poshmark Algorithm Guide 2026](https://closetassistantpm.com/poshmark-algorithm/)
- [eBay Product Research / Terapeak](https://www.ebay.com/help/selling/selling-tools/terapeak-research?id=4853)
- [Terapeak Research 2.0 Overview (eBay Innovation)](https://innovation.ebayinc.com/stories/new-improved-terapeak-research-2-0-in-ebay-seller-hub/)
- [How To Use Terapeak For eBay](https://mywifequitherjob.com/how-to-use-terapeak/)
- [How to Use eBay Terapeak (LitCommerce)](https://litcommerce.com/blog/ebay-terapeak/)
- [ThredUp Clean Out Earnings](https://www.thredup.com/cleanout/earnings)
- [ThredUp Fees Explained](https://help.thredup.com/en_us/how-do-thredups-fees-work-H106jQyih)
- [ThredUp Luxe Payout Structure](https://cf-assets-tup.thredup.com/luxe/luxe_payout_structure.pdf)
- [ThredUp Payout Reviews](https://www.topbubbleindex.com/blog/thredup-payout-reviews/)
- [ShopGoodwill Proxy Bidding Help](https://shopgoodwill.com/help/faqdetail/automatic-proxy-bidding)

### Comp-Based Pricing & Statistical Methods
- [eBay Marketplace Insights API Overview](https://developer.ebay.com/api-docs/buy/marketplace-insights/static/overview.html)
- [eBay Marketplace Insights API: ItemSales](https://developer.ebay.com/api-docs/buy/marketplace-insights/types/sal:ItemSales)
- [eBay Finding API: findCompletedItems](https://developer.ebay.com/devzone/finding/callref/findCompletedItems.html)
- [eBay Sold Items API Documentation (GitHub)](https://github.com/colindaniels/eBay-sold-items-documentation)
- [eBay Market Analyzer (GitHub)](https://github.com/driscoll42/ebayMarketAnalyzer)
- [eBay Price Predictor (GitHub)](https://github.com/NathanZorndorf/ebay-price-predictor)
- [How To View Sold Listings on eBay: Lessons from 4,000+ Items (CLOSO)](https://closo.co/blogs/casestudies/how-to-view-sold-listings-on-ebay-what-i-learned-after-pricing-4-000-items-using-sold-data)
- [Competitive Pricing Strategies for eBay](https://blog.reeva.ai/resources/competitive-pricing-strategies-for-ebay/)
- [Applying Comparable Sales Method to Automated Estimation (MDPI)](https://www.mdpi.com/2071-1050/12/14/5679)
- [Fannie Mae B4-1.3-08: Comparable Sales Guidelines](https://selling-guide.fanniemae.com/sel/b4-1.3-08/comparable-sales)
- [Truncated Mean (Wikipedia)](https://en.wikipedia.org/wiki/Truncated_mean)
- [When to Use a Trimmed Mean (Medium)](https://hollyemblem.medium.com/when-to-use-a-trimmed-mean-fd6aab347e46)
- [Trimmed Mean: Definition & Benefits (Statistics By Jim)](https://statisticsbyjim.com/basics/trimmed-mean/)
- [IQR Method for Outlier Detection (ProCogia)](https://procogia.com/interquartile-range-method-for-reliable-data-analysis/)
- [Interquartile Range to Detect Outliers (GeeksforGeeks)](https://www.geeksforgeeks.org/machine-learning/interquartile-range-to-detect-outliers-in-data/)

### Recency Weighting & Time Decay
- [Recency-Weighted Scoring Explained (Customers.ai)](https://customers.ai/recency-weighted-scoring)
- [The Math of Weighting Past Results (Fangraphs)](https://tht.fangraphs.com/the-math-of-weighting-past-results/)
- [Time Decay Attribution Model (RedTrack)](https://www.redtrack.io/blog/time-decay-attribution-model/)

### Seasonal Pricing
- [Seasonal Effects on Clothing Sales (Seth Society)](https://www.sethsociety.com/blogs/news/seasonal-effects-on-clothing-sales)
- [Master Seasonality in Apparel eCommerce](https://www.efulfillmentservice.com/2024/07/master-seasonality-in-apparel-ecommerce-like-a-pro/)
- [Seasonal Pricing Strategy (FasterCapital)](https://fastercapital.com/content/Seasonal-pricing--How-to-vary-your-prices-according-to-the-changes-in-demand-and-supply-throughout-the-year.html)
- [Seasonal Fashion Buying Habits Statistics 2025](https://bestcolorfulsocks.com/blogs/news/seasonal-fashion-buying-habits-statistics)

### Brand Tiers & Resale Value
- [Art & Science of Fashion Resale: Brand Tiers (Upright Labs)](https://www.uprightlabs.com/2025/06/30/the-art-science-of-fashion-resale-identifying-luxury-vintage-and-brand-tiers/)
- [Analyzing Resale Value Trends of Top Designer Labels (TheRealReal)](https://realstyle.therealreal.com/analyzing-resale-value-top-designers/)
- [Vintage Pricing Guide for Resellers (Curio)](https://www.curio.app/blog/vintage-pricing-guide)
- [What Sells Fastest on Poshmark in 2025 (CLOSO)](https://closo.co/blogs/data-driven-insights-market-analytics/what-sells-fastest-on-poshmark-in-2025-trends-tips-data-driven-insights)

### AI/ML Pricing Research
- [AI Pipeline for Garment Price Projection Using Computer Vision (ResearchGate)](https://www.researchgate.net/publication/380665098_An_AI_pipeline_for_garment_price_projection_using_computer_vision)
- [Demand Forecasting New Fashion Products (Wiley)](https://onlinelibrary.wiley.com/doi/10.1002/for.3192)
- [Dynamic Pricing Algorithms 2026 (AIMultiple)](https://research.aimultiple.com/dynamic-pricing-algorithm/)
- [Algorithmic Pricing: Implications (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S0167811625000473)
