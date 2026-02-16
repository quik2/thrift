import SwiftUI

struct CollectionView: View {
    @State private var viewModel = CollectionViewModel()
    @Namespace private var filterNamespace

    private let columns = [
        GridItem(.flexible(), spacing: TFSpacing.md),
        GridItem(.flexible(), spacing: TFSpacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                heroValueSection
                chartSection
                statsSection
                filterSection
                gridSection
            }
            .padding(.bottom, TFSpacing.xxl)
        }
        .background(backgroundGradient)
    }

    // MARK: - Background

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundGradient: some View {
        ZStack {
            Color.tfBackground

            // Subtle green halo top-left
            RadialGradient(
                colors: [TFColor.gainGreen.opacity(colorScheme == .dark ? 0.08 : 0.12), .clear],
                center: UnitPoint(x: 0.1, y: -0.05),
                startRadius: 0,
                endRadius: 600
            )

            // Subtle gold halo top-right
            RadialGradient(
                colors: [TFColor.gold.opacity(colorScheme == .dark ? 0.05 : 0.10), .clear],
                center: UnitPoint(x: 0.95, y: 0.02),
                startRadius: 0,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        AppHeader(
            title: "My Finds",
            subtitle: "\(viewModel.items.count) items · \(viewModel.totalValue) value",
            trailingIcon: "person.circle",
            trailingAction: {}
        )
    }

    // MARK: - Hero Value

    private var heroValueSection: some View {
        VStack(spacing: TFSpacing.xs) {
            Text(viewModel.totalValue)
                .font(.system(size: 44, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(TFColor.gainGreen)
                .shadow(color: TFColor.gainGreen.opacity(0.3), radius: 20, y: 4)

            Text("Total Collection Value")
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextSecondary)

            HStack(spacing: TFSpacing.sm) {
                Text("\(viewModel.totalProfit) from \(viewModel.totalSpent) spent")
                    .font(TFFont.micro)
                    .foregroundStyle(Color.tfTextTertiary)

                Text(viewModel.totalROI)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(TFColor.gainGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(TFColor.gainGreen.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TFSpacing.md)
    }

    // MARK: - Chart

    private var chartSection: some View {
        PriceHistoryChart(dataPoints: viewModel.chartData)
            .padding(.horizontal, TFSpacing.md)
            .padding(.bottom, TFSpacing.sm)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: TFSpacing.sm) {
            StatCard(
                value: viewModel.itemCount,
                label: "Items",
                trend: .up,
                trendValue: "+2 this week"
            )
            StatCard(
                value: viewModel.avgValue,
                label: "Avg Value",
                trend: .up,
                trendValue: "+8%"
            )
            StatCard(
                value: "$745",
                label: "Best Find",
                trend: .up,
                trendValue: "Nuptse 700"
            )
        }
        .padding(.horizontal, TFSpacing.md)
        .padding(.bottom, TFSpacing.sm)
    }

    // MARK: - Filters

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TFSpacing.sm) {
                ForEach(CollectionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, TFSpacing.md)
        }
        .padding(.bottom, TFSpacing.sm)
    }

    // MARK: - Grid

    private var gridSection: some View {
        Group {
            if viewModel.filteredItems.isEmpty {
                EmptyStateCard(
                    icon: "magnifyingglass",
                    title: "No items here",
                    message: "Try a different filter or scan more items to build your collection."
                )
                .frame(height: 240)
            } else {
                LazyVGrid(columns: columns, spacing: TFSpacing.md) {
                    ForEach(viewModel.filteredItems) { item in
                        CollectionCard(
                            gradientColors: (
                                Color(hex: item.thumbnailColor.primary),
                                Color(hex: item.thumbnailColor.secondary)
                            ),
                            garmentIcon: TFIcon.garmentIcon(for: item.identification.garmentType),
                            confidenceLevel: item.confidence.level,
                            confidenceScore: item.confidence.score,
                            brand: item.identification.brand,
                            itemName: item.identification.itemName,
                            price: formatPrice(item.priceRange.median),
                            priceRange: "\(formatPrice(item.priceRange.low)) – \(formatPrice(item.priceRange.high))",
                            isLowConfidence: item.confidence.level == .low || item.confidence.level == .insufficient,
                            isCorrected: item.corrected,
                            onTap: {
                                // Item detail navigation
                            }
                        )
                    }
                }
                .padding(.horizontal, TFSpacing.md)
            }
        }
    }
    private func formatPrice(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(value))"
        }
        return String(format: "$%.2f", value)
    }
}

#Preview {
    CollectionView()
        .preferredColorScheme(.dark)
}
