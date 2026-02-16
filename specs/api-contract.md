# ThriftFlip API Contract

## Base URL

```
POST /api/v1/scan
GET  /api/v1/items
GET  /api/v1/items/{item_id}
PUT  /api/v1/items/{item_id}
POST /api/v1/items/{item_id}/correct
DELETE /api/v1/items/{item_id}
POST /api/v1/items/{item_id}/listing-draft
POST /api/v1/items/{item_id}/publish
GET  /api/v1/settings
PUT  /api/v1/settings
```

---

## Core Data Shapes

### ScanResult

Returned from a scan. Every scan is auto-saved to the user's library.

```json
{
  "id": "scan_abc123",
  "timestamp": "2026-02-15T14:30:00Z",
  "status": "scanned",
  "identification": {
    "brand": "Patagonia",
    "itemName": "Better Sweater 1/4 Zip",
    "category": "Outerwear",
    "garmentType": "fleece",
    "color": "navy"
  },
  "pricingBreakdown": {
    "sold": {
      "low": 42.00,
      "median": 67.50,
      "high": 95.00,
      "compCount": 34,
      "currency": "USD"
    },
    "active": {
      "low": 55.00,
      "median": 79.99,
      "high": 125.00,
      "compCount": 13,
      "currency": "USD"
    },
    "combined": {
      "low": 42.00,
      "median": 69.00,
      "high": 95.00,
      "currency": "USD"
    }
  },
  "marketInsights": {
    "sellThroughRate": 72,
    "avgDaysToSell": 8,
    "demandLevel": "high",
    "volumeTrend": "stable",
    "totalSoldLast90Days": 34,
    "totalActiveListings": 13
  },
  "platformComparison": [
    {
      "platform": "ebay",
      "feePercent": 13.25,
      "estimatedShipping": 7.50,
      "grossPrice": 67.50,
      "fees": 8.94,
      "netProfit": 51.06,
      "netAfterCost": 43.06
    },
    {
      "platform": "poshmark",
      "feePercent": 20.0,
      "estimatedShipping": 0.00,
      "grossPrice": 67.50,
      "fees": 13.50,
      "netProfit": 54.00,
      "netAfterCost": 46.00
    },
    {
      "platform": "mercari",
      "feePercent": 10.0,
      "estimatedShipping": 7.50,
      "grossPrice": 67.50,
      "fees": 6.75,
      "netProfit": 53.25,
      "netAfterCost": 45.25
    },
    {
      "platform": "depop",
      "feePercent": 3.3,
      "estimatedShipping": 7.50,
      "grossPrice": 67.50,
      "fees": 2.23,
      "netProfit": 57.77,
      "netAfterCost": 49.77
    },
    {
      "platform": "whatnot",
      "feePercent": 8.0,
      "estimatedShipping": 7.50,
      "grossPrice": 67.50,
      "fees": 5.40,
      "netProfit": 54.60,
      "netAfterCost": 46.60
    }
  ],
  "buySignal": {
    "signal": "green",
    "reason": "High sell-through (72%), strong margins on all platforms",
    "estimatedROI": 538,
    "bestPlatform": "depop"
  },
  "profitEstimate": {
    "estimatedCost": 8.00,
    "bestNetProfit": 49.77,
    "bestPlatform": "depop",
    "roi": 538
  },
  "confidence": {
    "score": 87,
    "level": "high",
    "factors": [
      { "name": "tagExtraction", "value": "strong" },
      { "name": "compDepth", "value": "47 comps" },
      { "name": "compVariance", "value": "low" }
    ]
  },
  "comps": [
    {
      "id": "comp_1",
      "title": "Patagonia Better Sweater 1/4 Zip Navy M",
      "price": 72.00,
      "status": "sold",
      "soldDate": "2026-02-10",
      "source": "ebay",
      "imageUrl": "https://i.ebayimg.com/...",
      "listingUrl": "https://ebay.com/itm/..."
    },
    {
      "id": "comp_2",
      "title": "Patagonia Better Sweater Quarter Zip Blue",
      "price": 59.99,
      "status": "active",
      "soldDate": null,
      "source": "ebay",
      "imageUrl": "https://i.ebayimg.com/...",
      "listingUrl": "https://ebay.com/itm/..."
    }
  ],
  "tagExtraction": {
    "brand": "Patagonia",
    "size": "M",
    "material": "100% Polyester",
    "rnNumber": "51884",
    "rawText": "Patagonia\nSize M\n100% Polyester\nRN#51884\nMade in Vietnam"
  },
  "scanImages": {
    "itemImageUrl": "/local/scan_abc123_item.jpg",
    "tagImageUrl": "/local/scan_abc123_tag.jpg"
  }
}
```

### Item States

Every scan auto-saves. Items move through two states:

| State | Meaning | How it's set |
|-------|---------|-------------|
| `scanned` | User scanned it, hasn't decided yet | Automatic on scan |
| `bought` | User purchased this item | User taps "Mark as Bought" |

### UserSettings

User-configurable preferences set during onboarding quiz and fine-tuned in settings.

```json
{
  "userId": "user_abc123",
  "experienceLevel": "beginner",
  "storeType": "goodwill",
  "defaultCostEstimate": 7.00,
  "profitThreshold": {
    "minProfitDollars": 10.00,
    "minProfitPercent": null,
    "mode": "dollars"
  },
  "preferredPlatforms": ["ebay", "poshmark", "depop"],
  "shippingDefaults": {
    "clothing": 7.50,
    "shoes": 12.00,
    "heavy": 15.00,
    "accessories": 5.00
  },
  "displayPreferences": {
    "defaultPriceSource": "sold",
    "showAllPlatforms": true
  },
  "updatedAt": "2026-02-15T14:30:00Z"
}
```

**Store types → default cost estimates:**

| Store Type | Default Cost | Description |
|-----------|-------------|-------------|
| `goodwill` | $7.00 | Goodwill / similar large chains |
| `salvation_army` | $5.00 | Salvation Army / budget stores |
| `consignment` | $12.00 | Plato's Closet, Buffalo Exchange |
| `vintage` | $15.00 | Vintage/curated shops |
| `garage_sale` | $3.00 | Garage sales, estate sales |
| `custom` | user-set | User enters their own default |

### ListingDraft

AI-generated eBay listing for a bought item.

```json
{
  "id": "draft_abc123",
  "itemId": "scan_abc123",
  "platform": "ebay",
  "title": "Patagonia Better Sweater 1/4 Zip Fleece Jacket Navy Blue Men's Size M",
  "description": "Pre-owned Patagonia Better Sweater 1/4 Zip in navy blue...",
  "category": "Clothing > Men's > Coats & Jackets > Fleece",
  "condition": "Pre-owned",
  "suggestedPrice": 67.50,
  "photos": [],
  "status": "draft",
  "createdAt": "2026-02-16T10:00:00Z"
}
```

**Important:** `photos` is empty on draft creation. The user takes new product photos at home — scan photos are NOT suitable for listings. The app prompts "Take listing photos" with a guided photo capture flow (front, back, tag, details).

### Swift Models

```swift
// MARK: - Core Scan Result

struct ScanResult: Codable, Identifiable {
    let id: String
    let timestamp: Date
    var status: ItemStatus
    let identification: Identification
    let pricingBreakdown: PricingBreakdown?
    let marketInsights: MarketInsights?
    let platformComparison: [PlatformEstimate]
    let buySignal: BuySignal?
    let profitEstimate: ProfitEstimate?
    let confidence: Confidence
    let comps: [CompListing]
    let tagExtraction: TagExtraction?
    let scanImages: ScanImages
    var purchasePrice: Double?
    var corrected: Bool
}

enum ItemStatus: String, Codable {
    case scanned    // Auto-saved, user hasn't decided
    case bought     // User purchased this item
}

struct Identification: Codable {
    let brand: String
    let itemName: String
    let category: String
    let garmentType: String
    let color: String?
}

// MARK: - Pricing (Sold vs Active Separated)

struct PricingBreakdown: Codable {
    let sold: PriceRange?
    let active: PriceRange?
    let combined: PriceRange
}

struct PriceRange: Codable {
    let low: Double
    let median: Double
    let high: Double
    let compCount: Int?
    let currency: String
}

// MARK: - Market Insights

struct MarketInsights: Codable {
    let sellThroughRate: Int        // 0-100 percentage
    let avgDaysToSell: Int?
    let demandLevel: DemandLevel
    let volumeTrend: VolumeTrend
    let totalSoldLast90Days: Int
    let totalActiveListings: Int
}

enum DemandLevel: String, Codable {
    case high       // sell-through >= 65%
    case moderate   // sell-through 35-64%
    case low        // sell-through < 35%
}

enum VolumeTrend: String, Codable {
    case rising     // 30-day volume > 60-day avg
    case stable     // within 20% of 60-day avg
    case declining  // 30-day volume < 60-day avg
}

// MARK: - Platform Comparison

struct PlatformEstimate: Codable, Identifiable {
    var id: String { platform }
    let platform: String
    let feePercent: Double
    let estimatedShipping: Double
    let grossPrice: Double
    let fees: Double
    let netProfit: Double           // grossPrice - fees - shipping
    let netAfterCost: Double?       // netProfit - estimatedCost (nil if no cost set)
}

// MARK: - Buy/Pass Signal

struct BuySignal: Codable {
    let signal: Signal
    let reason: String
    let estimatedROI: Int?
    let bestPlatform: String?
}

enum Signal: String, Codable {
    case green
    case yellow
    case red
}

// MARK: - Profit Estimate

struct ProfitEstimate: Codable {
    let estimatedCost: Double       // from user settings (store type default)
    let bestNetProfit: Double
    let bestPlatform: String
    let roi: Int
}

// MARK: - Confidence

struct Confidence: Codable {
    let score: Int
    let level: ConfidenceLevel
    let factors: [ConfidenceFactor]
}

enum ConfidenceLevel: String, Codable {
    case high           // 80-100
    case medium         // 55-79
    case low            // 30-54
    case insufficient   // 0-29
}

struct ConfidenceFactor: Codable, Identifiable {
    var id: String { name }
    let name: String
    let value: String
}

// MARK: - Comps

struct CompListing: Codable, Identifiable {
    let id: String
    let title: String
    let price: Double
    let status: CompStatus
    let soldDate: String?
    let source: String
    let imageUrl: String
    let listingUrl: String
}

enum CompStatus: String, Codable {
    case sold
    case active
}

// MARK: - Tag Extraction

struct TagExtraction: Codable {
    let brand: String?
    let size: String?
    let material: String?
    let rnNumber: String?
    let rawText: String?
}

// MARK: - Scan Images

struct ScanImages: Codable {
    let itemImageUrl: String
    let tagImageUrl: String?
}

// MARK: - Listing Draft

struct ListingDraft: Codable, Identifiable {
    let id: String
    let itemId: String
    let platform: String
    var title: String
    var description: String
    var category: String
    var condition: String
    var suggestedPrice: Double
    var photos: [String]            // URLs of listing photos (NOT scan photos)
    var status: ListingStatus
    let createdAt: Date
}

enum ListingStatus: String, Codable {
    case draft          // AI-generated, user reviewing
    case needsPhotos    // Draft ready but no listing photos yet
    case ready          // Photos added, ready to publish
    case published      // Live on eBay
}

// MARK: - User Settings

struct UserSettings: Codable {
    var experienceLevel: ExperienceLevel
    var storeType: StoreType
    var defaultCostEstimate: Double
    var profitThreshold: ProfitThreshold
    var preferredPlatforms: [String]
    var shippingDefaults: ShippingDefaults
    var displayPreferences: DisplayPreferences
    let updatedAt: Date?
}

enum ExperienceLevel: String, Codable {
    case beginner       // Show minimal data, big signal
    case intermediate   // Show signal + key stats
    case expert         // Show everything
}

enum StoreType: String, Codable {
    case goodwill           // ~$7 default
    case salvationArmy      // ~$5 default
    case consignment        // ~$12 default
    case vintage            // ~$15 default
    case garageSale         // ~$3 default
    case custom             // user-set default
}

struct ProfitThreshold: Codable {
    var minProfitDollars: Double?
    var minProfitPercent: Double?
    var mode: ProfitMode
}

enum ProfitMode: String, Codable {
    case dollars
    case percent
}

struct ShippingDefaults: Codable {
    var clothing: Double
    var shoes: Double
    var heavy: Double
    var accessories: Double
}

struct DisplayPreferences: Codable {
    var defaultPriceSource: PriceSource
    var showAllPlatforms: Bool
}

enum PriceSource: String, Codable {
    case sold
    case active
    case combined
}

// MARK: - Portfolio Summary

struct PortfolioSummary: Codable {
    let totalItems: Int
    let totalInvested: Double       // sum of purchasePrice for bought items
    let totalPotentialValue: Double  // sum of median sold prices
    let totalPotentialProfit: Double
    let averageROI: Int
}
```

---

## Endpoint Details

### POST /api/v1/scan

Scans an item and auto-saves to the user's library.

**Request:**
```
Content-Type: multipart/form-data

Fields:
  - itemImage: JPEG (required)
  - tagImage: JPEG (optional but recommended)
  - ocrPayload: JSON (optional — on-device extraction results)
```

No `thriftPrice` in the request. The profit estimate uses the user's `defaultCostEstimate` from settings (derived from store type). The user can override per-item later via `PUT /api/v1/items/{id}`.

**Response:** `ScanResult` with `status: "scanned"` (auto-saved).

**Profit calculation:** Server looks up user's settings → uses `defaultCostEstimate` → computes `profitEstimate` and `platformComparison[].netAfterCost` → feeds into `buySignal`.

**Error states:**
```json
{ "error": "ocr_failed", "message": "Could not read the tag. Try a clearer photo.", "retryable": true }
{ "error": "no_comps", "message": "No comparable listings found for this item.", "retryable": false }
{ "error": "timeout", "message": "Search took too long. Please try again.", "retryable": true }
{ "error": "rate_limited", "message": "Daily scan limit reached. Upgrade for unlimited scans.", "retryable": false }
```

### GET /api/v1/items

Returns the user's library. Supports filtering by status.

**Query params:**
- `status` — `scanned`, `bought`, or omit for all
- `sort` — `newest` (default), `oldest`, `value_high`, `value_low`
- `limit` — default 50
- `offset` — default 0

**Response:**
```json
{
  "items": [
    {
      "id": "scan_abc123",
      "timestamp": "2026-02-15T14:30:00Z",
      "status": "bought",
      "identification": {
        "brand": "Patagonia",
        "itemName": "Better Sweater 1/4 Zip",
        "category": "Outerwear",
        "garmentType": "fleece",
        "color": "navy"
      },
      "pricingBreakdown": {
        "sold": { "low": 42.00, "median": 67.50, "high": 95.00, "compCount": 34, "currency": "USD" },
        "active": null,
        "combined": { "low": 42.00, "median": 69.00, "high": 95.00, "currency": "USD" }
      },
      "buySignal": { "signal": "green", "reason": "High sell-through, strong margins", "estimatedROI": 538, "bestPlatform": "depop" },
      "confidence": { "score": 87, "level": "high" },
      "thumbnailUrl": "/local/scan_abc123_thumb.jpg",
      "purchasePrice": 8.00,
      "corrected": false
    }
  ],
  "totalCount": 24,
  "portfolio": {
    "totalItems": 8,
    "totalInvested": 89.00,
    "totalPotentialValue": 634.00,
    "totalPotentialProfit": 545.00,
    "averageROI": 612
  },
  "scansToday": 3,
  "dailyLimit": 5
}
```

The `portfolio` field only includes items with `status: "bought"`.

### PUT /api/v1/items/{item_id}

Update item status or purchase price.

**Request:**
```json
{
  "status": "bought",
  "purchasePrice": 8.00
}
```

**Response:** Updated `ScanResult`.

### POST /api/v1/items/{item_id}/correct

**Request:**
```json
{
  "correctedBrand": "Patagonia",
  "correctedItemName": "Synchilla Snap-T Fleece",
  "correctedCategory": "Outerwear",
  "notes": "It's the snap-t not the better sweater"
}
```

**Response:** Updated `ScanResult` with re-computed pricing and buy signal.

### POST /api/v1/items/{item_id}/listing-draft

Generate an AI-powered eBay listing draft. Only available for items with `status: "bought"`.

**Request:** No body needed — the server has all item data.

**Response:**
```json
{
  "id": "draft_abc123",
  "itemId": "scan_abc123",
  "platform": "ebay",
  "title": "Patagonia Better Sweater 1/4 Zip Fleece Jacket Navy Blue Men's Size M",
  "description": "Pre-owned Patagonia Better Sweater 1/4 Zip in navy blue. Size Men's Medium. 100% Polyester fleece. Great condition...",
  "category": "Clothing, Shoes & Accessories > Men > Men's Clothing > Coats, Jackets & Vests",
  "condition": "Pre-owned",
  "suggestedPrice": 67.50,
  "photos": [],
  "status": "needsPhotos",
  "createdAt": "2026-02-16T10:00:00Z"
}
```

The `photos` array is empty. The app prompts the user to take product photos (front, back, tag close-up, any details). Scan photos are NOT used for listings — they're taken at bad angles in poor lighting.

### POST /api/v1/items/{item_id}/publish

Publish a listing draft to eBay via the Trading API.

**Request:**
```json
{
  "draftId": "draft_abc123",
  "title": "Patagonia Better Sweater 1/4 Zip Fleece...",
  "description": "Pre-owned Patagonia...",
  "price": 67.50,
  "photos": ["https://storage.../photo1.jpg", "https://storage.../photo2.jpg"]
}
```

**Response:**
```json
{
  "success": true,
  "ebayListingId": "123456789",
  "ebayListingUrl": "https://www.ebay.com/itm/123456789"
}
```

### GET /api/v1/settings

**Response:** `UserSettings` (see above)

Returns defaults if user has never saved settings:
```json
{
  "experienceLevel": "beginner",
  "storeType": "goodwill",
  "defaultCostEstimate": 7.00,
  "profitThreshold": { "minProfitDollars": 10.00, "minProfitPercent": null, "mode": "dollars" },
  "preferredPlatforms": ["ebay", "poshmark"],
  "shippingDefaults": { "clothing": 7.50, "shoes": 12.00, "heavy": 15.00, "accessories": 5.00 },
  "displayPreferences": { "defaultPriceSource": "sold", "showAllPlatforms": true },
  "updatedAt": null
}
```

### PUT /api/v1/settings

**Request:** Partial `UserSettings` — only send fields being changed.

**Response:** Full updated `UserSettings`.

---

## Mock Data for UI Development

Use these four items to build all UI states:

### High Confidence Item (Green Signal, Bought)
```json
{
  "id": "mock_high",
  "timestamp": "2026-02-15T14:30:00Z",
  "status": "bought",
  "identification": { "brand": "Patagonia", "itemName": "Better Sweater 1/4 Zip", "category": "Outerwear", "garmentType": "fleece", "color": "navy" },
  "pricingBreakdown": {
    "sold": { "low": 42.00, "median": 67.50, "high": 95.00, "compCount": 34, "currency": "USD" },
    "active": { "low": 55.00, "median": 79.99, "high": 125.00, "compCount": 13, "currency": "USD" },
    "combined": { "low": 42.00, "median": 69.00, "high": 95.00, "currency": "USD" }
  },
  "marketInsights": { "sellThroughRate": 72, "avgDaysToSell": 8, "demandLevel": "high", "volumeTrend": "stable", "totalSoldLast90Days": 34, "totalActiveListings": 13 },
  "platformComparison": [
    { "platform": "ebay", "feePercent": 13.25, "estimatedShipping": 7.50, "grossPrice": 67.50, "fees": 8.94, "netProfit": 51.06, "netAfterCost": 43.06 },
    { "platform": "poshmark", "feePercent": 20.0, "estimatedShipping": 0.00, "grossPrice": 67.50, "fees": 13.50, "netProfit": 54.00, "netAfterCost": 46.00 },
    { "platform": "mercari", "feePercent": 10.0, "estimatedShipping": 7.50, "grossPrice": 67.50, "fees": 6.75, "netProfit": 53.25, "netAfterCost": 45.25 },
    { "platform": "depop", "feePercent": 3.3, "estimatedShipping": 7.50, "grossPrice": 67.50, "fees": 2.23, "netProfit": 57.77, "netAfterCost": 49.77 },
    { "platform": "whatnot", "feePercent": 8.0, "estimatedShipping": 7.50, "grossPrice": 67.50, "fees": 5.40, "netProfit": 54.60, "netAfterCost": 46.60 }
  ],
  "buySignal": { "signal": "green", "reason": "High sell-through (72%), strong margins on all platforms", "estimatedROI": 538, "bestPlatform": "depop" },
  "profitEstimate": { "estimatedCost": 8.00, "bestNetProfit": 49.77, "bestPlatform": "depop", "roi": 538 },
  "confidence": { "score": 87, "level": "high", "factors": [
    { "name": "tagExtraction", "value": "strong" },
    { "name": "compDepth", "value": "47 comps" },
    { "name": "compVariance", "value": "low" }
  ]},
  "comps": [
    { "id": "c1", "title": "Patagonia Better Sweater 1/4 Zip Navy M", "price": 72.00, "status": "sold", "soldDate": "2026-02-10", "source": "ebay", "imageUrl": "", "listingUrl": "" },
    { "id": "c2", "title": "Patagonia Better Sweater Quarter Zip", "price": 59.99, "status": "active", "soldDate": null, "source": "ebay", "imageUrl": "", "listingUrl": "" },
    { "id": "c3", "title": "Patagonia Better Sweater 1/4 Zip L", "price": 65.00, "status": "sold", "soldDate": "2026-02-08", "source": "ebay", "imageUrl": "", "listingUrl": "" }
  ],
  "tagExtraction": { "brand": "Patagonia", "size": "M", "material": "100% Polyester", "rnNumber": "51884", "rawText": "Patagonia\nSize M\n100% Polyester\nRN#51884" },
  "scanImages": { "itemImageUrl": "mock_item.jpg", "tagImageUrl": "mock_tag.jpg" },
  "purchasePrice": 8.00,
  "corrected": false
}
```

### Medium Confidence Item (Yellow Signal, Scanned)
```json
{
  "id": "mock_medium",
  "timestamp": "2026-02-15T15:00:00Z",
  "status": "scanned",
  "identification": { "brand": "Nike", "itemName": "Tech Fleece Joggers", "category": "Bottoms", "garmentType": "joggers", "color": "black" },
  "pricingBreakdown": {
    "sold": { "low": 25.00, "median": 42.00, "high": 68.00, "compCount": 8, "currency": "USD" },
    "active": { "low": 35.00, "median": 55.00, "high": 85.00, "compCount": 4, "currency": "USD" },
    "combined": { "low": 25.00, "median": 45.00, "high": 78.00, "currency": "USD" }
  },
  "marketInsights": { "sellThroughRate": 48, "avgDaysToSell": 14, "demandLevel": "moderate", "volumeTrend": "stable", "totalSoldLast90Days": 8, "totalActiveListings": 4 },
  "platformComparison": [
    { "platform": "ebay", "feePercent": 13.25, "estimatedShipping": 7.50, "grossPrice": 42.00, "fees": 5.57, "netProfit": 28.93, "netAfterCost": 21.93 },
    { "platform": "poshmark", "feePercent": 20.0, "estimatedShipping": 0.00, "grossPrice": 42.00, "fees": 8.40, "netProfit": 33.60, "netAfterCost": 26.60 },
    { "platform": "mercari", "feePercent": 10.0, "estimatedShipping": 7.50, "grossPrice": 42.00, "fees": 4.20, "netProfit": 30.30, "netAfterCost": 23.30 },
    { "platform": "depop", "feePercent": 3.3, "estimatedShipping": 7.50, "grossPrice": 42.00, "fees": 1.39, "netProfit": 33.11, "netAfterCost": 26.11 },
    { "platform": "whatnot", "feePercent": 8.0, "estimatedShipping": 7.50, "grossPrice": 42.00, "fees": 3.36, "netProfit": 31.14, "netAfterCost": 24.14 }
  ],
  "buySignal": { "signal": "yellow", "reason": "Moderate sell-through (48%), decent margins but slower to sell", "estimatedROI": 280, "bestPlatform": "poshmark" },
  "profitEstimate": { "estimatedCost": 7.00, "bestNetProfit": 26.60, "bestPlatform": "poshmark", "roi": 280 },
  "confidence": { "score": 62, "level": "medium", "factors": [
    { "name": "tagExtraction", "value": "partial" },
    { "name": "compDepth", "value": "12 comps" },
    { "name": "compVariance", "value": "moderate" }
  ]},
  "comps": [
    { "id": "c4", "title": "Nike Tech Fleece Pants Black", "price": 48.00, "status": "sold", "soldDate": "2026-02-05", "source": "ebay", "imageUrl": "", "listingUrl": "" }
  ],
  "tagExtraction": { "brand": "Nike", "size": null, "material": null, "rnNumber": null, "rawText": "Nike" },
  "scanImages": { "itemImageUrl": "mock_item2.jpg", "tagImageUrl": null },
  "purchasePrice": null,
  "corrected": false
}
```

### Low Confidence Item (Red Signal, Scanned)
```json
{
  "id": "mock_low",
  "timestamp": "2026-02-15T15:30:00Z",
  "status": "scanned",
  "identification": { "brand": "Unknown", "itemName": "Wool Blend Overcoat", "category": "Outerwear", "garmentType": "coat", "color": "charcoal" },
  "pricingBreakdown": {
    "sold": null,
    "active": { "low": 15.00, "median": 40.00, "high": 120.00, "compCount": 3, "currency": "USD" },
    "combined": { "low": 15.00, "median": 40.00, "high": 120.00, "currency": "USD" }
  },
  "marketInsights": { "sellThroughRate": 0, "avgDaysToSell": null, "demandLevel": "low", "volumeTrend": "declining", "totalSoldLast90Days": 0, "totalActiveListings": 3 },
  "platformComparison": [
    { "platform": "ebay", "feePercent": 13.25, "estimatedShipping": 15.00, "grossPrice": 40.00, "fees": 5.30, "netProfit": 19.70, "netAfterCost": 12.70 },
    { "platform": "poshmark", "feePercent": 20.0, "estimatedShipping": 0.00, "grossPrice": 40.00, "fees": 8.00, "netProfit": 32.00, "netAfterCost": 25.00 },
    { "platform": "mercari", "feePercent": 10.0, "estimatedShipping": 15.00, "grossPrice": 40.00, "fees": 4.00, "netProfit": 21.00, "netAfterCost": 14.00 },
    { "platform": "depop", "feePercent": 3.3, "estimatedShipping": 15.00, "grossPrice": 40.00, "fees": 1.32, "netProfit": 23.68, "netAfterCost": 16.68 },
    { "platform": "whatnot", "feePercent": 8.0, "estimatedShipping": 15.00, "grossPrice": 40.00, "fees": 3.20, "netProfit": 21.80, "netAfterCost": 14.80 }
  ],
  "buySignal": { "signal": "red", "reason": "No recent sales found, low confidence, high price variance", "estimatedROI": null, "bestPlatform": null },
  "profitEstimate": null,
  "confidence": { "score": 31, "level": "low", "factors": [
    { "name": "tagExtraction", "value": "failed" },
    { "name": "compDepth", "value": "3 comps" },
    { "name": "compVariance", "value": "high" }
  ]},
  "comps": [
    { "id": "c5", "title": "Wool Overcoat Charcoal L", "price": 35.00, "status": "active", "soldDate": null, "source": "ebay", "imageUrl": "", "listingUrl": "" }
  ],
  "tagExtraction": null,
  "scanImages": { "itemImageUrl": "mock_item3.jpg", "tagImageUrl": null },
  "purchasePrice": null,
  "corrected": false
}
```

### Insufficient Confidence Item (No Signal)
```json
{
  "id": "mock_insufficient",
  "timestamp": "2026-02-15T16:00:00Z",
  "status": "scanned",
  "identification": { "brand": "Unknown", "itemName": "Unknown Garment", "category": "Unknown", "garmentType": "unknown", "color": null },
  "pricingBreakdown": null,
  "marketInsights": null,
  "platformComparison": [],
  "buySignal": null,
  "profitEstimate": null,
  "confidence": { "score": 12, "level": "insufficient", "factors": [
    { "name": "tagExtraction", "value": "failed" },
    { "name": "compDepth", "value": "0 comps" },
    { "name": "compVariance", "value": "n/a" }
  ]},
  "comps": [],
  "tagExtraction": null,
  "scanImages": { "itemImageUrl": "mock_item4.jpg", "tagImageUrl": null },
  "purchasePrice": null,
  "corrected": false
}
```

---

## Error Mock Data

```swift
enum ScanError: String {
    case ocrFailed = "ocr_failed"
    case noComps = "no_comps"
    case timeout = "timeout"
    case rateLimited = "rate_limited"
    case networkError = "network_error"
}
```
