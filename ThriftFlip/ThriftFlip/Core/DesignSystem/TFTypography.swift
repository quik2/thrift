import SwiftUI

enum TFFont {
    static let display = Font.system(size: 42, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let caption = Font.system(size: 14, weight: .medium, design: .default)
    static let micro = Font.system(size: 12, weight: .regular, design: .default)
}
