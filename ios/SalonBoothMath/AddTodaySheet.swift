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

    private var language: AppLanguage { AppLanguage.current(appLanguage) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy(en: "Add today", es: "Agregar hoy", vi: "Thêm hôm nay"))
                            .font(Brand.font(28, weight: .heavy))
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(Brand.font(16))
                            .foregroundStyle(Brand.mutedInk)
                    }
                    Spacer()
                    Button(language.cancelTitle) { dismiss() }
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.hotPink)
                }

                TodayMoneyField(title: copy(en: "Services", es: "Servicios", vi: "Dịch vụ"), text: $services)
                TodayMoneyField(title: copy(en: "Cash tips", es: "Propinas en efectivo", vi: "Tip tiền mặt"), text: $cashTips)
                TodayMoneyField(title: copy(en: "Card tips", es: "Propinas con tarjeta", vi: "Tip qua thẻ"), text: $cardTips)
                TodayMoneyField(title: copy(en: "Supplies", es: "Insumos", vi: "Đồ nghề / sản phẩm"), text: $supplies)

                VStack(alignment: .leading, spacing: 10) {
                    Text(copy(en: "Hours today · optional", es: "Horas de hoy · opcional", vi: "Số giờ hôm nay · tùy chọn"))
                        .font(Brand.font(17))
                    TextField("0", text: $hours)
                        .keyboardType(.decimalPad)
                        .font(Brand.font(22, weight: .heavy))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 58)
                        .background(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
                }

                PrimaryButton(title: copy(en: "Add to this week", es: "Agregar a esta semana", vi: "Thêm vào tuần này")) {
                    let normalizedHours = hours.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
                    let line = DayLine(
                        dateStart: Date(),
                        servicesCents: MoneyMath.cents(from: services),
                        cashTipsCents: MoneyMath.cents(from: cashTips),
                        cardTipsCents: MoneyMath.cents(from: cardTips),
                        suppliesCents: MoneyMath.cents(from: supplies),
                        hours: Double(normalizedHours).flatMap { $0 > 0 ? $0 : nil }
                    )
                    onAdd(line)
                    dismiss()
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
    }

    private func copy(en: String, es: String, vi: String) -> String {
        switch language {
        case .english: en
        case .spanish: es
        case .vietnamese: vi
        }
    }
}

private struct TodayMoneyField: View {
    let title: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Brand.font(17))
            HStack(spacing: 8) {
                Text(Locale.current.currencySymbol ?? "$")
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
