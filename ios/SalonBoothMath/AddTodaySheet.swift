import SwiftUI

struct AddTodaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @State private var services = ""
    @State private var cashTips = ""
    @State private var cardTips = ""
    @State private var supplies = ""
    @State private var hours = ""
    let onAdd: (DayLine) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("home.addToday", table: "Hybrid", language: appLanguage))
                            .font(Brand.font(28, weight: .heavy))
                        Text(formatDay(Date(), language: appLanguage))
                            .font(Brand.font(16))
                            .foregroundStyle(Brand.mutedInk)
                    }
                    Spacer()
                    Button(L("nav.cancel", table: "Hybrid", language: appLanguage)) { dismiss() }
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.hotPink)
                }
                TodayMoneyField(title: L("field.services", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $services)
                TodayMoneyField(title: L("field.tipsCash", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $cashTips)
                TodayMoneyField(title: L("field.tipsCard", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $cardTips)
                TodayMoneyField(title: L("field.supplies", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $supplies)
                VStack(alignment: .leading, spacing: 10) {
                    Text(L("settings.hoursToday", table: "Hybrid", language: appLanguage)).font(Brand.font(17))
                    TextField("0", text: $hours)
                        .keyboardType(.decimalPad)
                        .font(Brand.font(22, weight: .heavy))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 58)
                        .background(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
                }
                PrimaryButton(title: L("home.addToWeek", table: "Hybrid", language: appLanguage)) {
                    let normalizedHours = hours.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                    onAdd(DayLine(
                        dateStart: Date(),
                        servicesCents: MoneyMath.cents(from: services),
                        cashTipsCents: MoneyMath.cents(from: cashTips),
                        cardTipsCents: MoneyMath.cents(from: cardTips),
                        suppliesCents: MoneyMath.cents(from: supplies),
                        hours: Double(normalizedHours).flatMap { $0 > 0 ? $0 : nil }
                    ))
                    dismiss()
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .environment(\.locale, AppLanguage.current(appLanguage).locale)
    }
}

private struct TodayMoneyField: View {
    let title: String
    let currencySymbol: String
    @Binding var text: String
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Brand.font(17))
            HStack(spacing: 8) {
                Text(currencySymbol)
                TextField("0", text: $text).keyboardType(.decimalPad).focused($focused)
            }
            .font(Brand.font(25, weight: .heavy))
            .padding(.horizontal, 16)
            .frame(minHeight: 60)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line, lineWidth: focused ? 3 : 2))
        }
    }
}
