import SwiftUI

struct SettingsView: View {
    @AppStorage("trade") private var savedTrade = Trade.nail.rawValue
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var commissionCut = 0.55
    @AppStorage("cardFeeRate") private var cardFeeRate = 0.029
    @AppStorage("percentServicesOnCard") private var percentServicesOnCard = 0.70
    @AppStorage("taxRate") private var taxRate = 0.25
    @AppStorage("extraFeesCents") private var extraFeesCents = 0
    @AppStorage("workerPaysCardFees") private var workerPaysCardFees = false

    @State private var rentText = ""
    @State private var commissionText = ""
    @State private var cardFeeText = ""
    @State private var cardShareText = ""
    @State private var taxText = ""
    @State private var extraFeesText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                sectionTitle("settings.trade")
                Picker("settings.trade", selection: $savedTrade) {
                    ForEach(Trade.allCases) { trade in
                        Text(String(localized: String.LocalizationValue(trade.titleKey))).tag(trade.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                sectionTitle("settings.payModel")
                Picker("settings.payModel", selection: $savedPayModel) {
                    Text("pay.booth").tag(PayModel.booth.rawValue)
                    Text("pay.commission").tag(PayModel.commission.rawValue)
                }
                .pickerStyle(.segmented)

                if savedPayModel == PayModel.booth.rawValue {
                    settingField("rent.weekly", text: $rentText, prefix: "$", suffix: nil)
                    Picker("", selection: $savedRentPeriod) {
                        Text("rent.week").tag(RentPeriod.week.rawValue)
                        Text("rent.month").tag(RentPeriod.month.rawValue)
                    }
                    .pickerStyle(.segmented)
                } else {
                    settingField("commission.cut", text: $commissionText, prefix: nil, suffix: "%")
                    Toggle("I pay the card processing fees", isOn: $workerPaysCardFees)
                        .font(Brand.font(18, weight: .heavy))
                        .tint(Brand.hotPink)
                }

                settingField("settings.cardFee", text: $cardFeeText, prefix: nil, suffix: "%")
                settingField("settings.pctCard", text: $cardShareText, prefix: nil, suffix: "%")
                settingField("settings.tax", text: $taxText, prefix: nil, suffix: "%")
                settingField("settings.extraFees", text: $extraFeesText, prefix: "$", suffix: nil)

                Text("settings.disclaimer")
                    .font(Brand.font(16, weight: .bold))
                    .foregroundStyle(Brand.berry)

                PrimaryButton(title: String(localized: "settings.save")) { save() }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page)
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key).font(Brand.font(22, weight: .heavy))
    }

    private func settingField(_ key: LocalizedStringKey, text: Binding<String>, prefix: String?, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(key).font(Brand.font(18, weight: .heavy))
            MoneyEntryField(text: text, prefix: prefix, suffix: suffix)
        }
    }

    private func load() {
        rentText = String(format: "%.0f", Double(rentCents) / 100)
        commissionText = String(format: "%.0f", commissionCut * 100)
        cardFeeText = String(format: "%.1f", cardFeeRate * 100)
        cardShareText = String(format: "%.0f", percentServicesOnCard * 100)
        taxText = String(format: "%.0f", taxRate * 100)
        extraFeesText = String(format: "%.0f", Double(extraFeesCents) / 100)
    }

    private func save() {
        rentCents = MoneyMath.cents(from: rentText)
        commissionCut = (Double(commissionText) ?? 55) / 100
        cardFeeRate = (Double(cardFeeText) ?? 2.9) / 100
        percentServicesOnCard = (Double(cardShareText) ?? 70) / 100
        taxRate = (Double(taxText) ?? 25) / 100
        extraFeesCents = MoneyMath.cents(from: extraFeesText)
    }
}
