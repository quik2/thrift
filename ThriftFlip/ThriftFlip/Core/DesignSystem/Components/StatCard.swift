import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    let trend: StatTrend?
    let trendValue: String?

    init(
        value: String,
        label: String,
        trend: StatTrend? = nil,
        trendValue: String? = nil
    ) {
        self.value = value
        self.label = label
        self.trend = trend
        self.trendValue = trendValue
    }

    private var trendColor: Color {
        switch trend {
        case .up: return TFColor.gainGreen
        case .down: return TFColor.warning
        case .neutral: return Color.tfTextTertiary
        case .none: return .clear
        }
    }

    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        case .none: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TFSpacing.xs) {
            Text(value)
                .font(TFFont.title2)
                .monospacedDigit()
                .foregroundStyle(Color.tfTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(TFFont.micro)
                .foregroundStyle(Color.tfTextSecondary)
                .lineLimit(1)

            if let trend, let trendValue {
                HStack(spacing: 2) {
                    Image(systemName: trendIcon)
                        .font(TFFont.micro.weight(.semibold))
                    Text(trendValue)
                        .font(TFFont.micro)
                }
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TFSpacing.sm)
        .padding(.vertical, TFSpacing.sm)
        .tfGlassCard(cornerRadius: TFRadius.medium)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: 8) {
        StatCard(value: "24", label: "Total Items", trend: .up, trendValue: "+3")
        StatCard(value: "$67", label: "Avg Value", trend: .up, trendValue: "+12%")
        StatCard(value: "🔥 7", label: "Day Streak")
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
