import SwiftUI

/// A generic, reusable card component for displaying items in a collection grid.
/// Decoupled from domain models — accepts pre-formatted data as primitives.
struct CollectionCard: View {
    let gradientColors: (Color, Color)  // Thumbnail gradient (primary, secondary)
    let garmentIcon: String             // SF Symbol name for overlay
    let confidenceLevel: ConfidenceLevel
    let confidenceScore: Int
    let brand: String
    let itemName: String
    let price: String                   // Pre-formatted, e.g. "$175"
    let priceRange: String              // Pre-formatted, e.g. "$95 – $245"
    let isLowConfidence: Bool
    let isCorrected: Bool
    let onTap: () -> Void

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
                    .stroke(TFColor.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(CollectionCardButtonStyle())
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens item detail")
    }

    // MARK: - Thumbnail

    private var thumbnailArea: some View {
        ZStack {
            // Gradient placeholder thumbnail
            LinearGradient(
                colors: [gradientColors.0, gradientColors.1],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle clothing icon overlay
            Image(systemName: garmentIcon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.2))
        }
        .aspectRatio(4/3, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            ConfidenceBadge(
                level: confidenceLevel,
                score: confidenceScore,
                style: .dotOnly
            )
            .padding(6)
            .background(.black.opacity(0.35))
            .clipShape(Circle())
            .padding(TFSpacing.sm)
        }
        .overlay(alignment: .topLeading) {
            if isCorrected {
                Text("Corrected")
                    .font(TFFont.micro.weight(.semibold))
                    .foregroundStyle(Color.tfBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(TFColor.gold.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(TFSpacing.sm)
            }
        }
    }

    // MARK: - Content

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: TFSpacing.xs) {
            Text(brand)
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextPrimary)
                .lineLimit(1)

            Text(itemName)
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextSecondary)
                .lineLimit(1)

            Spacer().frame(height: TFSpacing.xs)

            // Price with monospaced digits and optional "est." suffix for low confidence
            Text(price)
                .font(TFFont.headline)
                .monospacedDigit()
                .foregroundStyle(isLowConfidence ? Color.tfTextSecondary : Color.tfTextPrimary)
            + Text(isLowConfidence ? " est." : "")
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextTertiary)

            Text(priceRange)
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextTertiary)
        }
        .padding(.horizontal, TFSpacing.sm)
        .padding(.vertical, TFSpacing.sm)
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        var text = "\(brand) \(itemName), estimated \(price), \(confidenceLevel.rawValue) confidence"
        if isCorrected { text += ", corrected" }
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

// MARK: - Previews

#Preview("Collection Card Grid - Light Mode") {
    ScrollView {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: TFSpacing.md),
                GridItem(.flexible(), spacing: TFSpacing.md)
            ],
            spacing: TFSpacing.md
        ) {
            // High confidence card
            CollectionCard(
                gradientColors: (Color(hex: "#1B3A5C"), Color(hex: "#2D5F8A")),
                garmentIcon: "cloud.fill",
                confidenceLevel: .high,
                confidenceScore: 92,
                brand: "Patagonia",
                itemName: "Better Sweater 1/4 Zip",
                price: "$175",
                priceRange: "$95 – $245",
                isLowConfidence: false,
                isCorrected: false,
                onTap: {}
            )

            // Medium confidence card
            CollectionCard(
                gradientColors: (Color(hex: "#4A5F3D"), Color(hex: "#6B8A5A")),
                garmentIcon: "figure.walk",
                confidenceLevel: .medium,
                confidenceScore: 68,
                brand: "Lululemon",
                itemName: "ABC Joggers",
                price: "$85",
                priceRange: "$65 – $110",
                isLowConfidence: false,
                isCorrected: false,
                onTap: {}
            )

            // Low confidence card (with "est." suffix)
            CollectionCard(
                gradientColors: (Color(hex: "#5C3A1B"), Color(hex: "#8A5F2D")),
                garmentIcon: "tshirt.fill",
                confidenceLevel: .low,
                confidenceScore: 42,
                brand: "Nike",
                itemName: "Dri-FIT Training Tee",
                price: "$35",
                priceRange: "$20 – $55",
                isLowConfidence: true,
                isCorrected: false,
                onTap: {}
            )

            // Corrected card (high confidence)
            CollectionCard(
                gradientColors: (Color(hex: "#3D1B5C"), Color(hex: "#5A2D8A")),
                garmentIcon: "cloud.fill",
                confidenceLevel: .high,
                confidenceScore: 87,
                brand: "Arc'teryx",
                itemName: "Atom LT Hoody",
                price: "$225",
                priceRange: "$180 – $280",
                isLowConfidence: false,
                isCorrected: true,
                onTap: {}
            )
        }
        .padding(TFSpacing.md)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.light)
}

#Preview("Collection Card Grid - Dark Mode") {
    ScrollView {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: TFSpacing.md),
                GridItem(.flexible(), spacing: TFSpacing.md)
            ],
            spacing: TFSpacing.md
        ) {
            // High confidence card
            CollectionCard(
                gradientColors: (Color(hex: "#1B3A5C"), Color(hex: "#2D5F8A")),
                garmentIcon: "cloud.fill",
                confidenceLevel: .high,
                confidenceScore: 92,
                brand: "Patagonia",
                itemName: "Better Sweater 1/4 Zip",
                price: "$175",
                priceRange: "$95 – $245",
                isLowConfidence: false,
                isCorrected: false,
                onTap: {}
            )

            // Medium confidence card
            CollectionCard(
                gradientColors: (Color(hex: "#4A5F3D"), Color(hex: "#6B8A5A")),
                garmentIcon: "figure.walk",
                confidenceLevel: .medium,
                confidenceScore: 68,
                brand: "Lululemon",
                itemName: "ABC Joggers",
                price: "$85",
                priceRange: "$65 – $110",
                isLowConfidence: false,
                isCorrected: false,
                onTap: {}
            )

            // Low confidence card (with "est." suffix)
            CollectionCard(
                gradientColors: (Color(hex: "#5C3A1B"), Color(hex: "#8A5F2D")),
                garmentIcon: "tshirt.fill",
                confidenceLevel: .low,
                confidenceScore: 42,
                brand: "Nike",
                itemName: "Dri-FIT Training Tee",
                price: "$35",
                priceRange: "$20 – $55",
                isLowConfidence: true,
                isCorrected: false,
                onTap: {}
            )

            // Corrected card (high confidence)
            CollectionCard(
                gradientColors: (Color(hex: "#3D1B5C"), Color(hex: "#5A2D8A")),
                garmentIcon: "cloud.fill",
                confidenceLevel: .high,
                confidenceScore: 87,
                brand: "Arc'teryx",
                itemName: "Atom LT Hoody",
                price: "$225",
                priceRange: "$180 – $280",
                isLowConfidence: false,
                isCorrected: true,
                onTap: {}
            )
        }
        .padding(TFSpacing.md)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
