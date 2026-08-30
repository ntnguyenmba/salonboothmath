import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case spanish = "es"

    var id: String { rawValue }
    var locale: Locale {
        switch self {
        case .english: Locale(identifier: "en_US")
        case .spanish: Locale(identifier: "es_US")
        case .vietnamese: Locale(identifier: "vi_US")
        }
    }

    var displayName: String {
        switch self {
        case .english: "English"
        case .vietnamese: "Tiếng Việt"
        case .spanish: "Español"
        }
    }

    var backTitle: String { L("nav.back", table: "Hybrid", language: rawValue) }
    var cancelTitle: String { L("nav.cancel", table: "Hybrid", language: rawValue) }
    var languageTitle: String { L("settings.language", table: "Hybrid", language: rawValue) }

    static func current(_ rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .english
    }

    static var stored: AppLanguage {
        current(UserDefaults.standard.string(forKey: "appLanguage") ?? "en")
    }
}

func L(_ key: String.LocalizationValue, table: String? = nil, language: String = AppLanguage.stored.rawValue) -> String {
    let locale = AppLanguage.current(language).locale
    if let table {
        return String(localized: key, table: table, locale: locale)
    }
    return String(localized: key, locale: locale)
}

func formatCurrency(_ cents: Int, language: String = AppLanguage.stored.rawValue) -> String {
    let locale = AppLanguage.current(language).locale
    let amount = Decimal(cents) / 100
    return amount.formatted(.currency(code: "USD").locale(locale).precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
}

func appCurrencySymbol(_ language: String = AppLanguage.stored.rawValue) -> String {
    AppLanguage.current(language).locale.currencySymbol ?? "$"
}

func inputCurrencyCents(_ cents: Int) -> String {
    NSDecimalNumber(decimal: Decimal(cents) / 100).stringValue
}

func formatWeekRange(_ start: Date, language: String = AppLanguage.stored.rawValue) -> String {
    let locale = AppLanguage.current(language).locale
    let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
    let style = Date.FormatStyle.dateTime.month(.abbreviated).day().locale(locale)
    return "\(start.formatted(style))–\(end.formatted(style))"
}

func formatDay(_ date: Date, language: String = AppLanguage.stored.rawValue) -> String {
    date.formatted(Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day().locale(AppLanguage.current(language).locale))
}

struct LanguagePicker: View {
    @Binding var selection: String

    var body: some View {
        Menu {
            Picker("", selection: $selection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "globe")
                Text(AppLanguage.current(selection).displayName)
            }
            .font(Brand.font(16))
            .foregroundStyle(Brand.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Brand.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Brand.line, lineWidth: 1.5))
        }
    }
}

private struct StandardNavigationControls: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .environment(\.locale, AppLanguage.current(appLanguage).locale)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("nav.back", table: "Hybrid", language: appLanguage)) { dismiss() }
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.hotPink)
                }
            }
    }
}

extension View {
    func standardNavigationControls() -> some View {
        modifier(StandardNavigationControls())
    }
}
