import SwiftUI

/// Skeleton loading placeholder for stats header
///
/// Displays a shimmer-animated horizontal row of 3 stat cards that matches
/// the layout of the stats overview (e.g., portfolio metrics, collection stats).
struct StatsHeaderSkeleton: View {
    var body: some View {
        HStack(spacing: TFSpacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                StatCardSkeletonCell()
            }
        }
        .padding(.horizontal, TFSpacing.md)
        .shimmer()
        .allowsHitTesting(false)
        .accessibilityLabel("Loading stats")
    }
}

// MARK: - Cell Component

/// Individual stat card skeleton cell
private struct StatCardSkeletonCell: View {
    var body: some View {
        VStack(spacing: TFSpacing.xs) {
            // Value placeholder (60% width, large text)
            GeometryReader { geometry in
                SkeletonBlock(
                    width: geometry.size.width * 0.6,
                    height: 28,
                    cornerRadius: TFRadius.small
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 28)

            // Label placeholder (80% width, small text)
            GeometryReader { geometry in
                SkeletonBlock(
                    width: geometry.size.width * 0.8,
                    height: 12,
                    cornerRadius: TFRadius.small
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(height: 12)
        }
        .padding(.horizontal, TFSpacing.sm)
        .padding(.vertical, TFSpacing.sm)
        .frame(maxWidth: .infinity)
        .tfGlassCard(cornerRadius: TFRadius.medium)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    ZStack {
        TFColor.background
            .ignoresSafeArea()

        VStack(spacing: TFSpacing.lg) {
            StatsHeaderSkeleton()

            Spacer()
        }
        .padding(.top, TFSpacing.xl)
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: TFSpacing.lg) {
            StatsHeaderSkeleton()

            Spacer()
        }
        .padding(.top, TFSpacing.xl)
    }
    .preferredColorScheme(.dark)
}

#Preview("Single Card") {
    ZStack {
        TFColor.background
            .ignoresSafeArea()

        StatCardSkeletonCell()
            .frame(width: 120)
    }
}

#Preview("With Content Below") {
    ScrollView {
        VStack(spacing: TFSpacing.lg) {
            StatsHeaderSkeleton()

            // Simulated content below
            VStack(spacing: TFSpacing.md) {
                ForEach(0..<5) { _ in
                    RoundedRectangle(cornerRadius: TFRadius.medium)
                        .fill(TFColor.cardSurface)
                        .frame(height: 80)
                        .padding(.horizontal, TFSpacing.md)
                }
            }
        }
        .padding(.vertical, TFSpacing.md)
    }
    .background(TFColor.background)
}
