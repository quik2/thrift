import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    @Environment(\.colorScheme) private var colorScheme

    private var shimmerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
    }

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: shimmerColor, location: 0.5),
                        .init(color: .clear, location: 0.65),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase * 400)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Placeholder Shape

struct SkeletonBlock: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(
        width: CGFloat? = nil,
        height: CGFloat = 16,
        cornerRadius: CGFloat = TFRadius.small
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.tfTextTertiary.opacity(0.1))
            .frame(width: width, height: height)
    }
}
