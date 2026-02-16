import SwiftUI

enum BadgeStyle {
    case full
    case compact
    case dotOnly
}

struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    let score: Int
    let style: BadgeStyle

    init(level: ConfidenceLevel, score: Int, style: BadgeStyle = .full) {
        self.level = level
        self.score = score
        self.style = style
    }

    private var badgeColor: Color {
        switch level {
        case .high: return TFColor.gainGreen
        case .medium: return TFColor.gold
        case .low: return TFColor.warning
        case .insufficient: return Color.tfTextSecondary
        }
    }

    private var levelText: String {
        switch level {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .insufficient: return "Insufficient"
        }
    }

    var body: some View {
        switch style {
        case .full:
            fullBadge
        case .compact:
            compactBadge
        case .dotOnly:
            dotOnlyBadge
        }
    }

    private var fullBadge: some View {
        HStack(spacing: TFSpacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)

            Text("\(levelText) · \(score)%")
                .font(TFFont.caption)
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, TFSpacing.sm)
        .padding(.vertical, TFSpacing.xs)
        .background(badgeColor.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Confidence: \(levelText), \(score) percent")
    }

    private var compactBadge: some View {
        HStack(spacing: TFSpacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)

            Text("\(score)%")
                .font(TFFont.micro)
                .foregroundStyle(badgeColor)
        }
        .padding(.leading, TFSpacing.xs)
        .padding(.trailing, TFSpacing.sm)
        .padding(.vertical, TFSpacing.xs)
        .background(badgeColor.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("\(levelText) confidence, \(score) percent")
    }

    private var dotOnlyBadge: some View {
        Circle()
            .fill(badgeColor)
            .frame(width: 8, height: 8)
            .accessibilityLabel("\(levelText) confidence")
    }
}

#Preview {
    VStack(spacing: 16) {
        ConfidenceBadge(level: .high, score: 87)
        ConfidenceBadge(level: .medium, score: 62)
        ConfidenceBadge(level: .low, score: 31)
        ConfidenceBadge(level: .insufficient, score: 12)

        HStack(spacing: 12) {
            ConfidenceBadge(level: .high, score: 87, style: .compact)
            ConfidenceBadge(level: .medium, score: 62, style: .compact)
            ConfidenceBadge(level: .low, score: 31, style: .compact)
            ConfidenceBadge(level: .insufficient, score: 12, style: .compact)
        }

        HStack(spacing: 12) {
            ConfidenceBadge(level: .high, score: 87, style: .dotOnly)
            ConfidenceBadge(level: .medium, score: 62, style: .dotOnly)
            ConfidenceBadge(level: .low, score: 31, style: .dotOnly)
            ConfidenceBadge(level: .insufficient, score: 12, style: .dotOnly)
        }
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
