import SwiftUI
import UIKit

/// Style variants for error card presentation
enum ErrorCardStyle {
    case standard  // Full height with icon, title, message, and buttons
    case inline    // Compact single-line variant
}

/// Generic error display card with configurable visual style and actions.
/// Completely decoupled from domain logic — takes plain strings and callbacks.
struct ErrorStateCard: View {
    let icon: String
    let title: String
    let message: String
    let style: ErrorCardStyle
    let primaryActionLabel: String?
    let primaryAction: (() -> Void)?
    let secondaryActionLabel: String?
    let secondaryAction: (() -> Void)?

    @AccessibilityFocusState private var isAccessibilityFocused: Bool

    // MARK: - Initializers

    /// Full initializer with all options
    init(
        icon: String = TFIcon.errorGeneric,
        title: String,
        message: String,
        style: ErrorCardStyle = .standard,
        primaryActionLabel: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryActionLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.style = style
        self.primaryActionLabel = primaryActionLabel
        self.primaryAction = primaryAction
        self.secondaryActionLabel = secondaryActionLabel
        self.secondaryAction = secondaryAction
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardErrorView
            case .inline:
                inlineErrorView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityFocused($isAccessibilityFocused)
        .onAppear {
            // Post announcement for screen readers with slight delay to ensure rendering
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let announcement = "\(title). \(message)"
                UIAccessibility.post(notification: .announcement, argument: announcement)
                isAccessibilityFocused = true
            }
        }
    }

    // MARK: - Standard Error View

    private var standardErrorView: some View {
        VStack(alignment: .leading, spacing: TFSpacing.md) {
            HStack(alignment: .top, spacing: TFSpacing.md) {
                // Error icon (36pt for standard style)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(TFColor.warning)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: TFSpacing.xs) {
                    // Title
                    Text(title)
                        .font(TFFont.headline)
                        .foregroundStyle(TFColor.textPrimary)

                    // Message
                    Text(message)
                        .font(TFFont.body)
                        .foregroundStyle(TFColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action buttons (if provided)
            if primaryActionLabel != nil || secondaryActionLabel != nil {
                HStack(spacing: TFSpacing.sm) {
                    if let primaryActionLabel, let primaryAction {
                        ActionButton(
                            primaryActionLabel,
                            icon: TFIcon.refresh,
                            style: .secondary,
                            size: .medium,
                            action: primaryAction
                        )
                    }

                    if let secondaryActionLabel, let secondaryAction {
                        ActionButton(
                            secondaryActionLabel,
                            style: .text,
                            size: .medium,
                            action: secondaryAction
                        )
                    }
                }
            }
        }
        .padding(TFSpacing.md)
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TFColor.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: TFRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: TFRadius.medium)
                .stroke(TFColor.warning.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Inline Error View

    private var inlineErrorView: some View {
        HStack(spacing: TFSpacing.sm) {
            // Compact icon (20pt for inline style)
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(TFColor.warning)
                .accessibilityHidden(true)

            // Combined title and message (stacked, caption size)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TFFont.caption)
                    .foregroundStyle(TFColor.textPrimary)

                Text(message)
                    .font(TFFont.caption)
                    .foregroundStyle(TFColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Compact circular action button (only shows primary action in inline style)
            if let primaryActionLabel, let primaryAction {
                Button(action: primaryAction) {
                    Image(systemName: TFIcon.refresh)
                        .font(.system(size: 16))
                        .foregroundStyle(TFColor.warning)
                        .frame(width: 32, height: 32)
                        .background(TFColor.warning.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel(primaryActionLabel)
            } else if let secondaryActionLabel, let secondaryAction {
                // Fallback to secondary action if no primary action provided
                Button(action: secondaryAction) {
                    Image(systemName: TFIcon.dismiss)
                        .font(.system(size: 14))
                        .foregroundStyle(TFColor.textTertiary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(secondaryActionLabel)
            }
        }
        .padding(.horizontal, TFSpacing.md)
        .padding(.vertical, TFSpacing.sm)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TFColor.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: TFRadius.small))
        .overlay {
            RoundedRectangle(cornerRadius: TFRadius.small)
                .stroke(TFColor.warning.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Previews

#Preview("Standard - Retryable") {
    VStack(spacing: TFSpacing.md) {
        ErrorStateCard(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Unable to reach the server. Check your internet connection and try again.",
            style: .standard,
            primaryActionLabel: "Try Again",
            primaryAction: { print("Retry tapped") }
        )

        ErrorStateCard(
            icon: "exclamationmark.triangle.fill",
            title: "Processing Failed",
            message: "We couldn't process your request. This is usually temporary.",
            style: .standard,
            primaryActionLabel: "Retry",
            primaryAction: { print("Retry tapped") }
        )

        ErrorStateCard(
            icon: "clock.badge.exclamationmark",
            title: "Request Timed Out",
            message: "The server took too long to respond. Please try again.",
            style: .standard,
            primaryActionLabel: "Try Again",
            primaryAction: { print("Retry tapped") }
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Standard - Primary + Secondary Actions") {
    VStack(spacing: TFSpacing.md) {
        ErrorStateCard(
            icon: "externaldrive.fill.badge.exclamationmark",
            title: "Storage Full",
            message: "Your device storage is full. Free up space to continue.",
            style: .standard,
            primaryActionLabel: "Manage Storage",
            primaryAction: { print("Manage storage tapped") },
            secondaryActionLabel: "Dismiss",
            secondaryAction: { print("Dismiss tapped") }
        )

        ErrorStateCard(
            icon: "crown.fill",
            title: "Daily Limit Reached",
            message: "You've used all 5 scans today. Upgrade to unlock unlimited scans.",
            style: .standard,
            primaryActionLabel: "Upgrade",
            primaryAction: { print("Upgrade tapped") },
            secondaryActionLabel: "Cancel",
            secondaryAction: { print("Cancel tapped") }
        )

        ErrorStateCard(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "We couldn't find any matches. Try adjusting your search or scan again.",
            style: .standard,
            primaryActionLabel: "Scan Again",
            primaryAction: { print("Scan again tapped") },
            secondaryActionLabel: "Manual Entry",
            secondaryAction: { print("Manual entry tapped") }
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Inline - Retryable") {
    VStack(spacing: TFSpacing.md) {
        ErrorStateCard(
            icon: "wifi.slash",
            title: "No connection",
            message: "Check your internet and try again.",
            style: .inline,
            primaryActionLabel: "Retry",
            primaryAction: { print("Retry tapped") }
        )

        ErrorStateCard(
            icon: "exclamationmark.triangle.fill",
            title: "Processing failed",
            message: "Unable to complete request.",
            style: .inline,
            primaryActionLabel: "Retry",
            primaryAction: { print("Retry tapped") }
        )

        ErrorStateCard(
            icon: "photo.badge.exclamationmark",
            title: "Image upload failed",
            message: "Could not upload photo.",
            style: .inline,
            primaryActionLabel: "Retry",
            primaryAction: { print("Retry tapped") }
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Inline - Dismissible") {
    VStack(spacing: TFSpacing.md) {
        ErrorStateCard(
            icon: "magnifyingglass",
            title: "No results",
            message: "We couldn't find any matches for this item.",
            style: .inline,
            secondaryActionLabel: "Dismiss",
            secondaryAction: { print("Dismiss tapped") }
        )

        ErrorStateCard(
            icon: "crown.fill",
            title: "Limit reached",
            message: "Upgrade to continue scanning.",
            style: .inline,
            secondaryActionLabel: "Dismiss",
            secondaryAction: { print("Dismiss tapped") }
        )

        ErrorStateCard(
            icon: "exclamationmark.circle.fill",
            title: "Feature unavailable",
            message: "This feature is temporarily disabled.",
            style: .inline,
            secondaryActionLabel: "Dismiss",
            secondaryAction: { print("Dismiss tapped") }
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.dark)
}

#Preview("Light Mode Comparison") {
    VStack(spacing: TFSpacing.lg) {
        Text("Standard Style")
            .font(TFFont.title2)
            .foregroundStyle(TFColor.textPrimary)

        ErrorStateCard(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Unable to reach the server. Check your internet connection and try again.",
            style: .standard,
            primaryActionLabel: "Try Again",
            primaryAction: { print("Retry tapped") }
        )

        Text("Inline Style - Retryable")
            .font(TFFont.title2)
            .foregroundStyle(TFColor.textPrimary)
            .padding(.top, TFSpacing.md)

        ErrorStateCard(
            icon: "wifi.slash",
            title: "No connection",
            message: "Check your internet and try again.",
            style: .inline,
            primaryActionLabel: "Retry",
            primaryAction: { print("Retry tapped") }
        )

        Text("Inline Style - Dismissible")
            .font(TFFont.title2)
            .foregroundStyle(TFColor.textPrimary)
            .padding(.top, TFSpacing.md)

        ErrorStateCard(
            icon: "crown.fill",
            title: "Limit reached",
            message: "Upgrade to continue scanning.",
            style: .inline,
            secondaryActionLabel: "Dismiss",
            secondaryAction: { print("Dismiss tapped") }
        )
    }
    .padding()
    .background(Color.tfBackground)
    .preferredColorScheme(.light)
}
