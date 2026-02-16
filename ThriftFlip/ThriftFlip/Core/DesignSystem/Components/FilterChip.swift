import SwiftUI

struct FilterChip: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ label: String,
        icon: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: TFSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .white : Color.tfTextSecondary)
                }
                Text(label)
                    .font(TFFont.caption)
                    .foregroundStyle(isSelected ? .white : Color.tfTextSecondary)
            }
            .padding(.horizontal, TFSpacing.md)
            .padding(.vertical, TFSpacing.sm)
            .background(isSelected ? TFColor.gainGreen : Color.tfCardSurface)
            .clipShape(Capsule())
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    HStack(spacing: 8) {
        FilterChip("All", isSelected: true, action: {})
        FilterChip("High Confidence", action: {})
        FilterChip("Needs Review", icon: "exclamationmark.triangle", action: {})
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
