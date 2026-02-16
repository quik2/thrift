import SwiftUI
import UIKit

/// Primary camera capture button with multiple states for barcode scanning.
/// Features a circular design with outer ring, state-based colors, and smooth animations.
struct PrimaryScanButton: View {
    // MARK: - Properties

    let state: ScanButtonState
    let action: () -> Void

    // MARK: - Animation State

    @State private var isPressed: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var isCooldownActive: Bool = false

    // MARK: - Constants

    private let outerDiameter: CGFloat = 72
    private let innerIconSize: CGFloat = 28
    private let ringStrokeWidth: CGFloat = 4
    private let ringGap: CGFloat = 2
    private let shadowRadius: CGFloat = 8
    private let shadowYOffset: CGFloat = 4

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: ringStrokeWidth)
                    .frame(width: outerDiameter, height: outerDiameter)

                // Main button fill
                Circle()
                    .fill(fillColor)
                    .frame(
                        width: outerDiameter - (ringStrokeWidth * 2) - (ringGap * 2),
                        height: outerDiameter - (ringStrokeWidth * 2) - (ringGap * 2)
                    )

                // Icon or spinner
                buttonContent
                    .frame(width: innerIconSize, height: innerIconSize)
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: shadowRadius, y: shadowYOffset)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .brightness(isPressed ? -0.1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: outerDiameter, height: outerDiameter)
        .buttonStyle(PlainButtonStyle())
        .disabled(isButtonDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isButtonDisabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    // MARK: - Subviews

    /// Button content that switches between icon and spinner based on state
    @ViewBuilder
    private var buttonContent: some View {
        switch state {
        case .ready, .cooldown, .disabled:
            Image(systemName: "camera.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .scanning:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
        }
    }

    // MARK: - Computed Properties

    /// Fill color based on current state
    private var fillColor: Color {
        switch state {
        case .ready:
            return TFColor.gainGreen
        case .scanning:
            return TFColor.gainGreen
        case .cooldown:
            return TFColor.gainGreen.opacity(0.4)
        case .disabled:
            return TFColor.textTertiary.opacity(0.3)
        }
    }

    /// Whether the button should be disabled for interaction
    private var isButtonDisabled: Bool {
        switch state {
        case .ready:
            return false
        case .scanning, .cooldown, .disabled:
            return true
        }
    }

    /// Accessibility label based on state
    private var accessibilityLabel: String {
        switch state {
        case .ready:
            return "Scan item"
        case .scanning:
            return "Scanning in progress"
        case .cooldown:
            return "Please wait"
        case .disabled:
            return "Camera unavailable"
        }
    }

    /// Accessibility hint based on state
    private var accessibilityHint: String {
        switch state {
        case .ready:
            return "Takes a photo of the tag and item"
        case .scanning:
            return "Processing scan"
        case .cooldown:
            return "Button temporarily unavailable"
        case .disabled:
            return "Camera access required"
        }
    }

    // MARK: - Actions

    /// Handle button tap with haptic feedback
    private func handleTap() {
        guard !isButtonDisabled else { return }

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        action()
    }

    /// Handle state transitions with appropriate effects
    private func handleStateChange(_ newState: ScanButtonState) {
        switch newState {
        case .ready:
            isCooldownActive = false

        case .scanning:
            isCooldownActive = false

        case .cooldown:
            startCooldownTimer()

        case .disabled:
            isCooldownActive = false
        }
    }

    /// Auto-reset from cooldown to ready after 1 second
    private func startCooldownTimer() {
        guard !isCooldownActive else { return }
        isCooldownActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCooldownActive = false
            // Note: Actual state change to .ready would be handled by parent view
            // This is just for internal tracking
        }
    }
}

// MARK: - Previews

#Preview("Ready State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            PrimaryScanButton(state: .ready) {
                print("Scan button tapped")
            }

            Text("Ready")
                .foregroundColor(.white)
                .font(TFFont.caption)
        }
    }
}

#Preview("Scanning State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            PrimaryScanButton(state: .scanning) {
                print("Scan button tapped")
            }

            Text("Scanning")
                .foregroundColor(.white)
                .font(TFFont.caption)
        }
    }
}

#Preview("Cooldown State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            PrimaryScanButton(state: .cooldown) {
                print("Scan button tapped")
            }

            Text("Cooldown")
                .foregroundColor(.white)
                .font(TFFont.caption)
        }
    }
}

#Preview("Disabled State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            PrimaryScanButton(state: .disabled) {
                print("Scan button tapped")
            }

            Text("Disabled")
                .foregroundColor(.white)
                .font(TFFont.caption)
        }
    }
}

#Preview("All States") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            VStack(spacing: 12) {
                PrimaryScanButton(state: .ready) {}
                Text("Ready").foregroundColor(.white).font(TFFont.caption)
            }

            VStack(spacing: 12) {
                PrimaryScanButton(state: .scanning) {}
                Text("Scanning").foregroundColor(.white).font(TFFont.caption)
            }

            VStack(spacing: 12) {
                PrimaryScanButton(state: .cooldown) {}
                Text("Cooldown").foregroundColor(.white).font(TFFont.caption)
            }

            VStack(spacing: 12) {
                PrimaryScanButton(state: .disabled) {}
                Text("Disabled").foregroundColor(.white).font(TFFont.caption)
            }
        }
        .padding()
    }
}
