import SwiftUI

/// Paywall tier comparison card for Free and Pro plans.
/// Supports visual selection states, "Most Popular" badge, and glassmorphic styling for premium tiers.
struct PaywallPlanCard: View {
    let planName: String
    let price: String
    let priceSubtext: String?
    let features: [PaywallFeature]
    let isCurrentPlan: Bool
    let isSelected: Bool
    let isMostPopular: Bool
    let onSelect: () -> Void

    @State private var isPressed = false

    private var isFree: Bool {
        planName.lowercased().contains("free")
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .top) {
                // Most Popular badge (overlaps top edge)
                if isMostPopular {
                    mostPopularBadge
                        .offset(y: -12)
                        .zIndex(1)
                }

                // Card content
                VStack(alignment: .leading, spacing: TFSpacing.md) {
                    // Plan name
                    Text(planName)
                        .font(TFFont.title2)
                        .foregroundStyle(titleColor)

                    // Price
                    HStack(alignment: .firstTextBaseline, spacing: TFSpacing.xs) {
                        Text(price)
                            .font(TFFont.display)
                            .foregroundStyle(priceColor)
                            .monospacedDigit()

                        if let priceSubtext {
                            Text(priceSubtext)
                                .font(TFFont.body)
                                .foregroundStyle(TFColor.textSecondary)
                        }
                    }

                    Divider()
                        .background(TFColor.borderSubtle)
                        .padding(.vertical, TFSpacing.xs)

                    // Features list
                    VStack(alignment: .leading, spacing: TFSpacing.sm) {
                        ForEach(features) { feature in
                            featureRow(feature)
                        }
                    }

                    Spacer(minLength: TFSpacing.md)

                    // Call-to-action or status
                    if isCurrentPlan {
                        currentPlanLabel
                    } else if !isFree {
                        ActionButton(
                            "Start Free Trial",
                            style: .primary,
                            size: .large,
                            action: onSelect
                        )
                    }
                }
                .padding(TFSpacing.lg)
                .padding(.top, isMostPopular ? TFSpacing.md : 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: 200)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: TFRadius.large))
                .overlay {
                    RoundedRectangle(cornerRadius: TFRadius.large)
                        .stroke(borderColor, lineWidth: borderWidth)
                }
                .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            }
        }
        .buttonStyle(PlanCardButtonStyle(isPressed: $isPressed))
        .disabled(isCurrentPlan)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isCurrentPlan ? "" : "Selects \(planName) plan")
        .accessibilityAddTraits(isCurrentPlan ? [] : [.isButton])
    }

    // MARK: - Subviews

    private var mostPopularBadge: some View {
        Text("Most Popular")
            .font(TFFont.caption)
            .foregroundStyle(.white)
            .textCase(.uppercase)
            .padding(.horizontal, TFSpacing.md)
            .padding(.vertical, TFSpacing.xs)
            .background(TFColor.gold)
            .clipShape(RoundedRectangle(cornerRadius: TFRadius.pill))
    }

    private func featureRow(_ feature: PaywallFeature) -> some View {
        HStack(alignment: .top, spacing: TFSpacing.sm) {
            Image(systemName: feature.isIncluded ? TFIcon.featureIncluded : TFIcon.featureExcluded)
                .font(.system(size: 18))
                .foregroundStyle(feature.isIncluded ? TFColor.gainGreen : Color.tfTextTertiary)
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            Text(feature.text)
                .font(TFFont.body)
                .foregroundStyle(feature.isIncluded ? TFColor.textPrimary : TFColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentPlanLabel: some View {
        HStack {
            Spacer()
            Text("Current Plan")
                .font(TFFont.caption)
                .foregroundStyle(TFColor.textSecondary)
                .padding(.horizontal, TFSpacing.md)
                .padding(.vertical, TFSpacing.sm)
                .background(TFColor.textSecondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: TFRadius.small))
            Spacer()
        }
    }

    // MARK: - Styling Helpers

    private var titleColor: Color {
        if isFree {
            return TFColor.textSecondary
        }
        return TFColor.textPrimary
    }

    private var priceColor: Color {
        if isFree {
            return TFColor.textPrimary
        }
        if isSelected {
            return TFColor.gold
        }
        return TFColor.textPrimary
    }

    private var borderColor: Color {
        if isFree {
            return TFColor.borderSubtle
        }
        if isSelected {
            return TFColor.gold.opacity(0.6)
        }
        return TFColor.gold.opacity(0.3)
    }

    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 1.0
    }

    private var shadowColor: Color {
        if isSelected && !isFree {
            return TFColor.gold.opacity(0.3)
        }
        return Color.clear
    }

    private var cardBackground: some View {
        Group {
            if isFree {
                TFColor.cardSurface
            } else if isSelected {
                // Glassmorphic background for selected Pro
                ZStack {
                    TFColor.cardSurface
                    LinearGradient(
                        colors: [
                            TFColor.gold.opacity(0.08),
                            TFColor.gold.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                TFColor.cardSurface
            }
        }
    }

    private var accessibilityLabel: String {
        let statusText = isCurrentPlan ? "Current plan" : ""
        let popularText = isMostPopular ? "Most popular" : ""
        let featuresText = features
            .map { "\($0.isIncluded ? "Included" : "Not included"): \($0.text)" }
            .joined(separator: ", ")

        return "\(planName) \(popularText) \(statusText), \(price) \(priceSubtext ?? ""), Features: \(featuresText)"
    }
}

// MARK: - Button Style

/// Custom button style to track press state without default animations
private struct PlanCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Free and Pro Plans") {
    VStack(spacing: TFSpacing.lg) {
        // Free plan (current)
        PaywallPlanCard(
            planName: "Free",
            price: "$0",
            priceSubtext: nil,
            features: [
                PaywallFeature(text: "5 scans per day", isIncluded: true),
                PaywallFeature(text: "Basic price estimates", isIncluded: true),
                PaywallFeature(text: "Save to collection", isIncluded: true),
                PaywallFeature(text: "Unlimited scans", isIncluded: false),
                PaywallFeature(text: "Advanced analytics", isIncluded: false),
                PaywallFeature(text: "Priority support", isIncluded: false)
            ],
            isCurrentPlan: true,
            isSelected: false,
            isMostPopular: false,
            onSelect: { print("Free selected") }
        )

        // Pro plan (most popular, selected)
        PaywallPlanCard(
            planName: "Pro",
            price: "$9.99",
            priceSubtext: "/month",
            features: [
                PaywallFeature(text: "Unlimited scans", isIncluded: true),
                PaywallFeature(text: "Advanced price analytics", isIncluded: true),
                PaywallFeature(text: "Price history tracking", isIncluded: true),
                PaywallFeature(text: "Export to CSV", isIncluded: true),
                PaywallFeature(text: "Priority support", isIncluded: true),
                PaywallFeature(text: "Early access to features", isIncluded: true)
            ],
            isCurrentPlan: false,
            isSelected: true,
            isMostPopular: true,
            onSelect: { print("Pro selected") }
        )
    }
    .padding(TFSpacing.lg)
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Pro Plan States") {
    VStack(spacing: TFSpacing.lg) {
        // Unselected Pro
        PaywallPlanCard(
            planName: "Pro",
            price: "$9.99",
            priceSubtext: "/month",
            features: [
                PaywallFeature(text: "Unlimited scans", isIncluded: true),
                PaywallFeature(text: "Advanced analytics", isIncluded: true),
                PaywallFeature(text: "Priority support", isIncluded: true)
            ],
            isCurrentPlan: false,
            isSelected: false,
            isMostPopular: true,
            onSelect: { print("Select Pro") }
        )

        // Selected Pro
        PaywallPlanCard(
            planName: "Pro",
            price: "$9.99",
            priceSubtext: "/month",
            features: [
                PaywallFeature(text: "Unlimited scans", isIncluded: true),
                PaywallFeature(text: "Advanced analytics", isIncluded: true),
                PaywallFeature(text: "Priority support", isIncluded: true)
            ],
            isCurrentPlan: false,
            isSelected: true,
            isMostPopular: true,
            onSelect: { print("Pro selected") }
        )

        // Current Pro plan
        PaywallPlanCard(
            planName: "Pro",
            price: "$9.99",
            priceSubtext: "/month",
            features: [
                PaywallFeature(text: "Unlimited scans", isIncluded: true),
                PaywallFeature(text: "Advanced analytics", isIncluded: true),
                PaywallFeature(text: "Priority support", isIncluded: true)
            ],
            isCurrentPlan: true,
            isSelected: false,
            isMostPopular: false,
            onSelect: { print("Already on Pro") }
        )
    }
    .padding(TFSpacing.lg)
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    VStack(spacing: TFSpacing.lg) {
        PaywallPlanCard(
            planName: "Free",
            price: "$0",
            priceSubtext: nil,
            features: [
                PaywallFeature(text: "5 scans per day", isIncluded: true),
                PaywallFeature(text: "Unlimited scans", isIncluded: false)
            ],
            isCurrentPlan: false,
            isSelected: false,
            isMostPopular: false,
            onSelect: {}
        )

        PaywallPlanCard(
            planName: "Pro",
            price: "$9.99",
            priceSubtext: "/month",
            features: [
                PaywallFeature(text: "Unlimited scans", isIncluded: true),
                PaywallFeature(text: "Advanced analytics", isIncluded: true)
            ],
            isCurrentPlan: false,
            isSelected: true,
            isMostPopular: true,
            onSelect: {}
        )
    }
    .padding(TFSpacing.lg)
    .background(Color.tfBackground)
    .preferredColorScheme(.light)
}
