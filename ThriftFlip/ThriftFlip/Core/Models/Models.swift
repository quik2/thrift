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
    case insufficient
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

// MARK: - Scan States

enum ScanOverlayState {
    case searching
    case locked
    case failed
}

enum ScanButtonState {
    case ready
    case scanning
    case cooldown
    case disabled
}

// MARK: - Scan Errors

enum ScanError: Error, Identifiable {
    case networkUnavailable
    case timeout
    case ocrFailed
    case noComps
    case rateLimited
    case cameraDenied
    case serverError(String)

    var id: String {
        switch self {
        case .networkUnavailable: return "network"
        case .timeout: return "timeout"
        case .ocrFailed: return "ocr"
        case .noComps: return "noComps"
        case .rateLimited: return "rateLimited"
        case .cameraDenied: return "cameraDenied"
        case .serverError: return "server"
        }
    }

    var title: String {
        switch self {
        case .networkUnavailable: return "No connection"
        case .timeout: return "Taking too long"
        case .ocrFailed: return "Couldn't read the tag"
        case .noComps: return "No comparables found"
        case .rateLimited: return "Daily limit reached"
        case .cameraDenied: return "Camera access needed"
        case .serverError: return "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .networkUnavailable: return "Check your internet connection and try again."
        case .timeout: return "The search is taking longer than expected. Try again."
        case .ocrFailed: return "Make sure the tag text is visible and well-lit, then try again."
        case .noComps: return "We couldn't find similar listings for this item."
        case .rateLimited: return "You've used all 5 free scans today. Upgrade for unlimited scans."
        case .cameraDenied: return "Go to Settings > ThriftFlip > Camera to enable scanning."
        case .serverError(let detail): return detail
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .ocrFailed, .serverError: return true
        case .noComps, .rateLimited, .cameraDenied: return false
        }
    }
}

// MARK: - App Header Style

enum AppHeaderStyle {
    case opaque
    case transparent
}

// MARK: - Paywall

struct PaywallFeature: Identifiable {
    let id = UUID()
    let text: String
    let isIncluded: Bool
}
