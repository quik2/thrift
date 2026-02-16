# ThriftFlip: Data Sources & API Research Report
**Date: February 16, 2026**

---

## Table of Contents
1. [eBay APIs](#1-ebay-apis)
2. [Web Scraping Alternatives](#2-web-scraping-alternatives)
3. [Barcode and Product Databases](#3-barcode-and-product-databases)
4. [Visual Search APIs](#4-visual-search-apis)
5. [Pricing Data Aggregators](#5-pricing-data-aggregators)
6. [MVP Recommendation](#6-practical-mvp-recommendation)

---

## 1. eBay APIs

### 1.1 Browse API

**Status:** Active, primary eBay search API
**Base URL:** `GET https://api.ebay.com/buy/browse/v1/item_summary/search`

**Available Endpoints:**
- `search` - Search for items by keyword, GTIN, category, ePID, or image
- `getItem` - Get details for a specific item
- `getItems` - Get details for multiple items
- `getItemByLegacyId` - Get item by legacy item ID
- `searchByImage` - Search using an image (relevant for ThriftFlip)

**Key Capabilities:**
- Keyword and category-based search
- Filter by condition, price range, location, listing format
- Filter by UPC/GTIN values
- Image-based search (searchByImage endpoint)
- Returns: title, price, condition, images, seller info, item URL, category

**CRITICAL LIMITATION: The Browse API does NOT support searching sold/completed listings.** It only returns active (current) listings. Only FIXED_PRICE (Buy It Now) items are returned by default. There is no filter or workaround to get historical sold prices through this API.

**Rate Limits:**
- Default: 5,000 calls/day per application
- After Application Growth Check: up to 1,500,000 calls/day
- Rate limit is application-level, not per-user

**Cost:** Free (no per-call charges), but requires eBay Developer Program account

**Authentication:** OAuth 2.0. The Browse API search endpoint supports client credentials grant (application token), which is simpler - no user login required for basic searches.

### 1.2 Finding API (findCompletedItems)

**Status: DECOMMISSIONED as of February 5, 2025**

The Finding API, including the `findCompletedItems` call, has been permanently shut down. This was the primary way developers accessed sold listing data.

**What it used to return:**
- Completed/sold item titles, prices, dates
- Selling status (sold vs. unsold)
- Item condition, category, seller info
- Up to 5,000 calls/day

**This is no longer an option.** The replacement is the Marketplace Insights API (see below).

### 1.3 Marketplace Insights API (Replacement for findCompletedItems)

**Status:** Active but RESTRICTED ACCESS (Limited Release)
**Base URL:** `GET https://api.ebay.com/buy/marketplace_insights/v1_beta/item_sales/search`

**This is the single best official eBay API for getting sold listing data with prices.** However, it is gated behind an approval process.

**What it returns (ItemSales type):**
- Sold price of items (actual transaction price)
- Total sold quantity
- Item title, ID, images, URLs
- Item location (postal code, country)
- Number of bids (auction items)
- Purchase options (FIXED_PRICE, AUCTION, BEST_OFFER)
- Seller feedback score and username
- Last 90 days of sales history
- Maximum 10,000 items per query

**Search capabilities:**
- Search by keyword, GTIN, ePID (eBay Product ID), category
- Filter by date range, price range, condition

**Access Requirements:**
- Limited Release API - only available to select developers approved by eBay business units
- Must apply through eBay Developer Portal with a detailed use case explanation
- Must meet Buy APIs Requirements (eligibility, approvals, and contracts)
- Approval is NOT guaranteed and many developers report being denied
- eBay support reviews applications on a case-by-case basis

**How to apply:** Contact eBay developer support through the developer portal, clearly state your use case and business model. Explain how you will comply with data use restrictions.

### 1.4 Terapeak / Product Research

**Status:** No API exists. UI-only access.

Terapeak (now rebranded as "Product Research" within eBay Seller Hub) provides:
- 3 years of actual sold data
- Real accepted prices on "Best Offer" listings
- Market trends and demand analysis

**There is no Terapeak API.** The data is only accessible through:
- eBay Seller Hub web interface (Research tab)
- eBay Mobile App (Product Research feature added in 2025/2026)

There is no programmatic way to access Terapeak data. The closest alternative is the Marketplace Insights API.

### 1.5 eBay Partner Network (Affiliate Program)

**Commission:** Up to 4% of item sale price for qualifying transactions

**API Access:** Partners use the same Browse API but with a Campaign ID appended. Affiliate status does NOT grant access to sold listing data. The Marketplace Insights API remains restricted to approved partner-level developers.

**Verdict:** Not useful for price estimation data. Only useful if ThriftFlip generates eBay referral traffic.

### 1.6 Authentication Requirements Summary

All eBay REST APIs use **OAuth 2.0**:

| Grant Type | Token Type | Use Case |
|---|---|---|
| Client Credentials | Application Token | Browse API search, public data |
| Authorization Code | User Token | Marketplace Insights, seller-specific data |

**Steps to get started:**
1. Create eBay Developer Program account (free)
2. Register your application to get App ID, Dev ID, Cert ID
3. Generate OAuth credentials (client ID + client secret)
4. Request appropriate scopes for your tokens
5. For Marketplace Insights: apply for access separately

### 1.7 Data Use Restrictions (IMPORTANT)

As of June 24, 2025, eBay updated their API License Agreement with critical restrictions:

- **NO AI/ML training:** Developers are prohibited from using eBay Content to train algorithms, conduct machine learning, develop synthetic data sets, train large language models, or train AI systems
- **NO commercialization of data:** Cannot sell, rent, trade, distribute, lease, or commercialize eBay Content
- **NO data storage beyond API caching rules**
- **Production use requires:** Meeting eligibility requirements, getting approvals, and signing contracts with eBay

**Impact on ThriftFlip:** Using eBay data to build a pricing model may violate the API License Agreement if it involves training ML models on eBay pricing data. Real-time lookups (query eBay, show results) are likely permissible. Building a cached price database from eBay data is likely NOT permissible. This is a significant legal consideration.

---

## 2. Web Scraping Alternatives

### 2.1 Legal Status of eBay Scraping

**eBay explicitly prohibits web scraping** in their User Agreement. Their terms prohibit using "any robot, spider, scraper, data mining tools, data gathering and extraction tools, or other automated means to access their services without prior express permission."

**Legal precedent:** In eBay v. Bidder's Edge (2000), the court issued an injunction against Bidder's Edge for scraping eBay without authorization.

**February 2026 update:** eBay updated their User Agreement to explicitly address AI agents and automated buying tools.

**Risk assessment:** Using scraping for a commercial product (ThriftFlip) carries real legal risk including account bans, cease-and-desist letters, and potential litigation. However, many businesses operate in this gray area using third-party intermediary services.

### 2.2 Apify eBay Scrapers

**Several purpose-built eBay sold listing scrapers exist on Apify:**

#### eBay Sold Listings Intelligence (marielise.dev)
- **URL:** `apify.com/marielise.dev/ebay-sold-listings-intelligence`
- **Pricing:** $25.00 per 1,000 results (Pay Per Event)
- **Rating:** 5.0 stars
- **Returns:** Average/median sold prices, days to sell, market demand, recommended listing price, condition impact analysis
- **Best for:** Pricing research and analytics

#### eBay Sold Listings API (caffein.dev)
- **URL:** `apify.com/caffein.dev/ebay-sold-listings`
- **Returns:** Normalized sale price, currency, end date, title, URL, item ID
- **Format:** JSON/CSV export
- **Best for:** Raw sold data collection

#### eBay Items Scraper (dtrungtin)
- **URL:** `apify.com/dtrungtin/ebay-items-scraper`
- **General purpose:** Active + completed listings
- **Pricing:** ~$2 per 1,000 results

#### eBay Scraper PPR (3x1t)
- **URL:** `apify.com/3x1t/ebay-scraper-ppr`
- **Pay Per Result model**

**Apify Platform Pricing:**
- Free tier: $5/month in platform credits
- Starter Plan: $39/month ($0.40/compute unit)
- Scale Plan: $199/month ($0.25/compute unit)
- Additional compute units: $0.25-$0.40 each
- Most eBay scrapers charge additional per-result fees

**For 1,000 scans/day using Apify:**
- Using marielise.dev scraper: ~$750/month (assuming 50 results per scan for price averaging = 50,000 results/day = 1.5M/month at $25/1K)
- Using caffein.dev: Likely similar cost range
- Using dtrungtin general scraper: ~$60/month for raw data (1,000 queries/day = 30K results at $2/1K)
- Plus platform compute costs: $39-199/month

### 2.3 SERP API Services (Indirect Scraping)

These services scrape eBay search results pages (including sold listings if filterable via URL parameters):

#### SerpApi
- **eBay Search Engine Results API:** Scrapes eBay seller listings
- **Pricing:** $75/month for 5,000 searches
- **LIMITATION:** As of August 2025, SerpApi does NOT support eBay sold listing type scraping (feature frozen on roadmap)

#### SearchAPI.io
- **eBay Search API available**
- **100 free requests** to start
- **Paid plans:** From $40/month
- **Cost:** ~$4-8 per 1,000 requests
- **Sold listings support:** Not confirmed

### 2.4 Proxy Services

#### Oxylabs
- Web Scraper API: Starting at $49/month
- Web Unblocker: $9.40/GB
- Residential proxies: $4-10/GB
- eBay Scraper API available (dedicated)
- 99.95% average success rate, 0.6s response times

#### Bright Data
- E-Commerce Scraper API available
- Entry plan: $499/month (71 GB traffic)
- Pre-built eBay datasets available
- Vestiaire Collective datasets also available

### 2.5 Unofficial eBay Sold Items API (Community)

A community-documented API exists (documented by Colin Daniels on GitHub):
- **Repo:** `github.com/colindaniels/eBay-sold-items-documentation`
- **Method:** POST requests that scrape eBay.com sold listings
- **Returns:** Total results, average price, min/max price, individual product data
- **Parameters:** Keywords, excluded phrases, category ID, max results (25/50/100/200)
- **Risk:** Unofficial, could break at any time, violates ToS

---

## 3. Barcode and Product Databases

### 3.1 Do Thrift Store Clothes Have Scannable Barcodes?

**The short answer: Usually not in a useful way.**

- Most thrift stores use simple price gun tags (colored stickers, handwritten tags)
- Some modern thrift chains (Goodwill, Salvation Army) use internal barcode systems, but these are store-specific inventory codes, NOT UPC/product codes
- Original manufacturer UPC barcodes are sometimes still on clothing hang tags, but:
  - Many clothes arrive at thrift stores without original tags
  - UPC coverage for clothing is inconsistent (fast fashion brands often don't use UPC on individual garments)
  - Vintage/secondhand items almost never have intact UPC tags

**Implication for ThriftFlip:** Barcode scanning alone will NOT be reliable for clothing identification at thrift stores. The app should primarily rely on visual recognition (camera/OCR of brand labels, care tags, RN numbers) rather than barcode scanning.

### 3.2 UPC/Barcode Database APIs

If barcodes ARE present, these services can look them up:

| Service | Database Size | Pricing | API |
|---|---|---|---|
| **Go-UPC** | 1 billion+ items | Paid plans (pricing on request) | REST/JSON |
| **Barcode Lookup** | Large | Paid API | REST, returns name/category/price/photos |
| **UPCitemdb** | Large | Free tier + paid | REST/JSON |
| **EANdata** | Large | Free + paid | REST |
| **UPC-Search.org** | 170M UPC + 1B EAN | Free lookups | Limited API |
| **UPC Database** | Large | Free tier | REST |

**Clothing coverage is poor across all these databases.** They work best for electronics, packaged goods, and branded retail products. Clothing, especially thrift/vintage, has very low hit rates.

### 3.3 Google Shopping / Merchant API

**Status:** Content API for Shopping sunsetting August 18, 2026. Replaced by Merchant API.

**NOT useful for ThriftFlip.** The Google Shopping API is designed for merchants to manage their OWN product catalogs, not to search Google Shopping for product data. It requires a Google Merchant Center account and is for uploading/managing product feeds, not for price lookup.

**Alternative:** Google's Vision API Product Search (see Visual Search section) allows image-based product matching against a custom catalog.

### 3.4 FTC RN Number Database

**What it is:** The FTC Registered Identification Number (RN) database identifies U.S. textile manufacturers, importers, and distributors. RN numbers are found on clothing care labels.

**Access:**
- Web interface: `rn.ftc.gov/Account/BasicSearch`
- Search by RN number, company name, or legal business name
- **NO public API exists** - web-only access
- Recent changes (2025) require account creation for some features

**What it returns:** Company name, business type (manufacturer/importer/distributor), address

**Usefulness for ThriftFlip:** HIGH for brand identification. If ThriftFlip can OCR the RN number from a care label, it can identify the manufacturer. Combined with "brand name + category" search terms, this enables more precise eBay price lookups. However, without an API, you would need to either scrape the FTC website or build a local lookup table of common RN numbers.

**Practical approach:** Build a static lookup table of the top 500-1000 most common RN numbers mapped to brand names. The FTC database only has ~tens of thousands of entries total.

---

## 4. Visual Search APIs

### 4.1 Google Cloud Vision API

**Best option for general clothing identification.**

**Relevant Features:**
| Feature | Price per 1,000 units | Free Tier |
|---|---|---|
| Label Detection | $1.50 | 1,000/month free |
| Logo Detection | $1.50 | 1,000/month free |
| Text Detection (OCR) | $1.50 | 1,000/month free |
| Web Detection | $3.50 | 1,000/month free |
| Object Localization | $2.25 | 1,000/month free |
| Product Search | Custom pricing | N/A |

**For ThriftFlip, the most useful features are:**
1. **Text Detection (OCR):** Read brand names, RN numbers, size, care labels from clothing tags ($1.50/1K)
2. **Label Detection:** Identify clothing type (shirt, dress, jacket) ($1.50/1K)
3. **Logo Detection:** Identify brand logos on clothing ($1.50/1K)
4. **Web Detection:** Find visually similar items on the web ($3.50/1K)

**Style Detection** is a specialized Google Vision feature for evaluating fashion/style nuances.

**Cost for 1,000 scans/day (30K/month):**
- OCR only: ~$43.50/month
- OCR + Label Detection: ~$87/month
- Full suite (OCR + Label + Logo + Web): ~$261/month

### 4.2 Amazon Rekognition

**DetectLabels API** can identify clothing and apparel items.

**Supported clothing labels:** Backpack, Belt, Blouse, Hoodie, Jacket, Shoe, Pants, Dress, Coat, Hat, Gloves, etc.

**Pricing:**
- Free tier: 1,000 images/month for first 12 months
- Tier 1 (first 1M images/month): $1.00 per 1,000 images ($0.001/image)
- Tier 2 (1M-10M): $0.80 per 1,000
- Tier 3 (10M-100M): $0.60 per 1,000

**Cost for 1,000 scans/day (30K/month):** ~$30/month

**Pros:** Cheapest cloud vision option, good clothing label coverage
**Cons:** Less fashion-specific than Google Vision, no OCR for tag reading (need Amazon Textract separately)

### 4.3 Clarifai

**Dedicated apparel models available:**
- `apparel-recognition` - Identifies fashion items, clothing, hats, jewelry, handbags
- `apparel-classification-v2` - Classifies apparels and accessories

**Pricing:**
| Plan | Monthly Cost | API Calls/Month | Per-Call Cost |
|---|---|---|---|
| Free | $0 | 1,000 | Free |
| Essential | $30 | 30,000 | $0.001 |
| Professional | $300 | 100,000 | $0.003 |

**Cost for 1,000 scans/day (30K/month):** $30/month (Essential plan)

**Pros:** Fashion-specific models out of the box, good accuracy for clothing classification
**Cons:** Limited free tier, less versatile than Google Vision for OCR

### 4.4 Open-Source Models (Best for Cost Optimization)

#### FashionCLIP (Original)
- **Repo:** `github.com/patrickjohncyh/fashion-clip`
- **HuggingFace:** `patrickjohncyh/fashion-clip`
- **Architecture:** ViT-B/32 CLIP fine-tuned on 800K Farfetch products
- **Training data:** 800K products, 3K+ brands, dozens of object types
- **Use case:** Text-to-image and image-to-text matching for fashion

#### Marqo-FashionCLIP (RECOMMENDED - Best Performance)
- **HuggingFace:** `Marqo/marqo-fashionCLIP`
- **Performance:** +57% improvement over FashionCLIP 2.0 on evaluation metrics
- **Uses Generalised Contrastive Learning (GCL):** Trained on categories, style, colors, materials, keywords, fine details
- **10% faster inference** than comparable models
- **Benchmarked on 7 datasets:** Atlas, DeepFashion, Fashion200k, iMaterialist, KAGL, Polyvore

#### OpenFashionCLIP
- **Repo:** `github.com/aimagelab/open-fashion-clip`
- **Training data:** 1,147,929 image-text pairs (larger than FashionCLIP)
- **Fully open-source training data**

#### CLIP (Base Model)
- **By OpenAI, various implementations (OpenCLIP)**
- **General purpose but decent for clothing**
- **Can be used for zero-shot classification**

**Cost:** FREE to run. Requires your own compute:
- On-device (iOS): CoreML conversion, runs on iPhone Neural Engine (~50-100ms per inference)
- Cloud server: ~$0.50-2/hour GPU instance, handles thousands of requests/hour

**For ThriftFlip MVP:** Running Marqo-FashionCLIP on-device via CoreML would give clothing classification at ZERO marginal cost per scan. This is the most cost-effective approach for the visual identification component.

---

## 5. Pricing Data Aggregators

### 5.1 PriceCharting

**Does NOT cover clothing.** PriceCharting focuses on:
- Video games
- Trading cards (Pokemon, Yu-Gi-Oh, sports cards)
- Comics
- Strategy guides

Not useful for ThriftFlip.

### 5.2 StockX / GOAT (Sneakers & Streetwear)

#### StockX
- **Developer Portal:** `developer.stockx.com`
- **Status:** Semi-public API, must request access
- **Coverage:** Sneakers, streetwear, electronics, collectibles
- **Data:** Real-time pricing, bid/ask, historical sales

#### GOAT
- **No official public API**
- **Third-party access via KicksDB**

#### KicksDB (Unified Sneaker API)
- **URL:** `kicks.dev`
- **Coverage:** StockX, GOAT, Flight Club, Shopify stores
- **Pricing:**

| Plan | Monthly Cost | Requests/Month | Markets |
|---|---|---|---|
| Free | EUR 0 | 1,000 | US only |
| Starter | EUR 29 | 50,000 | All markets |
| Pro | EUR 79 | 250,000 | All markets + realtime |
| Enterprise | Custom | Custom | Custom |

- **Overage:** EUR 0.05 per 1,000 requests

**Usefulness for ThriftFlip:** Excellent for sneakers and streetwear (Nike, Jordan, Yeezy, Supreme, etc.) which are high-value thrift finds. Limited to footwear and streetwear categories.

### 5.3 Retailed.io (Multi-Marketplace Aggregator)

- **URL:** `retailed.io`
- **Coverage:** 30+ marketplaces including StockX, GOAT, Chrono24
- **Products:** 3,000,000+ product variants
- **Features:** Dynamic pricing, SKU/UPC matching, worldwide sizing data

**Pricing:**

| Plan | Monthly Cost | Credits | Cost per 1K Credits |
|---|---|---|---|
| Free Trial | $0 | 50 (one-time) | N/A |
| Premium | $49 | 18,000 | ~$2.72 |
| Premium+ | $99 | 40,000 | ~$2.48 |
| Startup | $249 | 110,000 | ~$2.26 |
| Enterprise+ | $999 | 530,000 | ~$1.89 |

- 1 credit = 1 standard API request
- 2 credits = 1 JavaScript rendering request
- Only pay for successful requests

**Usefulness for ThriftFlip:** Good for sneakers, watches, and streetwear. NOT comprehensive for general clothing.

### 5.4 Vestiaire Collective

**No official API.** Data accessible only via:
- Apify scrapers (web scraping)
- Bright Data datasets (pre-collected)
- Direct web scraping (terms-violating)

**Coverage:** Luxury/designer fashion (Gucci, Chanel, Louis Vuitton, etc.)

### 5.5 Existing Competitor Apps (Data Sources to Study)

Several apps in this space already exist and reveal possible data approaches:

- **ThriftAI** (iOS/Android): AI item recognition + live marketplace price comparison
- **Vintage-Snap.com:** AI-powered vintage clothing valuation, compares across eBay, Etsy, Grailed, Depop, Poshmark
- **Price Snap:** Resale value estimates with profit calculator, uses recently sold data from real marketplaces
- **WhatsitAI:** AI identification + market values from eBay, Etsy, Facebook Marketplace, Vinted

These competitors likely use a combination of scraping and API access to aggregate pricing data.

### 5.6 Clothing-Specific Price Databases

**There is no universal clothing price database API.** The closest options are:
- eBay Marketplace Insights API (restricted)
- Scraping eBay sold listings (legal risk)
- ThredUp Resale Report (annual report, not an API)
- "Price It Right!" software (360,000 items, consignment-focused, not an API)

---

## 6. Practical MVP Recommendation

### 6.1 Recommended MVP Architecture

```
[iPhone Camera]
    |
    v
[On-Device Processing]
  - Apple Vision/VisionKit OCR (FREE) --> extract brand, RN#, size from tag
  - CoreML FashionCLIP model (FREE) --> classify garment type + style
    |
    v
[Cloud API Layer]
  - Apify eBay Sold Listings Scraper --> get recent sold prices
  - OR eBay Browse API --> get active listing prices (as fallback)
    |
    v
[Price Estimation Logic]
  - Aggregate sold prices (median, average, range)
  - Adjust for condition
  - Display to user
```

### 6.2 Recommended Data Pipeline (Tiered Approach)

**Tier 1 - Primary (Best Data Quality):**
Apply for eBay Marketplace Insights API access. If approved, this gives you 90 days of sold data, which is the gold standard for price estimation.

**Tier 2 - Scraping Fallback (If Marketplace Insights denied):**
Use Apify's eBay sold listings scrapers. The caffein.dev or marielise.dev actors provide actual sold prices. Accept the ToS risk, but mitigate by not storing/caching data long-term and keeping request volumes reasonable.

**Tier 3 - Active Listings Fallback (Always Available):**
Use eBay Browse API (free, 5,000 calls/day) to search active listings. Active listing prices are less accurate than sold prices but provide a reasonable estimate. Available to all developers without special approval.

**Tier 4 - Category-Specific Enrichment:**
- Sneakers/streetwear: KicksDB free tier (1,000 requests/month) or Retailed.io
- Luxury brands: Manual brand multiplier tables based on known resale data

### 6.3 On-Device Processing (Zero Marginal Cost)

These components run entirely on the iPhone with no per-call API costs:

1. **Apple VisionKit Text Recognition:** Built into iOS, FREE, excellent OCR for reading text from clothing tags (brand name, RN number, size, fabric content)

2. **CoreML FashionCLIP Model:** Convert Marqo-FashionCLIP to CoreML format. Runs on Neural Engine. Classifies garment type, style, and can generate search terms. One-time engineering cost, zero marginal cost.

3. **Local RN Number Lookup Table:** Build a static dictionary of common RN numbers mapped to brand names. Load from bundled JSON file. Zero API cost.

4. **Apple barcode scanning (if available):** AVFoundation barcode detection is built into iOS. Won't work for most thrift items but costs nothing to include.

### 6.4 Cost Estimates for 1,000 Scans/Day

#### Option A: Cheapest Viable (Browse API Only)
| Component | Monthly Cost |
|---|---|
| On-device OCR + FashionCLIP | $0 |
| eBay Browse API (active listings) | $0 (within 5K/day limit) |
| **Total** | **$0/month** |
| **Accuracy:** | Low-Medium (active prices, not sold prices) |

#### Option B: Best Value (Apify Scraping)
| Component | Monthly Cost |
|---|---|
| On-device OCR + FashionCLIP | $0 |
| Apify eBay Sold Listings (50 comps/scan) | ~$750/month at $25/1K results |
| Apify platform (Starter) | $39/month |
| **Total** | **~$790/month** |
| **Accuracy:** | High (real sold prices) |

#### Option B-Lite: Budget Scraping (Fewer Comps)
| Component | Monthly Cost |
|---|---|
| On-device OCR + FashionCLIP | $0 |
| Apify eBay Sold Listings (10 comps/scan) | ~$150-250/month |
| Apify platform (Free) | $0 |
| **Total** | **~$150-250/month** |
| **Accuracy:** | Medium-High |

#### Option C: Premium (If Marketplace Insights Approved)
| Component | Monthly Cost |
|---|---|
| On-device OCR + FashionCLIP | $0 |
| Google Cloud Vision OCR (backup) | ~$43/month |
| eBay Marketplace Insights API | $0 (free if approved) |
| **Total** | **~$43/month** |
| **Accuracy:** | Highest (official sold data, 90-day history) |

#### Option D: Full Stack with Sneaker Support
| Component | Monthly Cost |
|---|---|
| On-device OCR + FashionCLIP | $0 |
| Apify eBay Sold Listings | ~$250/month |
| KicksDB Starter (sneakers) | EUR 29/month |
| Google Cloud Vision OCR | ~$43/month |
| **Total** | **~$325/month** |

### 6.5 Recommended MVP Strategy

**Phase 1 (Launch MVP - Weeks 1-4):**
1. Build on-device OCR + FashionCLIP classification (zero cost)
2. Use eBay Browse API for active listing prices (free, 5K calls/day)
3. Apply for Marketplace Insights API access simultaneously
4. Display price as a range: "Similar items listed for $X - $Y on eBay"

**Phase 2 (Improve Accuracy - Weeks 5-8):**
1. If Marketplace Insights approved: integrate sold data, change messaging to "Recently sold for $X - $Y"
2. If denied: integrate Apify eBay sold listings scraper as backend service
3. Add server-side caching layer (cache results for identical searches for 24-48 hours to reduce API calls)

**Phase 3 (Expand Coverage - Weeks 9-12):**
1. Add KicksDB for sneaker-specific pricing
2. Build brand recognition database (top 200 thrift brands with typical resale multipliers)
3. Add condition adjustment logic
4. Consider Google Cloud Vision Web Detection for finding exact item matches

### 6.6 Fallback Strategy

```
Scan Item
  |
  v
[On-Device] Extract brand + garment type + search terms
  |
  v
Try: eBay Marketplace Insights API (sold data)
  |-- Success --> Return median sold price with range
  |-- Fail/Denied -->
      |
      Try: Apify eBay Sold Listings scraper
        |-- Success --> Return aggregated sold price
        |-- Fail/Rate Limited -->
            |
            Try: eBay Browse API (active listings)
              |-- Success --> Return "Listed at $X-$Y" (mark as estimate)
              |-- Fail -->
                  |
                  Return: Brand-based estimate from local database
                  "Similar [Brand] [Category] items typically resell for $X-$Y"
```

### 6.7 Key Technical Decisions

1. **Server vs. Serverless:** Use a lightweight server (or AWS Lambda / Cloud Functions) between the app and eBay APIs. This gives you caching, rate limit management, and the ability to swap data sources without app updates.

2. **Caching Strategy:** Cache eBay search results for 24-48 hours keyed by (brand + category + condition). Most thrift store pricing doesn't change that fast. This can reduce API calls by 60-80%.

3. **Search Query Construction:** The quality of your eBay search query determines accuracy. Use: `"{brand name}" "{garment type}" {condition} -lot -bundle -wholesale`

4. **On-Device Model Size:** Marqo-FashionCLIP (ViT-B/32) converts to ~150-300MB CoreML model. Consider quantization to reduce to ~50-100MB for acceptable app size.

5. **Legal Mitigation:** Display results as "based on eBay marketplace data" with a link to eBay search results. This aligns with affiliate program guidelines and provides attribution.

---

## Summary: Best API for Each Need

| Need | Best Option | Cost | Reliability |
|---|---|---|---|
| **Sold prices (official)** | eBay Marketplace Insights API | Free (if approved) | High but hard to get access |
| **Sold prices (scraping)** | Apify eBay Sold Listings | ~$25/1K results | Medium (scraper can break) |
| **Active listing prices** | eBay Browse API | Free | High |
| **Clothing identification** | Marqo-FashionCLIP (on-device) | Free | High |
| **Tag/label OCR** | Apple VisionKit | Free | High |
| **Brand logo detection** | Google Cloud Vision | $1.50/1K | High |
| **Sneaker prices** | KicksDB | Free-EUR79/month | High |
| **Multi-marketplace prices** | Retailed.io | $49-999/month | Medium-High |
| **Barcode lookup** | UPCitemdb / Go-UPC | Free tier available | Low for clothing |
| **Manufacturer from RN#** | FTC RN Database (local copy) | Free | High |

---

## Sources

- [eBay Browse API Documentation](https://developer.ebay.com/api-docs/buy/browse/overview.html)
- [eBay Marketplace Insights API Overview](https://developer.ebay.com/api-docs/buy/marketplace-insights/static/overview.html)
- [eBay API Call Limits](https://developer.ebay.com/develop/get-started/api-call-limits)
- [eBay API License Agreement](https://developer.ebay.com/join/api-license-agreement)
- [eBay OAuth Documentation](https://developer.ebay.com/api-docs/static/oauth-tokens.html)
- [eBay Restricts AI Data Use (July 2025)](https://www.ecommercebytes.com/2025/07/18/ebay-restricts-developers-from-using-its-data-to-train-ai/)
- [eBay Finding API Decommission Notice](https://community.ebay.com/t5/Traditional-APIs-Search/Alert-Finding-API-and-Shopping-API-to-be-decommissioned-in-2025/td-p/34222062)
- [Marketplace Insights API Access Discussion](https://community.ebay.com/t5/eBay-APIs-Talk-to-your-fellow/Access-to-sold-completed-listing-data-what-options-do-non/m-p/35398955)
- [Apify eBay Sold Listings Intelligence](https://apify.com/marielise.dev/ebay-sold-listings-intelligence)
- [Apify eBay Sold Listings API](https://apify.com/caffein.dev/ebay-sold-listings)
- [Apify Pricing](https://use-apify.com/docs/what-is-apify/apify-pricing)
- [SerpApi eBay Search API](https://serpapi.com/ebay-search-api)
- [SearchAPI.io eBay API](https://www.searchapi.io/docs/ebay-search-api)
- [Oxylabs Pricing](https://oxylabs.io/pricing)
- [Bright Data vs Oxylabs Comparison](https://brightdata.com/blog/comparison/bright-data-vs-oxylabs)
- [Colin Daniels eBay Sold Items Documentation](https://github.com/colindaniels/eBay-sold-items-documentation)
- [eBay Scraping Legal Guide](https://multilogin.com/blog/how-to-scrape-ebay-data/)
- [eBay User Agreement](https://www.ebay.com/help/policies/member-behaviour-policies/user-agreement?id=4259)
- [Google Cloud Vision API Pricing](https://cloud.google.com/vision/pricing)
- [Amazon Rekognition Pricing](https://aws.amazon.com/rekognition/pricing/)
- [Clarifai Pricing](https://www.clarifai.com/pricing)
- [Clarifai Apparel Recognition Model](https://clarifai.com/clarifai/main/models/apparel-recognition)
- [FashionCLIP on HuggingFace](https://huggingface.co/patrickjohncyh/fashion-clip)
- [Marqo-FashionCLIP GitHub](https://github.com/marqo-ai/marqo-FashionCLIP)
- [OpenFashionCLIP Paper](https://arxiv.org/abs/2309.05551)
- [Go-UPC Barcode Database](https://go-upc.com/)
- [Barcode Lookup API](https://www.barcodelookup.com/api)
- [FTC RN Database Search](https://rn.ftc.gov/Account/BasicSearch)
- [KicksDB API Pricing](https://kicks.dev/pricing)
- [Retailed.io API Pricing](https://www.retailed.io/datasources/pricing)
- [StockX Developer Portal](https://developer.stockx.com/portal/api-introduction)
- [Sneaks-API (StockX/GOAT/FlightClub)](https://github.com/druv5319/Sneaks-API)
- [eBay Partner Network](https://partnernetwork.ebay.com/)
- [ThriftAI App](https://apps.apple.com/us/app/thriftai-profit-identifier/id6746565278)
- [Vintage-Snap.com](https://vintage-snap.com/)
- [ThredUp 2025 Resale Report](https://www.thredup.com/resale/)
