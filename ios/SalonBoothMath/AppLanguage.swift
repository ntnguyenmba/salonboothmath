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

func appLocale(_ language: String = AppLanguage.stored.rawValue) -> Locale {
    AppLanguage.current(language).locale
}

func L(_ key: String, table: String? = nil, language: String = AppLanguage.stored.rawValue) -> String {
    let lang = AppLanguage.current(language).rawValue
    if let catalog = catalogString(key: key, table: table, language: lang) {
        return catalog
    }
    let locale = Locale(identifier: lang)
    if let table {
        return String(localized: String.LocalizationValue(stringLiteral: key), table: table, locale: locale)
    }
    return String(localized: String.LocalizationValue(stringLiteral: key), locale: locale)
}

private func catalogString(key: String, table: String?, language: String) -> String? {
    let name = table ?? "Localizable"
    let nearby = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("\(name).xcstrings")
    guard FileManager.default.fileExists(atPath: nearby.path),
          let data = try? Data(contentsOf: nearby),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let strings = json["strings"] as? [String: Any],
          let entry = strings[key] as? [String: Any],
          let locs = entry["localizations"] as? [String: Any],
          let lang = locs[language] as? [String: Any],
          let unit = lang["stringUnit"] as? [String: Any],
          let value = unit["value"] as? String,
          !value.isEmpty
    else { return nil }
    return value
}

func formatCurrency(_ cents: Int, language: String = AppLanguage.stored.rawValue) -> String {
    let amount = Decimal(cents) / 100
    return amount.formatted(.currency(code: "USD").locale(appLocale(language)).precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
}

func compareVerdict(boothCents: Int, commissionCents: Int, hybridCents: Int, language: String = AppLanguage.stored.rawValue) -> String {
    let scores: [(String, Int)] = [("booth", boothCents), ("commission", commissionCents), ("hybrid", hybridCents)]
    let best = scores.map(\.1).max() ?? 0
    let winners = scores.filter { $0.1 == best }
    guard winners.count == 1 else { return L("compare.verdictTie", language: language) }
    let second = scores.filter { $0.0 != winners[0].0 }.map(\.1).max() ?? best
    let extra = best - second
    guard extra > 0 else { return L("compare.verdictTie", language: language) }
    let key: String
    switch winners[0].0 {
    case "booth": key = "compare.verdictBooth"
    case "commission": key = "compare.verdictCommission"
    default: key = "compare.verdictHybrid"
    }
    return String(format: L(key, language: language), formatCurrency(extra, language: language))
}

func appCurrencySymbol(_ language: String = AppLanguage.stored.rawValue) -> String {
    AppLanguage.current(language).locale.currencySymbol ?? "$"
}

func inputCurrencyCents(_ cents: Int) -> String {
    NSDecimalNumber(decimal: Decimal(cents) / 100).stringValue
}

func formatWeekRange(_ start: Date, language: String = AppLanguage.stored.rawValue) -> String {
    let locale = appLocale(language)
    let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
    return "\(start.formatted(.dateTime.month(.abbreviated).day().locale(locale)))–\(end.formatted(.dateTime.month(.abbreviated).day().locale(locale)))"
}

func formatDay(_ date: Date, language: String = AppLanguage.stored.rawValue) -> String {
    date.formatted(Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day().locale(appLocale(language)))
}

func formatHoursLabel(_ hours: Double, language: String = AppLanguage.stored.rawValue) -> String {
    hours.formatted(.number.precision(.fractionLength(0...1)).locale(appLocale(language)))
}

func formatHoursInput(_ hours: Double) -> String {
    hours.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "en_US_POSIX")))
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
