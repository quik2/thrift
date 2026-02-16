import SwiftUI

struct TFGlassCard: ViewModifier {
    var cornerRadius: CGFloat = TFRadius.large

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.tfCardSurface.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        UnevenRoundedRectangle(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: cornerRadius
                        )
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        .frame(height: cornerRadius * 2)
                        .clipped()
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }
}

extension View {
    func tfGlassCard(cornerRadius: CGFloat = TFRadius.large) -> some View {
        modifier(TFGlassCard(cornerRadius: cornerRadius))
    }
}
