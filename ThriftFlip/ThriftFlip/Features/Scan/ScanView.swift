import SwiftUI

struct ScanView: View {
    var body: some View {
        ZStack {
            // Camera placeholder
            Color.black.ignoresSafeArea()

            VStack(spacing: TFSpacing.lg) {
                Spacer()

                // Scan overlay frame
                ZStack {
                    // Corner brackets
                    ScanFrameCorners()
                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 280, height: 180)

                    Text("Center the tag in the frame")
                        .font(TFFont.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .offset(y: 110)
                }
                .offset(y: -40)

                Spacer()

                // Scan button
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 78, height: 78)

                        Circle()
                            .fill(TFColor.gainGreen)
                            .frame(width: 72, height: 72)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, TFSpacing.xl)
            }

            // Top bar with flash + gallery
            VStack {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bolt.slash.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, TFSpacing.md)
                Spacer()
            }
        }
    }
}

// MARK: - Scan Frame Shape

struct ScanFrameCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 32
        let radius: CGFloat = 12

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}

#Preview {
    ScanView()
}
