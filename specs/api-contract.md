# ThriftFlip API Contract

## Base URL

```
POST /api/v1/scan
GET  /api/v1/collection
GET  /api/v1/collection/{item_id}
POST /api/v1/collection/{item_id}/correct
DELETE /api/v1/collection/{item_id}
```

---

## Core Data Shapes

### ScanResult

This is the primary object returned from a scan. The entire UI is built around this shape.

```json
{
  "id": "scan_abc123",
  "timestamp": "2026-02-15T14:30:00Z",
  "identification": {
    "brand": "Patagonia",
    "itemName": "Better Sweater 1/4 Zip",
    "category": "Outerwear",
    "garmentType": "fleece",
    "color": "navy"
  },
  "priceRange": {
    "low": 42.00,
    "median": 67.50,
    "high": 95.00,
    "currency": "USD"
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

### Swift Model (for Codex)

```swift
struct ScanResult: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let identification: Identification
    let priceRange: PriceRange
    let confidence: Confidence
    let comps: [CompListing]
    let tagExtraction: TagExtraction?
    let scanImages: ScanImages
}

struct Identification: Codable {
    let brand: String
    let itemName: String
    let category: String
    let garmentType: String
    let color: String?
}

struct PriceRange: Codable {
    let low: Double
    let median: Double
    let high: Double
    let currency: String
}

struct Confidence: Codable {
    let score: Int           // 0-100
    let level: ConfidenceLevel
    let factors: [ConfidenceFactor]
}

enum ConfidenceLevel: String, Codable {
    case high    // 75-100
    case medium  // 50-74
    case low     // 0-49
}

struct ConfidenceFactor: Codable, Identifiable {
    var id: String { name }
    let name: String
    let value: String
}

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

struct TagExtraction: Codable {
    let brand: String?
    let size: String?
    let material: String?
    let rnNumber: String?
    let rawText: String?
}

struct ScanImages: Codable {
    let itemImageUrl: String
    let tagImageUrl: String?
}
```

---

## Endpoint Details

### POST /api/v1/scan

**Request:**
```
Content-Type: multipart/form-data

Fields:
  - itemImage: JPEG (required)
  - tagImage: JPEG (optional but recommended)
```

**Response:** `ScanResult` (see above)

**Error states:**
```json
{ "error": "ocr_failed", "message": "Could not read the tag. Try a clearer photo.", "retryable": true }
{ "error": "no_comps", "message": "No comparable listings found for this item.", "retryable": false }
{ "error": "timeout", "message": "Search took too long. Please try again.", "retryable": true }
{ "error": "rate_limited", "message": "Daily scan limit reached. Upgrade for unlimited scans.", "retryable": false }
```

### GET /api/v1/collection

**Response:**
```json
{
  "items": [
    {
      "id": "scan_abc123",
      "timestamp": "2026-02-15T14:30:00Z",
      "identification": {
        "brand": "Patagonia",
        "itemName": "Better Sweater 1/4 Zip",
        "category": "Outerwear",
        "garmentType": "fleece",
        "color": "navy"
      },
      "priceRange": {
        "low": 42.00,
        "median": 67.50,
        "high": 95.00,
        "currency": "USD"
      },
      "confidence": {
        "score": 87,
        "level": "high"
      },
      "thumbnailUrl": "/local/scan_abc123_thumb.jpg",
      "corrected": false
    }
  ],
  "totalCount": 24,
  "scansToday": 3,
  "dailyLimit": 5
}
```

### POST /api/v1/collection/{item_id}/correct

**Request:**
```json
{
  "correctedBrand": "Patagonia",
  "correctedItemName": "Synchilla Snap-T Fleece",
  "correctedCategory": "Outerwear",
  "notes": "It's the snap-t not the better sweater"
}
```

**Response:** Updated `ScanResult` with re-computed pricing.

---

## Mock Data for UI Development

Use these three items to build all UI states:

### High Confidence Item
```json
{
  "id": "mock_high",
  "timestamp": "2026-02-15T14:30:00Z",
  "identification": {
    "brand": "Patagonia",
    "itemName": "Better Sweater 1/4 Zip",
    "category": "Outerwear",
    "garmentType": "fleece",
    "color": "navy"
  },
  "priceRange": { "low": 42.00, "median": 67.50, "high": 95.00, "currency": "USD" },
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
  "scanImages": { "itemImageUrl": "mock_item.jpg", "tagImageUrl": "mock_tag.jpg" }
}
```

### Medium Confidence Item
```json
{
  "id": "mock_medium",
  "timestamp": "2026-02-15T15:00:00Z",
  "identification": {
    "brand": "Nike",
    "itemName": "Tech Fleece Joggers",
    "category": "Bottoms",
    "garmentType": "joggers",
    "color": "black"
  },
  "priceRange": { "low": 25.00, "median": 45.00, "high": 78.00, "currency": "USD" },
  "confidence": { "score": 62, "level": "medium", "factors": [
    { "name": "tagExtraction", "value": "partial" },
    { "name": "compDepth", "value": "12 comps" },
    { "name": "compVariance", "value": "moderate" }
  ]},
  "comps": [
    { "id": "c4", "title": "Nike Tech Fleece Pants Black", "price": 48.00, "status": "sold", "soldDate": "2026-02-05", "source": "ebay", "imageUrl": "", "listingUrl": "" }
  ],
  "tagExtraction": { "brand": "Nike", "size": null, "material": null, "rnNumber": null, "rawText": "Nike" },
  "scanImages": { "itemImageUrl": "mock_item2.jpg", "tagImageUrl": null }
}
```

### Low Confidence Item
```json
{
  "id": "mock_low",
  "timestamp": "2026-02-15T15:30:00Z",
  "identification": {
    "brand": "Unknown",
    "itemName": "Wool Blend Overcoat",
    "category": "Outerwear",
    "garmentType": "coat",
    "color": "charcoal"
  },
  "priceRange": { "low": 15.00, "median": 40.00, "high": 120.00, "currency": "USD" },
  "confidence": { "score": 31, "level": "low", "factors": [
    { "name": "tagExtraction", "value": "failed" },
    { "name": "compDepth", "value": "3 comps" },
    { "name": "compVariance", "value": "high" }
  ]},
  "comps": [
    { "id": "c5", "title": "Wool Overcoat Charcoal L", "price": 35.00, "status": "active", "soldDate": null, "source": "ebay", "imageUrl": "", "listingUrl": "" }
  ],
  "tagExtraction": null,
  "scanImages": { "itemImageUrl": "mock_item3.jpg", "tagImageUrl": null }
}
```

---

## Error Mock Data

```swift
// For building error state UI
enum ScanError: String {
    case ocrFailed = "ocr_failed"
    case noComps = "no_comps"
    case timeout = "timeout"
    case rateLimited = "rate_limited"
    case networkError = "network_error"
}
```
