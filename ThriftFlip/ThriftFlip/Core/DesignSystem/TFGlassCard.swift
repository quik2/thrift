import SwiftUI

struct TFGlassCard: ViewModifier {
    var cornerRadius: CGFloat = TFRadius.large
    @Environment(\.colorScheme) private var colorScheme

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.06)
    }

    private var innerHighlight: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.7)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.08)
    }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.tfCardSurface.opacity(colorScheme == .dark ? 0.45 : 0.85))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        UnevenRoundedRectangle(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: cornerRadius
                        )
                        .stroke(innerHighlight, lineWidth: 1.0)
                        .frame(height: cornerRadius * 2)
                        .clipped()
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: colorScheme == .dark ? 12 : 8, y: colorScheme == .dark ? 4 : 2)
    }
}

extension View {
    func tfGlassCard(cornerRadius: CGFloat = TFRadius.large) -> some View {
        modifier(TFGlassCard(cornerRadius: cornerRadius))
    }
}
