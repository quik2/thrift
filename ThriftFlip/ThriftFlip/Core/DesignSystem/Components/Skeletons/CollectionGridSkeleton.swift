import SwiftUI

/// Skeleton loading placeholder for collection grid
///
/// Displays a shimmer-animated 2-column grid that matches the layout
/// of collection item cards (e.g., CollectionView, SoldItemsGrid).
struct CollectionGridSkeleton: View {
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: TFSpacing.md),
                GridItem(.flexible(), spacing: TFSpacing.md)
            ],
            spacing: TFSpacing.md
        ) {
            ForEach(0..<6, id: \.self) { _ in
                CollectionCardSkeletonCell()
            }
        }
        .padding(.horizontal, TFSpacing.md)
        .shimmer()
        .allowsHitTesting(false)
        .accessibilityLabel("Loading collection")
    }
}

// MARK: - Cell Component

/// Individual collection card skeleton cell
private struct CollectionCardSkeletonCell: View {
    var body: some View {
        VStack(spacing: 0) {
            // Image area (4:3 aspect ratio)
            GeometryReader { geometry in
                SkeletonBlock(
                    width: geometry.size.width,
                    height: geometry.size.width * 0.75, // 4:3 aspect ratio
                    cornerRadius: 0 // Top corners only handled by card
                )
            }
            .aspectRatio(4/3, contentMode: .fit)

            // Content area with text placeholders
            VStack(alignment: .leading, spacing: TFSpacing.xs) {
                // Title line (70% width)
                GeometryReader { geometry in
                    SkeletonBlock(
                        width: geometry.size.width * 0.7,
                        height: 14,
                        cornerRadius: TFRadius.small
                    )
                }
                .frame(height: 14)

                // Subtitle line (50% width)
                GeometryReader { geometry in
                    SkeletonBlock(
                        width: geometry.size.width * 0.5,
                        height: 12,
                        cornerRadius: TFRadius.small
                    )
                }
                .frame(height: 12)

                // Price line (40% width, taller)
                GeometryReader { geometry in
                    SkeletonBlock(
                        width: geometry.size.width * 0.4,
                        height: 20,
                        cornerRadius: TFRadius.small
                    )
                }
                .frame(height: 20)
            }
            .padding(TFSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(TFColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: TFRadius.large))
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    ScrollView {
        CollectionGridSkeleton()
            .padding(.vertical, TFSpacing.md)
    }
    .background(TFColor.background)
}

#Preview("Dark Mode") {
    ScrollView {
        CollectionGridSkeleton()
            .padding(.vertical, TFSpacing.md)
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Single Card") {
    ZStack {
        TFColor.background
            .ignoresSafeArea()

        CollectionCardSkeletonCell()
            .frame(width: 180)
            .shimmer()
    }
}
