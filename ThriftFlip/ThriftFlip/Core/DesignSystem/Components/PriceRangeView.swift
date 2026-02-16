import SwiftUI

enum PriceBlockStyle {
    case hero
    case inline
}

struct PriceRangeBlock: View {
    let priceRange: PriceRange
    let confidence: ConfidenceLevel
    let style: PriceBlockStyle

    init(priceRange: PriceRange, confidence: ConfidenceLevel, style: PriceBlockStyle = .hero) {
        self.priceRange = priceRange
        self.confidence = confidence
        self.style = style
    }

    private var isLowConfidence: Bool { confidence == .low }

    var body: some View {
        VStack(alignment: style == .hero ? .center : .leading, spacing: TFSpacing.xs) {
            medianRow
            rangeRow
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var medianRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(formatPrice(priceRange.median))
                .font(style == .hero ? TFFont.display : TFFont.title2)
                .fontDesign(.default)
                .monospacedDigit()
                .foregroundStyle(isLowConfidence ? Color.tfTextSecondary : Color.tfTextPrimary)

            if isLowConfidence {
                Text("est.")
                    .font(style == .hero ? TFFont.caption : TFFont.micro)
                    .foregroundStyle(Color.tfTextTertiary)
            }
        }
    }

    private var rangeRow: some View {
        Text("Low \(formatPrice(priceRange.low)) — High \(formatPrice(priceRange.high))")
            .font(style == .hero ? TFFont.caption : TFFont.micro)
            .foregroundStyle(isLowConfidence ? Color.tfTextTertiary : Color.tfTextSecondary)
    }

    private var accessibilityText: String {
        let prefix = isLowConfidence ? "Rough estimate" : "Estimated value"
        return "\(prefix) \(formatPrice(priceRange.median)), range \(formatPrice(priceRange.low)) to \(formatPrice(priceRange.high))"
    }

    private func formatPrice(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(value))"
        }
        return String(format: "$%.2f", value)
    }
}

#Preview {
    VStack(spacing: 32) {
        PriceRangeBlock(
            priceRange: PriceRange(low: 42, median: 67.50, high: 95, currency: "USD"),
            confidence: .high
        )
        PriceRangeBlock(
            priceRange: PriceRange(low: 15, median: 40, high: 120, currency: "USD"),
            confidence: .low
        )
        PriceRangeBlock(
            priceRange: PriceRange(low: 25, median: 45, high: 78, currency: "USD"),
            confidence: .medium,
            style: .inline
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
