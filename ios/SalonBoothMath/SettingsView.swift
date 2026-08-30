import SwiftUI
import StoreKit

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

    @StateObject private var purchases = PurchaseManager()
    @State private var rentText = ""
    @State private var commissionText = ""
    @State private var cardFeeText = ""
    @State private var cardShareText = ""
    @State private var taxText = ""
    @State private var extraFeesText = ""

    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var model: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var selectedTipOwner: TipOwner { TipOwner(rawValue: tipOwner) ?? .you }
    private var houseKeepPercent: Int { max(0, 100 - commissionCutBasisPoints / 100) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 14) {
                    BrandMark(size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Salon Booth Math").font(Brand.font(22, weight: .heavy))
                        Text(L("settings.tagline", language: appLanguage))
                            .font(Brand.font(16)).foregroundStyle(Brand.muted)
                    }
                }

                sectionTitle(language.languageTitle)
                LanguagePicker(selection: $appLanguage)

                sectionTitle(L("settings.trade", language: appLanguage))
                Picker(L("settings.trade", language: appLanguage), selection: $savedTrade) {
                    ForEach(Trade.allCases) { trade in
                        Text(L(trade.titleKey, language: appLanguage)).tag(trade.rawValue)
                    }
                }.pickerStyle(.segmented)

                sectionTitle(L("settings.payModel", language: appLanguage))
                Picker(L("settings.payModel", language: appLanguage), selection: $savedPayModel) {
                    Text(L("pay.booth", language: appLanguage)).tag(PayModel.booth.rawValue)
                    Text(L("pay.commission", language: appLanguage)).tag(PayModel.commission.rawValue)
                    Text(L("pay.hybrid", table: "Hybrid", language: appLanguage)).tag(PayModel.hybrid.rawValue)
                }.pickerStyle(.segmented)

                if model != .commission {
                    settingField("rent.weekly", text: $rentText, prefix: "$", suffix: nil)
                    Text(L("settings.rentPeriod", language: appLanguage)).font(Brand.font(18))
                    Picker(L("settings.rentPeriod", language: appLanguage), selection: $savedRentPeriod) {
                        Text(L("rent.week", language: appLanguage)).tag(RentPeriod.week.rawValue)
                        Text(L("rent.month", language: appLanguage)).tag(RentPeriod.month.rawValue)
                    }.pickerStyle(.segmented)
                }

                if model != .booth {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("settings.serviceSplit", table: "Hybrid", language: appLanguage)).font(Brand.font(18))
                        MoneyEntryField(text: $commissionText, prefix: nil, suffix: "%")
                        Text(String(format: L("settings.houseKeeps", table: "Hybrid", language: appLanguage), houseKeepPercent))
                            .font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                    }

                    sectionTitle(L("commission.tipsWho", language: appLanguage))
                    Picker(L("commission.tipsWho", language: appLanguage), selection: $tipOwner) {
                        Text(L("tips.you", language: appLanguage)).tag(TipOwner.you.rawValue)
                        Text(L("tips.house", language: appLanguage)).tag(TipOwner.house.rawValue)
                        Text(L("tips.split5050", table: "Hybrid", language: appLanguage)).tag(TipOwner.split.rawValue)
                    }
                    .pickerStyle(.segmented)

                    Text(tipRuleExplanation)
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Toggle(L("settings.workerCardFees", language: appLanguage), isOn: $workerPaysCardFees)
                        .font(Brand.font(18)).tint(Brand.hotPink)
                }

                settingField("settings.cardFee", text: $cardFeeText, prefix: nil, suffix: "%")
                settingField("settings.pctCard", text: $cardShareText, prefix: nil, suffix: "%")
                settingField("settings.tax", text: $taxText, prefix: nil, suffix: "%")
                Text(L("settings.taxNote", table: "Hybrid", language: appLanguage)).font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                settingField("settings.extraFees", text: $extraFeesText, prefix: "$", suffix: nil)

                Text(L("settings.disclaimer", language: appLanguage)).font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                PrimaryButton(title: L("settings.save", language: appLanguage)) { save() }
                legalSupportSection
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .environment(\.locale, AppLanguage.current(appLanguage).locale)
        .navigationTitle(L("settings.title", language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
        .onAppear(perform: load)
    }

    private var tipRuleExplanation: String {
        switch selectedTipOwner {
        case .you: return L("settings.tipYou", language: appLanguage)
        case .house: return L("settings.tipHouse", language: appLanguage)
        case .split: return L("settings.tipSplit", language: appLanguage)
        }
    }

    private var legalSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(L("settings.legal", language: appLanguage))
            Link(destination: LegalURLs.privacy) { settingsRow(L("settings.privacy", language: appLanguage), icon: "hand.raised.fill") }
            Link(destination: LegalURLs.terms) { settingsRow(L("settings.terms", language: appLanguage), icon: "doc.text.fill") }
            Link(destination: LegalURLs.support) { settingsRow(L("settings.support", language: appLanguage), icon: "envelope.fill") }
            Button { Task { await purchases.restore() } } label: { settingsRow(L("paywall.restore", language: appLanguage), icon: "arrow.clockwise") }
            NavigationLink { AboutSalonBoothMathView() } label: { settingsRow(L("settings.about", language: appLanguage), icon: "info.circle.fill") }
            Text(L("legal.disclaimer", language: appLanguage))
                .font(Brand.font(16)).foregroundStyle(Brand.muted).fixedSize(horizontal: false, vertical: true)
            Text("© 2026 Everitt Ventures LLC").font(Brand.font(16)).foregroundStyle(Brand.muted)
        }
        .padding(.top, 8)
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Brand.hotPink).frame(width: 24)
            Text(title).font(Brand.font(17)).foregroundStyle(Brand.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold)).foregroundStyle(Brand.muted)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1))
    }

    private func sectionTitle(_ title: String) -> some View { Text(title).font(Brand.font(22, weight: .heavy)) }

    private func settingField(_ key: String, text: Binding<String>, prefix: String?, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L(key, language: appLanguage)).font(Brand.font(18))
            MoneyEntryField(text: text, prefix: prefix, suffix: suffix)
        }
    }

    private func load() {
        rentText = inputCurrencyCents(rentCents)
        commissionText = MoneyMath.percentText(fromBasisPoints: commissionCutBasisPoints)
        cardFeeText = MoneyMath.percentText(fromBasisPoints: cardFeeBasisPoints)
        cardShareText = MoneyMath.percentText(fromBasisPoints: servicesOnCardBasisPoints)
        taxText = MoneyMath.percentText(fromBasisPoints: taxBasisPoints)
        extraFeesText = inputCurrencyCents(extraFeesCents)
    }

    private func save() {
        rentCents = MoneyMath.cents(from: rentText)
        commissionCutBasisPoints = MoneyMath.basisPoints(fromPercentText: commissionText, fallback: 5500)
        cardFeeBasisPoints = MoneyMath.basisPoints(fromPercentText: cardFeeText, fallback: 290)
        servicesOnCardBasisPoints = MoneyMath.basisPoints(fromPercentText: cardShareText, fallback: 7000)
        taxBasisPoints = MoneyMath.basisPoints(fromPercentText: taxText, fallback: 2500)
        extraFeesCents = MoneyMath.cents(from: extraFeesText)
    }

}

private struct AboutSalonBoothMathView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        VStack(spacing: 18) {
            BrandMark(size: 92)
            Text("Salon Booth Math").font(Brand.font(30, weight: .heavy))
            Text(L("settings.aboutBody", language: appLanguage))
                .font(Brand.font(17)).foregroundStyle(Brand.muted).multilineTextAlignment(.center)
            Text(String(format: L("settings.version", language: appLanguage), version, build))
                .font(Brand.font(16)).foregroundStyle(Brand.muted)
            Spacer()
            Text("© 2026 Everitt Ventures LLC").font(Brand.font(16)).foregroundStyle(Brand.muted)
        }
        .padding(Brand.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .navigationTitle(L("settings.about", language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
    }
}
