import SwiftUI

enum ActionButtonStyle {
    case primary
    case secondary
    case text
    case destructive
}

enum ActionButtonSize {
    case large
    case medium
    case small
}

struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ActionButtonStyle
    let size: ActionButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        size: ActionButtonSize = .large,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    private var height: CGFloat {
        switch size {
        case .large: return 52
        case .medium: return 44
        case .small: return 36
        }
    }

    private var cornerRadius: CGFloat {
        size == .large ? TFRadius.medium : TFRadius.small
    }

    private var titleFont: Font {
        switch size {
        case .large: return TFFont.headline
        case .medium: return TFFont.body
        case .small: return TFFont.caption
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .large: return 20
        case .medium: return 18
        case .small: return 16
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .large: return TFSpacing.lg
        case .medium: return TFSpacing.md
        case .small: return TFSpacing.sm
        }
    }

    private var backgroundColor: Color {
        if isDisabled { return Color.tfTextTertiary.opacity(0.2) }
        switch style {
        case .primary: return TFColor.gainGreen
        case .secondary, .text: return .clear
        case .destructive: return TFColor.warning
        }
    }

    private var textColor: Color {
        if isDisabled { return Color.tfTextTertiary }
        switch style {
        case .primary, .destructive: return .white
        case .secondary, .text: return TFColor.gainGreen
        }
    }

    private var borderColor: Color? {
        if style == .secondary {
            return isDisabled ? Color.tfTextTertiary.opacity(0.3) : TFColor.gainGreen
        }
        return nil
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: TFSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                        .frame(width: iconSize, height: iconSize)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: iconSize))
                            .foregroundStyle(textColor)
                    }
                    Text(title)
                        .font(titleFont)
                        .foregroundStyle(textColor)
                }
            }
            .frame(height: height)
            .frame(maxWidth: size == .large ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(ActionButtonPressStyle())
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
    }
}

private struct ActionButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionButton("Save to Collection", icon: "bookmark.fill", action: {})
        ActionButton("Rescan", style: .secondary, action: {})
        ActionButton("Mark Incorrect", style: .text, size: .medium, action: {})
        ActionButton("Loading...", isLoading: true, action: {})
        ActionButton("Disabled", isDisabled: true, action: {})
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
