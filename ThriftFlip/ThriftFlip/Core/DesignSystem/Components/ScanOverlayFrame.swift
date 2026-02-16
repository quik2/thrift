import SwiftUI
import UIKit

/// Camera alignment guide overlay that provides visual feedback during barcode scanning.
/// Displays a frame with corner brackets that pulse, lock, or shake based on scan state.
struct ScanOverlayFrame: View {
    // MARK: - Properties

    let state: ScanOverlayState
    let guidanceText: String

    // MARK: - Animation State

    @State private var pulseOpacity: Double = 0.6
    @State private var shakeOffset: CGFloat = 0
    @State private var isResettingFromFailed: Bool = false

    // MARK: - Constants

    private let frameWidth: CGFloat = 280
    private let frameHeight: CGFloat = 180
    private let bracketLength: CGFloat = 32
    private let bracketThickness: CGFloat = 3
    private let verticalOffset: CGFloat = -40
    private let guidanceSpacing: CGFloat = 16

    // MARK: - Body

    var body: some View {
        ZStack {
            // Vignette effect - radial gradient from clear to black 30%
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.3),
                    .init(color: .black.opacity(0.3), location: 1.0)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: guidanceSpacing) {
                // Corner bracket frame
                bracketFrame
                    .frame(width: frameWidth, height: frameHeight)
                    .offset(x: shakeOffset)
                    .accessibilityHidden(true)

                // Guidance text
                Text(guidanceText)
                    .font(TFFont.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(guidanceText)
                    .accessibilityAddTraits(.isStaticText)
            }
            .offset(y: verticalOffset)
        }
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
        .onAppear {
            if state == .searching {
                startPulseAnimation()
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Subviews

    /// The corner bracket frame that adapts color and animation based on state
    private var bracketFrame: some View {
        ZStack {
            // Top-left bracket
            cornerBracket
                .position(x: bracketLength / 2, y: bracketLength / 2)

            // Top-right bracket
            cornerBracket
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .position(x: frameWidth - bracketLength / 2, y: bracketLength / 2)

            // Bottom-left bracket
            cornerBracket
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .position(x: bracketLength / 2, y: frameHeight - bracketLength / 2)

            // Bottom-right bracket
            cornerBracket
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
                .position(x: frameWidth - bracketLength / 2, y: frameHeight - bracketLength / 2)
        }
        .frame(width: frameWidth, height: frameHeight)
    }

    /// Individual corner bracket shape
    private var cornerBracket: some View {
        CornerBracketShape(length: bracketLength, thickness: bracketThickness)
            .stroke(bracketColor, style: StrokeStyle(lineWidth: bracketThickness, lineCap: .round))
            .opacity(bracketOpacity)
    }

    // MARK: - Computed Properties

    /// Bracket color based on current state
    private var bracketColor: Color {
        switch state {
        case .searching:
            return .white
        case .locked:
            return TFColor.gainGreen
        case .failed:
            return TFColor.warning
        }
    }

    /// Bracket opacity based on current state and animation
    private var bracketOpacity: Double {
        switch state {
        case .searching:
            return pulseOpacity
        case .locked, .failed:
            return 1.0
        }
    }

    // MARK: - State Handling

    /// Handle state transitions with appropriate animations and accessibility announcements
    private func handleStateChange(_ newState: ScanOverlayState) {
        switch newState {
        case .searching:
            startPulseAnimation()
            shakeOffset = 0
            announceState("Searching for tag")

        case .locked:
            stopPulseAnimation()
            shakeOffset = 0
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                // Spring animation to locked state handled by color change
            }
            announceState("Tag detected")

        case .failed:
            stopPulseAnimation()
            performShakeAnimation()
            announceState("Could not read tag, please try again")
            scheduleResetToSearching()
        }
    }

    /// Start the pulsing animation for searching state
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.8
        }
    }

    /// Stop the pulsing animation
    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseOpacity = 1.0
        }
    }

    /// Perform shake animation for failed state
    private func performShakeAnimation() {
        let shakeSequence: [CGFloat] = [0, -8, 8, -8, 8, -4, 4, 0]

        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }

    /// Auto-reset from failed to searching after 2 seconds
    private func scheduleResetToSearching() {
        guard !isResettingFromFailed else { return }
        isResettingFromFailed = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isResettingFromFailed = false
            // Note: Actual state change would be handled by parent view
            // This is just for internal animation cleanup
        }
    }

    /// Post accessibility announcement for state changes
    private func announceState(_ message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

// MARK: - Corner Bracket Shape

/// Custom shape for drawing L-shaped corner brackets
private struct CornerBracketShape: Shape {
    let length: CGFloat
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Horizontal line (top of L)
        path.move(to: CGPoint(x: 0, y: thickness / 2))
        path.addLine(to: CGPoint(x: length, y: thickness / 2))

        // Vertical line (side of L)
        path.move(to: CGPoint(x: thickness / 2, y: 0))
        path.addLine(to: CGPoint(x: thickness / 2, y: length))

        return path
    }
}

// MARK: - Previews

#Preview("Searching State") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScanOverlayFrame(
            state: .searching,
            guidanceText: "Position barcode within frame"
        )
    }
}

#Preview("Locked State") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScanOverlayFrame(
            state: .locked,
            guidanceText: "Scanning barcode..."
        )
    }
}

#Preview("Failed State") {
    ZStack {
        Color.black.ignoresSafeArea()

        ScanOverlayFrame(
            state: .failed,
            guidanceText: "Unable to read barcode"
        )
    }
}

#Preview("All States") {
    VStack(spacing: 40) {
        ZStack {
            Color.black
            ScanOverlayFrame(
                state: .searching,
                guidanceText: "Searching"
            )
        }
        .frame(height: 250)

        ZStack {
            Color.black
            ScanOverlayFrame(
                state: .locked,
                guidanceText: "Locked"
            )
        }
        .frame(height: 250)

        ZStack {
            Color.black
            ScanOverlayFrame(
                state: .failed,
                guidanceText: "Failed"
            )
        }
        .frame(height: 250)
    }
}
