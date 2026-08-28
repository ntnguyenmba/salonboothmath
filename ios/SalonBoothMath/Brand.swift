import SwiftUI

// High-contrast v1 design system.
enum Brand {
    static let page = Color(hex: 0x0B0B0F)
    static let surface = Color(hex: 0x18181F)
    static let ink = Color(hex: 0xFFFFFF)
    static let muted = Color.white.opacity(0.78)
    static let mutedInk = muted
    static let berry = Color(hex: 0x4B0728)
    static let hotPink = Color(hex: 0xFF3D6E)
    static let warning = Color(hex: 0xFFB86B)
    static let error = Color(hex: 0xFF7A72)
    static let line = Color.white.opacity(0.20)

    static let screenPadding: CGFloat = 22
    static let controlRadius: CGFloat = 18
    static let controlHeight: CGFloat = 60

    // Nunito is the app typography target. If the font asset is unavailable in a
    // development build, SwiftUI falls back cleanly to a bold rounded system face.
    static func font(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name: String
        switch weight {
        case .heavy, .black: name = "Nunito-ExtraBold"
        default: name = "Nunito-Bold"
        }
        return .custom(name, size: size).weight(weight)
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
