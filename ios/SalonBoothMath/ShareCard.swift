import SwiftUI

struct TakeHomeShareCard: View {
    let takeHomeCents: Int
    let weekStart: Date

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Brand.hotPink)
                .frame(height: 8)

            VStack(alignment: .leading, spacing: 18) {
                Text(L("home.youTookHome", language: appLanguage))
                    .font(Brand.font(22, weight: .heavy))
                    .foregroundStyle(.white)

                Text(currency(takeHomeCents))
                    .font(Brand.font(64, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(weekRange)
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

    private var weekRange: String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return weekStart.formatted(.dateTime.month(.abbreviated).day()) + "–" + end.formatted(.dateTime.day())
    }

    private func currency(_ cents: Int) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
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
