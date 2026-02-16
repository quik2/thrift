import SwiftUI

/// A 160×180pt comparable listing card for horizontal carousels.
/// Generic visual component that displays thumbnail, title, price, and status badge.
/// Does not depend on any domain models — caller provides pre-formatted display strings.
struct CompCard: View {
    let imageUrl: String?
    let title: String
    let price: String              // Pre-formatted price like "$65"
    let statusText: String         // e.g. "SOLD" or "ACTIVE"
    let statusColor: Color         // e.g. TFColor.gainGreen or TFColor.textSecondary
    let onTap: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: TFSpacing.sm) {
                // Thumbnail with status badge overlay
                ZStack(alignment: .topTrailing) {
                    thumbnailView
                        .frame(width: 160, height: 100)
                        .clipped()

                    // Status badge
                    statusBadge
                        .padding([.top, .trailing], TFSpacing.sm)
                }

                // Title
                Text(title)
                    .font(TFFont.caption)
                    .foregroundStyle(TFColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Price
                Text(price)
                    .font(TFFont.headline.monospacedDigit())
                    .foregroundStyle(TFColor.textPrimary)
            }
            .frame(width: 160, height: 180, alignment: .topLeading)
            .background(TFColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: TFRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: TFRadius.medium)
                    .stroke(TFColor.borderSubtle, lineWidth: 1)
            }
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(CompCardButtonStyle(isPressed: $isPressed))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(price), \(statusText)")
        .accessibilityHint("Opens listing details")
        .accessibilityAddTraits([.isButton, .isLink])
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.tfTextTertiary.opacity(0.1)
            Image(systemName: TFIcon.photo)
                .font(.system(size: 24))
                .foregroundStyle(Color.tfTextTertiary)
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(TFFont.micro)
            .foregroundStyle(statusColor)
            .textCase(.uppercase)
            .padding(.horizontal, TFSpacing.sm)
            .padding(.vertical, TFSpacing.xs)
            .background(statusColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: TFRadius.small))
    }
}

// MARK: - Button Style

/// Custom button style to track press state without default button animations
private struct CompCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Previews

#Preview("Comp Cards - Dark Mode") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: TFSpacing.md) {
            // Sold listing
            CompCard(
                imageUrl: "https://picsum.photos/160/100",
                title: "Patagonia Better Sweater Fleece Jacket",
                price: "$65",
                statusText: "SOLD",
                statusColor: TFColor.gainGreen,
                onTap: { print("Tapped sold listing") }
            )

            // Active listing
            CompCard(
                imageUrl: "https://picsum.photos/160/100",
                title: "Patagonia Men's Better Sweater",
                price: "$90",
                statusText: "ACTIVE",
                statusColor: TFColor.textSecondary,
                onTap: { print("Tapped active listing") }
            )

            // No image variant
            CompCard(
                imageUrl: nil,
                title: "Patagonia Better Sweater Size M",
                price: "$73",
                statusText: "SOLD",
                statusColor: TFColor.gainGreen,
                onTap: nil
            )
        }
        .padding()
    }
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    HStack(spacing: TFSpacing.md) {
        CompCard(
            imageUrl: "https://picsum.photos/160/100",
            title: "Nike Vintage Windbreaker",
            price: "$45",
            statusText: "SOLD",
            statusColor: TFColor.gainGreen,
            onTap: {}
        )

        CompCard(
            imageUrl: "https://picsum.photos/160/100",
            title: "Adidas Track Jacket XL",
            price: "$38",
            statusText: "ACTIVE",
            statusColor: TFColor.textSecondary,
            onTap: {}
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.light)
}

#Preview("Failed Image State") {
    HStack(spacing: TFSpacing.md) {
        CompCard(
            imageUrl: "invalid-url",
            title: "The North Face Puffer Jacket",
            price: "$120",
            statusText: "SOLD",
            statusColor: TFColor.gainGreen,
            onTap: {}
        )

        CompCard(
            imageUrl: nil,
            title: "Carhartt Work Jacket Brown",
            price: "$55",
            statusText: "ACTIVE",
            statusColor: TFColor.textSecondary,
            onTap: {}
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
