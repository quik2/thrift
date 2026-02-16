//
//  ComponentCatalog.swift
//  ThriftFlip
//
//  Design System Component Catalog
//  This file contains preview-only content to visualize all design system components.
//  Open in Xcode Canvas to browse the entire design system.
//

import SwiftUI

// MARK: - Preview 1: Tokens

#Preview("Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // Colors Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("Colors")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(alignment: .leading, spacing: TFSpacing.sm) {
                    ColorSwatch(color: TFColor.gainGreen, name: "TFColor.gainGreen")
                    ColorSwatch(color: TFColor.warning, name: "TFColor.warning")
                    ColorSwatch(color: TFColor.gold, name: "TFColor.gold")
                    ColorSwatch(color: Color.tfBackground, name: "Color.tfBackground")
                    ColorSwatch(color: Color.tfCardSurface, name: "Color.tfCardSurface")
                    ColorSwatch(color: Color.tfTextPrimary, name: "Color.tfTextPrimary")
                    ColorSwatch(color: Color.tfTextSecondary, name: "Color.tfTextSecondary")
                    ColorSwatch(color: Color.tfTextTertiary, name: "Color.tfTextTertiary")
                    ColorSwatch(color: TFColor.borderSubtle, name: "TFColor.borderSubtle")
                }
            }

            Divider()

            // Typography Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("Typography")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(alignment: .leading, spacing: TFSpacing.sm) {
                    Text("TFFont.display")
                        .font(TFFont.display)
                    Text("TFFont.title1")
                        .font(TFFont.title1)
                    Text("TFFont.title2")
                        .font(TFFont.title2)
                    Text("TFFont.headline")
                        .font(TFFont.headline)
                    Text("TFFont.body")
                        .font(TFFont.body)
                    Text("TFFont.caption")
                        .font(TFFont.caption)
                    Text("TFFont.micro")
                        .font(TFFont.micro)
                }
            }

            Divider()

            // Spacing Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("Spacing")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(alignment: .leading, spacing: TFSpacing.sm) {
                    SpacingBar(size: TFSpacing.xs, name: "TFSpacing.xs (4pt)")
                    SpacingBar(size: TFSpacing.sm, name: "TFSpacing.sm (8pt)")
                    SpacingBar(size: TFSpacing.md, name: "TFSpacing.md (16pt)")
                    SpacingBar(size: TFSpacing.lg, name: "TFSpacing.lg (24pt)")
                    SpacingBar(size: TFSpacing.xl, name: "TFSpacing.xl (32pt)")
                    SpacingBar(size: TFSpacing.xxl, name: "TFSpacing.xxl (48pt)")
                }
            }
        }
        .padding(TFSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 2: Buttons & Actions

#Preview("Buttons & Actions") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // ActionButton Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("ActionButton")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    // Primary Style
                    SectionLabel("Primary Style")
                    HStack(spacing: TFSpacing.sm) {
                        ActionButton("Large", icon: "star.fill", style: .primary, size: .large) {}
                        ActionButton("Medium", style: .primary, size: .medium) {}
                        ActionButton("Small", style: .primary, size: .small) {}
                    }

                    // Secondary Style
                    SectionLabel("Secondary Style")
                    HStack(spacing: TFSpacing.sm) {
                        ActionButton("Large", icon: "heart.fill", style: .secondary, size: .large) {}
                        ActionButton("Medium", style: .secondary, size: .medium) {}
                        ActionButton("Small", style: .secondary, size: .small) {}
                    }

                    // Text Style
                    SectionLabel("Text Style")
                    HStack(spacing: TFSpacing.sm) {
                        ActionButton("Large", icon: "arrow.right", style: .text, size: .large) {}
                        ActionButton("Medium", style: .text, size: .medium) {}
                        ActionButton("Small", style: .text, size: .small) {}
                    }

                    // Destructive Style
                    SectionLabel("Destructive Style")
                    HStack(spacing: TFSpacing.sm) {
                        ActionButton("Large", icon: "trash", style: .destructive, size: .large) {}
                        ActionButton("Medium", style: .destructive, size: .medium) {}
                        ActionButton("Small", style: .destructive, size: .small) {}
                    }

                    // Loading State
                    SectionLabel("Loading State")
                    ActionButton("Processing", style: .primary, size: .large, isLoading: true) {}
                }
            }

            Divider()

            // PrimaryScanButton Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("PrimaryScanButton")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Ready State")
                    PrimaryScanButton(state: .ready) {}

                    SectionLabel("Scanning State")
                    PrimaryScanButton(state: .scanning) {}

                    SectionLabel("Cooldown State")
                    PrimaryScanButton(state: .cooldown) {}

                    SectionLabel("Disabled State")
                    PrimaryScanButton(state: .disabled) {}
                }
            }

            Divider()

            // FilterChip Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("FilterChip")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                HStack(spacing: TFSpacing.sm) {
                    FilterChip("Selected", isSelected: true) {}
                    FilterChip("Unselected", isSelected: false) {}
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 3: Cards

#Preview("Cards") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // CompCard Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("CompCard")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Sold Listing")
                    CompCard(
                        imageUrl: "https://example.com/shirt.jpg",
                        title: "Vintage Nike Windbreaker",
                        price: "$45",
                        statusText: "Sold 2 days ago",
                        statusColor: TFColor.gainGreen,
                        onTap: {}
                    )

                    SectionLabel("Active Listing")
                    CompCard(
                        imageUrl: "https://example.com/jacket.jpg",
                        title: "Carhartt Work Jacket",
                        price: "$85",
                        statusText: "Active • 3 watchers",
                        statusColor: Color.tfTextSecondary,
                        onTap: {}
                    )

                    SectionLabel("No Image")
                    CompCard(
                        imageUrl: nil,
                        title: "Patagonia Fleece",
                        price: "$60",
                        statusText: "Sold 1 week ago",
                        statusColor: TFColor.gainGreen,
                        onTap: {}
                    )
                }
            }

            Divider()

            // CollectionCard Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("CollectionCard")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: TFSpacing.md) {
                    CollectionCard(
                        gradientColors: (Color.blue, Color.purple),
                        garmentIcon: "tshirt.fill",
                        confidenceLevel: .high,
                        confidenceScore: 94,
                        brand: "Supreme",
                        itemName: "Box Logo Tee",
                        price: "$120",
                        priceRange: "$95-$145",
                        isLowConfidence: false,
                        isCorrected: false,
                        onTap: {}
                    )

                    CollectionCard(
                        gradientColors: (Color.orange, Color.red),
                        garmentIcon: "figure.dress.line.vertical.figure",
                        confidenceLevel: .medium,
                        confidenceScore: 72,
                        brand: "Levi's",
                        itemName: "501 Jeans",
                        price: "$55",
                        priceRange: "$45-$70",
                        isLowConfidence: false,
                        isCorrected: false,
                        onTap: {}
                    )

                    CollectionCard(
                        gradientColors: (Color.green, Color.teal),
                        garmentIcon: "tshirt.fill",
                        confidenceLevel: .low,
                        confidenceScore: 45,
                        brand: "Nike",
                        itemName: "Vintage Windbreaker",
                        price: "est. $38",
                        priceRange: "$25-$50",
                        isLowConfidence: true,
                        isCorrected: false,
                        onTap: {}
                    )

                    CollectionCard(
                        gradientColors: (Color.purple, Color.pink),
                        garmentIcon: "figure.dress.line.vertical.figure",
                        confidenceLevel: .high,
                        confidenceScore: 88,
                        brand: "Patagonia",
                        itemName: "Synchilla Fleece",
                        price: "$75",
                        priceRange: "$65-$90",
                        isLowConfidence: false,
                        isCorrected: true,
                        onTap: {}
                    )
                }
            }

            Divider()

            // StatCard Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("StatCard")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                HStack(spacing: TFSpacing.sm) {
                    StatCard(
                        value: "$1,240",
                        label: "Total Value",
                        trend: .up,
                        trendValue: "+12%"
                    )

                    StatCard(
                        value: "24",
                        label: "Items",
                        trend: .neutral,
                        trendValue: "No change"
                    )

                    StatCard(
                        value: "$52",
                        label: "Avg. Price",
                        trend: .down,
                        trendValue: "-5%"
                    )
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 4: Badges & Indicators

#Preview("Badges & Indicators") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // ConfidenceBadge Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("ConfidenceBadge")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Full Style")
                    HStack(spacing: TFSpacing.sm) {
                        ConfidenceBadge(level: .high, score: 95, style: .full)
                        ConfidenceBadge(level: .medium, score: 72, style: .full)
                        ConfidenceBadge(level: .low, score: 45, style: .full)
                        ConfidenceBadge(level: .insufficient, score: 20, style: .full)
                    }

                    SectionLabel("Compact Style")
                    HStack(spacing: TFSpacing.sm) {
                        ConfidenceBadge(level: .high, score: 95, style: .compact)
                        ConfidenceBadge(level: .medium, score: 72, style: .compact)
                        ConfidenceBadge(level: .low, score: 45, style: .compact)
                        ConfidenceBadge(level: .insufficient, score: 20, style: .compact)
                    }

                    SectionLabel("Dot Only Style")
                    HStack(spacing: TFSpacing.sm) {
                        ConfidenceBadge(level: .high, score: 95, style: .dotOnly)
                        ConfidenceBadge(level: .medium, score: 72, style: .dotOnly)
                        ConfidenceBadge(level: .low, score: 45, style: .dotOnly)
                        ConfidenceBadge(level: .insufficient, score: 20, style: .dotOnly)
                    }
                }
            }

            Divider()

            // PriceRangeView Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("PriceRangeBlock")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.lg) {
                    SectionLabel("Hero Style")
                    PriceRangeBlock(
                        priceRange: PriceRange(low: 45.0, median: 65.0, high: 85.0, currency: "USD"),
                        confidence: .high,
                        style: .hero
                    )

                    SectionLabel("Inline Style")
                    PriceRangeBlock(
                        priceRange: PriceRange(low: 45.0, median: 65.0, high: 85.0, currency: "USD"),
                        confidence: .low,
                        style: .inline
                    )
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 5: States

#Preview("States") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // EmptyStateCard Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("EmptyStateCard")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("With Primary & Secondary Actions")
                    EmptyStateCard(
                        icon: "camera.fill",
                        title: "No Items Yet",
                        message: "Start building your thrift collection by scanning your first item.",
                        actionLabel: "Scan Item",
                        action: {},
                        secondaryActionLabel: "Learn More",
                        secondaryAction: {}
                    )

                    SectionLabel("No Actions")
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "No Results Found",
                        message: "We couldn't find any items matching your search. Try adjusting your filters."
                    )
                }
            }

            Divider()

            // ErrorStateCard Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("ErrorStateCard")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Standard with Retry")
                    ErrorStateCard(
                        title: "Connection Failed",
                        message: "Unable to reach the server. Please check your internet connection and try again.",
                        style: .standard,
                        primaryActionLabel: "Retry",
                        primaryAction: {}
                    )

                    SectionLabel("Standard with Primary & Secondary")
                    ErrorStateCard(
                        icon: "wifi.slash",
                        title: "Offline",
                        message: "You're currently offline. Some features may be unavailable.",
                        style: .standard,
                        primaryActionLabel: "Retry",
                        primaryAction: {},
                        secondaryActionLabel: "Continue Offline",
                        secondaryAction: {}
                    )

                    SectionLabel("Inline Retryable")
                    ErrorStateCard(
                        title: "Failed to Load",
                        message: "Something went wrong.",
                        style: .inline,
                        primaryActionLabel: "Retry",
                        primaryAction: {}
                    )

                    SectionLabel("Inline Dismissible")
                    ErrorStateCard(
                        title: "Update Available",
                        message: "A new version is available.",
                        style: .inline,
                        primaryActionLabel: "Update",
                        primaryAction: {},
                        secondaryActionLabel: "Dismiss",
                        secondaryAction: {}
                    )
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 6: Overlays & Camera

#Preview("Overlays & Camera") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // ScanOverlayFrame Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("ScanOverlayFrame")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.lg) {
                    SectionLabel("Searching State")
                    ZStack {
                        Color.black
                        ScanOverlayFrame(
                            state: .searching,
                            guidanceText: "Position item in frame"
                        )
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    SectionLabel("Locked State")
                    ZStack {
                        Color.black
                        ScanOverlayFrame(
                            state: .locked,
                            guidanceText: "Item detected • Hold steady"
                        )
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    SectionLabel("Failed State")
                    ZStack {
                        Color.black
                        ScanOverlayFrame(
                            state: .failed,
                            guidanceText: "Unable to detect item"
                        )
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Divider()

            // AppHeader Section
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("AppHeader")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Opaque with Subtitle & Icon")
                    AppHeader(
                        title: "My Collection",
                        subtitle: "24 items • $1,240 total",
                        trailingIcon: "plus.circle.fill",
                        trailingAction: {},
                        style: .opaque
                    )

                    SectionLabel("Transparent")
                    ZStack {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        AppHeader(
                            title: "Scan",
                            style: .transparent
                        )
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 7: Loading Skeletons

#Preview("Loading Skeletons") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("Loading Skeletons")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.xl) {
                    SectionLabel("ResultSheetSkeleton")
                    ResultSheetSkeleton()

                    Divider()

                    SectionLabel("CollectionGridSkeleton")
                    CollectionGridSkeleton()

                    Divider()

                    SectionLabel("StatsHeaderSkeleton")
                    StatsHeaderSkeleton()
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 8: Glass & Modifiers

#Preview("Glass & Modifiers") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            // Glass Card Modifier
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("TFGlassCard Modifier")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                ZStack {
                    // Colorful background to show glass effect
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: TFSpacing.lg) {
                        VStack(spacing: TFSpacing.sm) {
                            SectionLabel("Without Glass Modifier")
                            VStack(alignment: .leading, spacing: TFSpacing.sm) {
                                Text("Standard Card")
                                    .font(TFFont.headline)
                                    .foregroundStyle(Color.tfTextPrimary)
                                Text("This card has no glass effect applied.")
                                    .font(TFFont.caption)
                                    .foregroundStyle(Color.tfTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(TFSpacing.md)
                            .background(Color.tfCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(spacing: TFSpacing.sm) {
                            SectionLabel("With Glass Modifier")
                            VStack(alignment: .leading, spacing: TFSpacing.sm) {
                                Text("Glass Card")
                                    .font(TFFont.headline)
                                    .foregroundStyle(Color.tfTextPrimary)
                                Text("This card uses the .tfGlassCard() modifier for a frosted glass effect.")
                                    .font(TFFont.caption)
                                    .foregroundStyle(Color.tfTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(TFSpacing.md)
                            .tfGlassCard()
                        }
                    }
                    .padding(TFSpacing.lg)
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider()

            // Shimmer Modifier
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                Text("Shimmer Modifier & SkeletonBlock")
                    .font(TFFont.title2)
                    .foregroundStyle(Color.tfTextPrimary)

                VStack(spacing: TFSpacing.md) {
                    SectionLabel("Skeleton Blocks with Shimmer")

                    VStack(alignment: .leading, spacing: TFSpacing.sm) {
                        SkeletonBlock(width: 200, height: 24, cornerRadius: 8)
                        SkeletonBlock(width: nil, height: 16, cornerRadius: 6)
                        SkeletonBlock(width: 150, height: 16, cornerRadius: 6)

                        HStack(spacing: TFSpacing.sm) {
                            SkeletonBlock(width: 80, height: 80, cornerRadius: 12)
                            SkeletonBlock(width: 80, height: 80, cornerRadius: 12)
                            SkeletonBlock(width: 80, height: 80, cornerRadius: 12)
                        }
                    }
                    .padding(TFSpacing.md)
                    .background(Color.tfCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

// MARK: - Preview 9: Light Mode Highlights

#Preview("Light Mode Highlights") {
    ScrollView {
        VStack(alignment: .leading, spacing: TFSpacing.xl) {
            Text("Light Mode Preview")
                .font(TFFont.title1)
                .foregroundStyle(Color.tfTextPrimary)

            Text("Selected components showcased in light mode")
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextSecondary)

            Divider()

            // Buttons
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                SectionLabel("Buttons")
                HStack(spacing: TFSpacing.sm) {
                    ActionButton("Primary", icon: "star.fill", style: .primary, size: .medium) {}
                    ActionButton("Secondary", style: .secondary, size: .medium) {}
                    ActionButton("Text", style: .text, size: .medium) {}
                }
            }

            // Cards
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                SectionLabel("Collection Cards")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: TFSpacing.md) {
                    CollectionCard(
                        gradientColors: (Color.blue, Color.purple),
                        garmentIcon: "tshirt.fill",
                        confidenceLevel: .high,
                        confidenceScore: 94,
                        brand: "Supreme",
                        itemName: "Box Logo Tee",
                        price: "$120",
                        priceRange: "$95-$145",
                        isLowConfidence: false,
                        isCorrected: false,
                        onTap: {}
                    )

                    CollectionCard(
                        gradientColors: (Color.orange, Color.red),
                        garmentIcon: "figure.dress.line.vertical.figure",
                        confidenceLevel: .medium,
                        confidenceScore: 72,
                        brand: "Levi's",
                        itemName: "501 Jeans",
                        price: "$55",
                        priceRange: "$45-$70",
                        isLowConfidence: false,
                        isCorrected: true,
                        onTap: {}
                    )
                }
            }

            // Badges
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                SectionLabel("Confidence Badges")
                HStack(spacing: TFSpacing.sm) {
                    ConfidenceBadge(level: .high, score: 95, style: .full)
                    ConfidenceBadge(level: .medium, score: 72, style: .full)
                    ConfidenceBadge(level: .low, score: 45, style: .full)
                }
            }

            // Stats
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                SectionLabel("Stat Cards")
                HStack(spacing: TFSpacing.sm) {
                    StatCard(
                        value: "$1,240",
                        label: "Total Value",
                        trend: .up,
                        trendValue: "+12%"
                    )

                    StatCard(
                        value: "24",
                        label: "Items"
                    )
                }
            }

            // Empty State
            VStack(alignment: .leading, spacing: TFSpacing.md) {
                SectionLabel("Empty State")
                EmptyStateCard(
                    icon: "camera.fill",
                    title: "No Items Yet",
                    message: "Start building your collection.",
                    actionLabel: "Scan Item",
                    action: {}
                )
            }
        }
        .padding(TFSpacing.lg)
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.light)
}

// MARK: - Helper Views

private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        HStack(spacing: TFSpacing.sm) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )

            Text(name)
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextSecondary)
        }
    }
}

private struct SpacingBar: View {
    let size: CGFloat
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: TFSpacing.xs) {
            Text(name)
                .font(TFFont.caption)
                .foregroundStyle(Color.tfTextSecondary)

            RoundedRectangle(cornerRadius: 4)
                .fill(TFColor.gainGreen)
                .frame(width: size, height: 8)
        }
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(TFFont.caption)
            .foregroundStyle(Color.tfTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, TFSpacing.xs)
    }
}
