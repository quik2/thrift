import Foundation

enum MockData {

    // MARK: - Collection Items

    static let savedItems: [SavedItem] = [
        SavedItem(
            id: "item_001",
            timestamp: Date().addingTimeInterval(-86400 * 2),
            identification: Identification(brand: "Patagonia", itemName: "Better Sweater 1/4 Zip", category: "Outerwear", garmentType: "fleece", color: "navy"),
            priceRange: PriceRange(low: 95, median: 175, high: 245, currency: "USD"),
            confidence: Confidence(score: 87, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "47 comps"),
                ConfidenceFactor(name: "compVariance", value: "low")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#1B3A5C", secondary: "#2D5F8A"),
            corrected: false
        ),
        SavedItem(
            id: "item_002",
            timestamp: Date().addingTimeInterval(-86400 * 3),
            identification: Identification(brand: "Nike", itemName: "Tech Fleece Joggers", category: "Bottoms", garmentType: "joggers", color: "black"),
            priceRange: PriceRange(low: 65, median: 125, high: 185, currency: "USD"),
            confidence: Confidence(score: 62, level: .medium, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "partial"),
                ConfidenceFactor(name: "compDepth", value: "12 comps"),
                ConfidenceFactor(name: "compVariance", value: "moderate")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#1A1A1A", secondary: "#333333"),
            corrected: false
        ),
        SavedItem(
            id: "item_003",
            timestamp: Date().addingTimeInterval(-86400),
            identification: Identification(brand: "Carhartt", itemName: "Detroit Jacket", category: "Outerwear", garmentType: "jacket", color: "tan"),
            priceRange: PriceRange(low: 195, median: 385, high: 520, currency: "USD"),
            confidence: Confidence(score: 91, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "63 comps"),
                ConfidenceFactor(name: "compVariance", value: "low")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#8B6914", secondary: "#C49B32"),
            corrected: false
        ),
        SavedItem(
            id: "item_004",
            timestamp: Date().addingTimeInterval(-86400 * 5),
            identification: Identification(brand: "The North Face", itemName: "Nuptse 700 Puffer", category: "Outerwear", garmentType: "jacket", color: "black"),
            priceRange: PriceRange(low: 420, median: 745, high: 950, currency: "USD"),
            confidence: Confidence(score: 94, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "89 comps"),
                ConfidenceFactor(name: "compVariance", value: "low")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#0D0D0D", secondary: "#2A2A2A"),
            corrected: false
        ),
        SavedItem(
            id: "item_005",
            timestamp: Date().addingTimeInterval(-86400 * 4),
            identification: Identification(brand: "Polo Ralph Lauren", itemName: "Cashmere Cable Knit", category: "Tops", garmentType: "sweater", color: "cream"),
            priceRange: PriceRange(low: 55, median: 135, high: 195, currency: "USD"),
            confidence: Confidence(score: 71, level: .medium, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "partial"),
                ConfidenceFactor(name: "compDepth", value: "24 comps"),
                ConfidenceFactor(name: "compVariance", value: "moderate")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#E8DCC8", secondary: "#F5EDE0"),
            corrected: true
        ),
        SavedItem(
            id: "item_006",
            timestamp: Date().addingTimeInterval(-86400 * 6),
            identification: Identification(brand: "Levi's", itemName: "Vintage 501 Selvedge", category: "Bottoms", garmentType: "jeans", color: "indigo"),
            priceRange: PriceRange(low: 115, median: 225, high: 320, currency: "USD"),
            confidence: Confidence(score: 78, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "156 comps"),
                ConfidenceFactor(name: "compVariance", value: "moderate")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#1B2A4A", secondary: "#2E4470"),
            corrected: false
        ),
        SavedItem(
            id: "item_007",
            timestamp: Date().addingTimeInterval(-3600 * 5),
            identification: Identification(brand: "Arc'teryx", itemName: "Atom LT Hoody", category: "Outerwear", garmentType: "jacket", color: "pilot"),
            priceRange: PriceRange(low: 245, median: 465, high: 620, currency: "USD"),
            confidence: Confidence(score: 89, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "34 comps"),
                ConfidenceFactor(name: "compVariance", value: "low")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#2B3D4F", secondary: "#4A6B8A"),
            corrected: false
        ),
        SavedItem(
            id: "item_008",
            timestamp: Date().addingTimeInterval(-86400 * 7),
            identification: Identification(brand: "Burberry", itemName: "Wool Trench Coat", category: "Outerwear", garmentType: "coat", color: "camel"),
            priceRange: PriceRange(low: 320, median: 585, high: 780, currency: "USD"),
            confidence: Confidence(score: 83, level: .high, factors: [
                ConfidenceFactor(name: "tagExtraction", value: "strong"),
                ConfidenceFactor(name: "compDepth", value: "41 comps"),
                ConfidenceFactor(name: "compVariance", value: "moderate")
            ]),
            thumbnailColor: ThumbnailColor(primary: "#8B7355", secondary: "#C4A97D"),
            corrected: false
        ),
    ]

    // MARK: - Portfolio Value Chart Data

    static var portfolioChartData: [PriceDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var points: [PriceDataPoint] = []

        // Chart shows portfolio growth over time ending at current totalValue
        let finalValue = totalValue
        let values: [Double] = [
            185, 310, 480, 620, 780, 950, 1120,
            1280, 1420, 1560, 1680, 1820, 1940,
            2050, 2140, 2220, 2310, 2390, 2460,
            2520, 2580, 2640, 2710, 2780, finalValue
        ]

        for (index, value) in values.enumerated() {
            let daysAgo = values.count - 1 - index
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                points.append(PriceDataPoint(date: date, value: value))
            }
        }

        return points
    }

    // MARK: - Computed Stats

    static var totalValue: Double {
        savedItems.reduce(0) { $0 + $1.priceRange.median }
    }

    static var totalSpent: Double { 345 }

    static var averageValue: Double {
        totalValue / Double(savedItems.count)
    }

    static var roiPercent: Double {
        ((totalValue - totalSpent) / totalSpent) * 100
    }
}
