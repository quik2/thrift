import Foundation

// MARK: - Scan Result

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
    let score: Int
    let level: ConfidenceLevel
    let factors: [ConfidenceFactor]
}

enum ConfidenceLevel: String, Codable {
    case high
    case medium
    case low
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

// MARK: - Saved Item (Collection list)

struct SavedItem: Identifiable {
    let id: String
    let timestamp: Date
    let identification: Identification
    let priceRange: PriceRange
    let confidence: Confidence
    let thumbnailColor: ThumbnailColor
    let corrected: Bool
}

struct ThumbnailColor {
    let primary: String   // hex
    let secondary: String // hex
}

// MARK: - Chart Data

struct PriceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Stat Trend

enum StatTrend {
    case up, down, neutral
}
