import SwiftUI

// Locked v1 design system. Do not introduce trade-specific themes.
enum Brand {
    static let page = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x0B1220)
    static let berry = Color(hex: 0x4B0728)
    static let hotPink = Color(hex: 0xFF3D6E)
    static let warning = Color(hex: 0xC2410C)
    static let error = Color(hex: 0xB42318)
    static let line = Color(hex: 0x0B1220).opacity(0.10)

    static let screenPadding: CGFloat = 22
    static let controlRadius: CGFloat = 18
    static let controlHeight: CGFloat = 60

    static func font(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
