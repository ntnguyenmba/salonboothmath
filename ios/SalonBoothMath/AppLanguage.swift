import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .vietnamese: "Tiếng Việt"
        case .spanish: "Español"
        }
    }

    var backTitle: String {
        switch self {
        case .english: "Back"
        case .vietnamese: "Quay lại"
        case .spanish: "Atrás"
        }
    }

    var cancelTitle: String {
        switch self {
        case .english: "Cancel"
        case .vietnamese: "Hủy"
        case .spanish: "Cancelar"
        }
    }

    var languageTitle: String {
        switch self {
        case .english: "Language"
        case .vietnamese: "Ngôn ngữ"
        case .spanish: "Idioma"
        }
    }

    static func current(_ rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .english
    }
}

func appLocalized(_ key: String, language: String) -> String {
    String(localized: String.LocalizationValue(key), locale: Locale(identifier: language))
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppLanguage.current(appLanguage).backTitle) { dismiss() }
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
