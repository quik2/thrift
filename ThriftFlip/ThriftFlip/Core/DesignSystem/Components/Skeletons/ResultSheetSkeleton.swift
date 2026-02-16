import SwiftUI

/// Skeleton loading placeholder for ResultBottomSheet
///
/// Displays a shimmer-animated placeholder that matches the 7-row layout
/// of the scan result bottom sheet.
struct ResultSheetSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Title row (name + status icon)
            HStack(spacing: TFSpacing.sm) {
                SkeletonBlock(
                    width: 200,
                    height: 22,
                    cornerRadius: TFRadius.small
                )

                Spacer()

                SkeletonBlock(
                    width: 40,
                    height: 22,
                    cornerRadius: TFRadius.small
                )
            }
            .padding(.bottom, TFSpacing.xs)

            // Row 2: Category
            SkeletonBlock(
                width: 140,
                height: 16,
                cornerRadius: TFRadius.small
            )
            .padding(.bottom, TFSpacing.md)

            // Row 3: Confidence badge
            SkeletonBlock(
                width: 80,
                height: 24,
                cornerRadius: TFRadius.pill
            )
            .padding(.bottom, TFSpacing.md)

            // Row 4: Price section
            VStack(alignment: .leading, spacing: TFSpacing.xs) {
                SkeletonBlock(
                    width: 160,
                    height: 48,
                    cornerRadius: TFRadius.small
                )

                SkeletonBlock(
                    width: 120,
                    height: 16,
                    cornerRadius: TFRadius.small
                )
            }
            .padding(.bottom, TFSpacing.xs)

            // Row 5: Comp depth indicator
            SkeletonBlock(
                width: 100,
                height: 14,
                cornerRadius: TFRadius.small
            )
            .padding(.bottom, TFSpacing.md)

            // Row 6: Comparable items carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TFSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonBlock(
                            width: 160,
                            height: 180,
                            cornerRadius: TFRadius.medium
                        )
                    }
                }
            }
            .padding(.bottom, TFSpacing.lg)

            // Row 7: Action buttons
            HStack(spacing: TFSpacing.sm) {
                SkeletonBlock(
                    width: nil, // Full width in HStack
                    height: 52,
                    cornerRadius: TFRadius.medium
                )

                SkeletonBlock(
                    width: nil, // Full width in HStack
                    height: 52,
                    cornerRadius: TFRadius.medium
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(width: UIScreen.main.bounds.width * 0.48 - TFSpacing.md * 1.5)
            }
        }
        .padding(.horizontal, TFSpacing.lg)
        .shimmer()
        .allowsHitTesting(false)
        .accessibilityLabel("Loading scan result")
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    ZStack {
        TFColor.background
            .ignoresSafeArea()

        ResultSheetSkeleton()
            .padding(.vertical, TFSpacing.xl)
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ResultSheetSkeleton()
            .padding(.vertical, TFSpacing.xl)
    }
    .preferredColorScheme(.dark)
}

#Preview("In Sheet Context") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ZStack {
                TFColor.cardSurface
                    .ignoresSafeArea()

                ResultSheetSkeleton()
                    .presentationDetents([.large])
            }
        }
}
