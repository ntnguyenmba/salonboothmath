import SwiftUI
import UIKit

struct TakeHomeShareCard: View {
    let takeHomeCents: Int
    let weekStart: Date
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Brand.hotPink)
                .frame(height: 8)

            VStack(alignment: .leading, spacing: 18) {
                Text(L("home.youTookHome", language: appLanguage))
                    .font(Brand.font(22, weight: .heavy))
                    .foregroundStyle(.white)

                Text(formatCurrency(takeHomeCents, language: appLanguage))
                    .font(Brand.font(64, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(formatWeekRange(weekStart, language: appLanguage))
                    .font(Brand.font(20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer(minLength: 28)

                Text("Salon Booth Math")
                    .font(Brand.font(20, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Brand.berry)
        }
        .frame(width: 1080, height: 1080)
    }
}

@MainActor
enum ShareCardRenderer {
    static func image(takeHomeCents: Int, weekStart: Date) -> UIImage? {
        let renderer = ImageRenderer(content: TakeHomeShareCard(takeHomeCents: takeHomeCents, weekStart: weekStart))
        renderer.scale = 1
        return renderer.uiImage
    }
}
