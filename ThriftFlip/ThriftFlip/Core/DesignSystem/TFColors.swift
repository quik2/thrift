import SwiftUI
import UIKit

enum TFColor {
    // MARK: - Semantic Surfaces (adapt to light/dark)
    static let background = Color("TFBackground")
    static let cardSurface = Color("TFCardSurface")

    // MARK: - Text
    static let textPrimary = Color("TFTextPrimary")
    static let textSecondary = Color("TFTextSecondary")
    static let textTertiary = Color("TFTextTertiary")

    // MARK: - Fixed Accent Colors
    static let gainGreen = Color(hex: "#5AC53A")
    static let gainGreenSoft = Color(hex: "#88D56F")
    static let warning = Color(hex: "#EB5D2A")
    static let gold = Color(hex: "#F6C86A")

    // MARK: - Borders
    static let borderSubtle = Color.white.opacity(0.12)
    static let borderInnerHighlight = Color.white.opacity(0.06)
}

// MARK: - Fallback colors when asset catalog is not configured
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Adaptive colors that resolve correctly in light/dark
    static let tfBackground = Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#1F2123"))
    static let tfCardSurface = Color(light: Color(hex: "#F5F5F7"), dark: Color(hex: "#2A2C2E"))
    static let tfTextPrimary = Color(light: Color(hex: "#1A1A1A"), dark: Color(hex: "#FFFFFF"))
    static let tfTextSecondary = Color(light: Color(hex: "#6B7280"), dark: Color(hex: "#9CA3AF"))
    static let tfTextTertiary = Color(light: Color(hex: "#9CA3AF"), dark: Color(hex: "#48484A"))

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
