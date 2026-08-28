import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @AppStorage("trade") private var savedTrade = Trade.nail.rawValue
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCutBasisPoints") private var commissionCutBasisPoints = 5500
    @AppStorage("tipOwner") private var tipOwner = TipOwner.you.rawValue
    @AppStorage("cardFeeBasisPoints") private var cardFeeBasisPoints = 290
    @AppStorage("servicesOnCardBasisPoints") private var servicesOnCardBasisPoints = 7000
    @AppStorage("taxBasisPoints") private var taxBasisPoints = 2500
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
                sectionTitle(AppLanguage.current(appLanguage).languageTitle)
                LanguagePicker(selection: $appLanguage)

                sectionTitle(String(localized: "settings.trade"))
                Picker("settings.trade", selection: $savedTrade) {
                    ForEach(Trade.allCases) { trade in
                        Text(String(localized: String.LocalizationValue(trade.titleKey))).tag(trade.rawValue)
                    }
                }.pickerStyle(.segmented)

                sectionTitle(String(localized: "settings.payModel"))
                Picker("settings.payModel", selection: $savedPayModel) {
                    Text("pay.booth").tag(PayModel.booth.rawValue)
                    Text("pay.commission").tag(PayModel.commission.rawValue)
                }.pickerStyle(.segmented)

                if savedPayModel == PayModel.booth.rawValue {
                    settingField("rent.weekly", text: $rentText, prefix: "$", suffix: nil)
                    Picker("", selection: $savedRentPeriod) {
                        Text("rent.week").tag(RentPeriod.week.rawValue)
                        Text("rent.month").tag(RentPeriod.month.rawValue)
                    }.pickerStyle(.segmented)
                } else {
                    settingField("commission.cut", text: $commissionText, prefix: nil, suffix: "%")
                    sectionTitle(String(localized: "commission.tipsWho"))
                    Picker("commission.tipsWho", selection: $tipOwner) {
                        Text("tips.you").tag(TipOwner.you.rawValue)
                        Text("tips.house").tag(TipOwner.house.rawValue)
                        Text("tips.split").tag(TipOwner.split.rawValue)
                    }.pickerStyle(.segmented)
                    Toggle("settings.workerCardFees", isOn: $workerPaysCardFees).font(Brand.font(18)).tint(Brand.hotPink)
                }

                settingField("settings.cardFee", text: $cardFeeText, prefix: nil, suffix: "%")
                settingField("settings.pctCard", text: $cardShareText, prefix: nil, suffix: "%")
                settingField("settings.tax", text: $taxText, prefix: nil, suffix: "%")
                settingField("settings.extraFees", text: $extraFeesText, prefix: "$", suffix: nil)

                Text("settings.disclaimer").font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                PrimaryButton(title: String(localized: "settings.save")) { save() }
            }.padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
        .onAppear(perform: load)
    }

    private func sectionTitle(_ title: String) -> some View { Text(title).font(Brand.font(22)) }
    private func settingField(_ key: LocalizedStringKey, text: Binding<String>, prefix: String?, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) { Text(key).font(Brand.font(18)); MoneyEntryField(text: text, prefix: prefix, suffix: suffix) }
    }
    private func load() {
        rentText = inputCurrencyCents(rentCents); commissionText = MoneyMath.percentText(fromBasisPoints: commissionCutBasisPoints); cardFeeText = MoneyMath.percentText(fromBasisPoints: cardFeeBasisPoints); cardShareText = MoneyMath.percentText(fromBasisPoints: servicesOnCardBasisPoints); taxText = MoneyMath.percentText(fromBasisPoints: taxBasisPoints); extraFeesText = inputCurrencyCents(extraFeesCents)
    }
    private func save() {
        rentCents = MoneyMath.cents(from: rentText); commissionCutBasisPoints = MoneyMath.basisPoints(fromPercentText: commissionText, fallback: 5500); cardFeeBasisPoints = MoneyMath.basisPoints(fromPercentText: cardFeeText, fallback: 290); servicesOnCardBasisPoints = MoneyMath.basisPoints(fromPercentText: cardShareText, fallback: 7000); taxBasisPoints = MoneyMath.basisPoints(fromPercentText: taxText, fallback: 2500); extraFeesCents = MoneyMath.cents(from: extraFeesText)
    }
}
