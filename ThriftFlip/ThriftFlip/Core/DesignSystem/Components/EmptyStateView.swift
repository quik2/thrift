import SwiftUI

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.tfTextTertiary)

            Spacer().frame(height: TFSpacing.md)

            Text(title)
                .font(TFFont.headline)
                .foregroundStyle(Color.tfTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer().frame(height: TFSpacing.sm)

            Text(message)
                .font(TFFont.body)
                .foregroundStyle(Color.tfTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if let actionLabel, let action {
                Spacer().frame(height: TFSpacing.lg)

                ActionButton(
                    actionLabel,
                    style: .primary,
                    size: .medium,
                    action: action
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateCard(
        icon: "camera.viewfinder",
        title: "No scans yet",
        message: "Scan a tag and item to see what it's worth.",
        actionLabel: "Start Scanning",
        action: {}
    )
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
