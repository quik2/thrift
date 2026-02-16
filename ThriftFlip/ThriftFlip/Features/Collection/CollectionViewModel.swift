import SwiftUI

@MainActor @Observable
final class CollectionViewModel {
    var items: [SavedItem] = MockData.savedItems
    var selectedFilter: CollectionFilter = .all
    var chartData: [PriceDataPoint] = MockData.portfolioChartData

    var filteredItems: [SavedItem] {
        switch selectedFilter {
        case .all:
            return items
        case .highConfidence:
            return items.filter { $0.confidence.level == .high }
        case .needsReview:
            return items.filter { $0.confidence.level == .low || $0.confidence.level == .medium }
        case .listed:
            return []  // No listed items in MVP mock
        }
    }

    var totalValue: String {
        formatCurrency(MockData.totalValue)
    }

    var totalROI: String {
        String(format: "+%.0f%%", MockData.roiPercent)
    }

    var totalProfit: String {
        "+\(formatCurrency(MockData.totalValue - MockData.totalSpent))"
    }

    var totalSpent: String {
        formatCurrency(MockData.totalSpent)
    }

    var itemCount: String {
        "\(items.count)"
    }

    var avgValue: String {
        formatCurrency(MockData.averageValue)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

enum CollectionFilter: String, CaseIterable {
    case all = "All"
    case highConfidence = "High Confidence"
    case needsReview = "Needs Review"
    case listed = "Listed"
}
