import SwiftUI

struct CollectionCard: View {
    let item: SavedItem
    let onTap: () -> Void

    private var isLowConfidence: Bool { item.confidence.level == .low }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnailArea
                contentArea
            }
            .background(Color.tfCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: TFRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: TFRadius.large)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(CollectionCardButtonStyle())
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens item detail")
    }

    // MARK: - Thumbnail

    private var thumbnailArea: some View {
        GeometryReader { geo in
            ZStack {
                // Gradient placeholder thumbnail
                LinearGradient(
                    colors: [
                        Color(hex: item.thumbnailColor.primary),
                        Color(hex: item.thumbnailColor.secondary)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle clothing icon overlay
                Image(systemName: garmentIcon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.2))

                // Confidence dot overlay — top right
                VStack {
                    HStack {
                        Spacer()
                        ConfidenceBadge(
                            level: item.confidence.level,
                            score: item.confidence.score,
                            style: .dotOnly
                        )
                        .padding(6)
                        .background(.black.opacity(0.35))
                        .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(TFSpacing.sm)

                // Corrected badge — top left
                if item.corrected {
                    VStack {
                        HStack {
                            Text("Corrected")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.tfBackground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(TFColor.gold.opacity(0.85))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(TFSpacing.sm)
                }
            }
            .frame(width: geo.size.width, height: geo.size.width * 0.75)
        }
        .aspectRatio(4/3, contentMode: .fit)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: TFRadius.large,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: TFRadius.large
            )
        )
    }

    // MARK: - Content

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: TFSpacing.xs) {
            Text(item.identification.brand)
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextPrimary)
                .lineLimit(1)

            Text(item.identification.itemName)
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextSecondary)
                .lineLimit(1)

            Spacer().frame(height: TFSpacing.xs)

            Text(formatPrice(item.priceRange.median))
                .font(TFFont.headline)
                .monospacedDigit()
                .foregroundStyle(isLowConfidence ? Color.tfTextSecondary : Color.tfTextPrimary)
            + Text(isLowConfidence ? " est." : "")
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextTertiary)

            Text("\(formatPrice(item.priceRange.low)) – \(formatPrice(item.priceRange.high))")
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextTertiary)
        }
        .padding(.horizontal, TFSpacing.sm)
        .padding(.vertical, TFSpacing.sm)
    }

    // MARK: - Helpers

    private var garmentIcon: String {
        switch item.identification.garmentType.lowercased() {
        case "fleece", "jacket", "coat": return "cloud.fill"
        case "joggers", "pants": return "figure.walk"
        case "shirt", "tee": return "tshirt.fill"
        default: return "hanger"
        }
    }

    private func formatPrice(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(value))"
        }
        return String(format: "$%.2f", value)
    }

    private var accessibilityText: String {
        var text = "\(item.identification.brand) \(item.identification.itemName), estimated \(formatPrice(item.priceRange.median)), \(item.confidence.level.rawValue) confidence"
        if item.corrected { text += ", corrected" }
        return text
    }
}

// MARK: - Button Style

struct CollectionCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
