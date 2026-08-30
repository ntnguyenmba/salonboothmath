import WidgetKit
import SwiftUI

private let appGroup = "group.com.everittventures.salonboothmath"

struct TakeHomeEntry: TimelineEntry {
    let date: Date
    let takeHomeCents: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TakeHomeEntry {
        TakeHomeEntry(date: .now, takeHomeCents: 78000)
    }

    func getSnapshot(in context: Context, completion: @escaping (TakeHomeEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TakeHomeEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.date(byAdding: .minute, value: 20, to: now) ?? now.addingTimeInterval(1200)
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }

    private func entry() -> TakeHomeEntry {
        let cents = UserDefaults(suiteName: appGroup)?.integer(forKey: "widget.currentWeek.takeHomeCents") ?? 0
        return TakeHomeEntry(date: .now, takeHomeCents: cents)
    }
}

struct SalonBoothMathWidgetView: View {
    let entry: TakeHomeEntry
    private var language: String {
        UserDefaults(suiteName: appGroup)?.string(forKey: "widget.appLanguage") ?? "en"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color(hex: 0xFF3D6E))
                .frame(height: 4)
                .padding(.horizontal, -16)
                .padding(.top, -16)

            Spacer(minLength: 2)

            Text(widgetCopy("home.youTookHome"))
                .font(.custom("Nunito Sans", size: 15).weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(currency(entry.takeHomeCents))
                .font(.custom("Nunito Sans", size: 34).weight(.heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(widgetCopy("home.thisWeek"))
                .font(.custom("Nunito Sans", size: 16).weight(.bold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(16)
        .containerBackground(Color(hex: 0x4A1835), for: .widget)
        .widgetURL(URL(string: "salonboothmath://home"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(widgetCopy("home.youTookHome")) \(currency(entry.takeHomeCents)). \(widgetCopy("home.thisWeek"))."))
    }

    private func widgetCopy(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: Locale(identifier: language))
    }

    private func currency(_ cents: Int) -> String {
        let locale = Locale(identifier: language)
        let code = Locale.current.currency?.identifier ?? "USD"
        return (Decimal(cents) / 100).formatted(.currency(code: code).locale(locale).precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
    }
}

struct SalonBoothMathWidget: Widget {
    let kind = "SalonBoothMathWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SalonBoothMathWidgetView(entry: entry)
        }
        .configurationDisplayName("Salon Booth Math")
        .description("widget.description")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct SalonBoothMathWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalonBoothMathWidget()
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
