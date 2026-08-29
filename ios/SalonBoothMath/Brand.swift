import SwiftUI

// Brand system derived directly from the Salon Booth Math app icon.
enum Brand {
    static let page = Color(hex: 0x4B0728)
    static let surface = Color(hex: 0x35051D)
    static let surfaceRaised = Color(hex: 0x5A0A31)
    static let ink = Color.white
    static let muted = Color.white.opacity(0.78)
    static let mutedInk = muted
    static let berry = Color(hex: 0x4B0728)
    static let hotPink = Color(hex: 0xFF3D6E)
    static let warning = hotPink
    static let error = hotPink
    static let line = Color.white.opacity(0.22)

    static let screenPadding: CGFloat = 22
    static let controlRadius: CGFloat = 18
    static let controlHeight: CGFloat = 60

    static func font(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct BrandMark: View {
    var size: CGFloat = 58

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Brand.surface)

            Image(systemName: "chair.lounge.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: -size * 0.07, y: size * 0.03)

            Text("$")
                .font(Brand.font(size * 0.42, weight: .heavy))
                .foregroundStyle(Brand.hotPink)
                .offset(x: size * 0.20, y: -size * 0.05)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
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
