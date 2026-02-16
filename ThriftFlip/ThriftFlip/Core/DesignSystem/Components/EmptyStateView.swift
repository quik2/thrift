import SwiftUI

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    let secondaryActionLabel: String?
    let secondaryAction: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
        self.secondaryActionLabel = secondaryActionLabel
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Color.tfTextTertiary)
                .frame(width: 64, height: 64)
                .background(Color.tfTextTertiary.opacity(0.08))
                .clipShape(Circle())
                .accessibilityHidden(true)

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

            if let secondaryActionLabel, let secondaryAction {
                Spacer().frame(height: TFSpacing.sm)

                ActionButton(
                    secondaryActionLabel,
                    style: .text,
                    size: .medium,
                    action: secondaryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

}

#Preview("With Actions") {
    EmptyStateCard(
        icon: "camera.viewfinder",
        title: "Nothing here yet",
        message: "Get started by taking your first action.",
        actionLabel: "Get Started",
        action: {},
        secondaryActionLabel: "Learn More",
        secondaryAction: {}
    )
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("No Actions") {
    EmptyStateCard(
        icon: "magnifyingglass",
        title: "No results",
        message: "Try adjusting your search or filters."
    )
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}
