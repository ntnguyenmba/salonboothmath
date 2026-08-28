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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 14) {
                    BrandMark(size: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Salon Booth Math")
                            .font(Brand.font(22, weight: .heavy))
                        Text("Simple money math for salon professionals")
                            .font(Brand.font(14))
                            .foregroundStyle(Brand.muted)
                    }
                }

                sectionTitle(AppLanguage.current(appLanguage).languageTitle)
                LanguagePicker(selection: $appLanguage)

                sectionTitle(String(localized: "settings.trade"))
                Picker("settings.trade", selection: $savedTrade) {
                    ForEach(Trade.allCases) { trade in
                        Text(String(localized: String.LocalizationValue(trade.titleKey))).tag(trade.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                sectionTitle(String(localized: "settings.payModel"))
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
                    sectionTitle(String(localized: "commission.tipsWho"))
                    Picker("commission.tipsWho", selection: $tipOwner) {
                        Text("tips.you").tag(TipOwner.you.rawValue)
                        Text("tips.house").tag(TipOwner.house.rawValue)
                        Text("tips.split").tag(TipOwner.split.rawValue)
                    }
                    .pickerStyle(.segmented)
                    Toggle("settings.workerCardFees", isOn: $workerPaysCardFees)
                        .font(Brand.font(18))
                        .tint(Brand.hotPink)
                }

                settingField("settings.cardFee", text: $cardFeeText, prefix: nil, suffix: "%")
                settingField("settings.pctCard", text: $cardShareText, prefix: nil, suffix: "%")
                settingField("settings.tax", text: $taxText, prefix: nil, suffix: "%")
                settingField("settings.extraFees", text: $extraFeesText, prefix: "$", suffix: nil)

                Text("settings.disclaimer")
                    .font(Brand.font(15))
                    .foregroundStyle(Brand.mutedInk)

                PrimaryButton(title: String(localized: "settings.save")) {
                    save()
                }

                legalSupportSection
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
        .onAppear(perform: load)
    }

    private var legalSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Legal & Support")

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                settingsRow("Privacy Policy", icon: "hand.raised.fill")
            }

            NavigationLink {
                TermsOfUseView()
            } label: {
                settingsRow("Terms of Use", icon: "doc.text.fill")
            }

            Link(destination: URL(string: "mailto:support@everittventures.com?subject=Salon%20Booth%20Math%20Support")!) {
                settingsRow("Contact Support", icon: "envelope.fill")
            }

            Button {
                Task { await purchases.restore() }
            } label: {
                settingsRow("Restore Purchases", icon: "arrow.clockwise")
            }

            NavigationLink {
                AboutSalonBoothMathView()
            } label: {
                settingsRow("About", icon: "info.circle.fill")
            }

            Text("Calculations and tax reserve estimates are provided for informational purposes only and are not tax, accounting, financial, or legal advice.")
                .font(Brand.font(14))
                .foregroundStyle(Brand.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text("© 2026 Everitt Ventures LLC")
                .font(Brand.font(13))
                .foregroundStyle(Brand.muted)
        }
        .padding(.top, 8)
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Brand.hotPink)
                .frame(width: 24)
            Text(title)
                .font(Brand.font(17))
                .foregroundStyle(Brand.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Brand.muted)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(Brand.font(22, weight: .heavy))
    }

    private func settingField(_ key: LocalizedStringKey, text: Binding<String>, prefix: String?, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(key).font(Brand.font(18))
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

private struct PrivacyPolicyView: View {
    var body: some View {
        LegalTextView(
            title: "Privacy Policy",
            sections: [
                ("Privacy first", "Salon Booth Math is designed to work without an account. Your calculator entries, settings, and saved week history are stored on your device."),
                ("Data collection", "Salon Booth Math does not require you to provide a name, email address, salon name, client information, or other personal profile information to use the calculator."),
                ("Purchases", "Lifetime Access purchases are processed by Apple through the App Store. Apple handles payment information. Salon Booth Math uses StoreKit only to determine whether Lifetime Access is unlocked."),
                ("Support", "If you contact support, we receive the information you choose to include in your message so we can respond to your request."),
                ("Your control", "You can remove locally stored app data by deleting the app from your device."),
                ("Contact", "Privacy questions may be sent to support@everittventures.com. Salon Booth Math is provided by Everitt Ventures LLC.")
            ]
        )
    }
}

private struct TermsOfUseView: View {
    var body: some View {
        LegalTextView(
            title: "Terms of Use",
            sections: [
                ("Purpose", "Salon Booth Math is a calculation and record-keeping tool for salon professionals. It provides estimates based on the information and settings you enter."),
                ("No professional advice", "Results, including take-home amounts and tax reserve estimates, are informational only. They are not tax, accounting, financial, employment, or legal advice."),
                ("Your inputs", "You are responsible for checking your booth rent, commission terms, card fees, tips, expenses, taxes, and other inputs. Actual earnings and obligations may differ from app estimates."),
                ("Lifetime Access", "Lifetime Access is a one-time, non-consumable in-app purchase tied to the Apple account used to purchase it. Eligible purchases can be restored through the app."),
                ("Availability", "We may update the app to improve reliability, compatibility, calculations, or presentation. We do not guarantee that every estimate will match payroll, tax filings, salon statements, or payment processor records."),
                ("Provider", "Salon Booth Math is provided by Everitt Ventures LLC. Questions may be sent to support@everittventures.com.")
            ]
        )
    }
}

private struct AboutSalonBoothMathView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 18) {
            BrandMark(size: 92)
            Text("Salon Booth Math")
                .font(Brand.font(30, weight: .heavy))
            Text("Booth rent and commission take-home math without the salon-management clutter.")
                .font(Brand.font(17))
                .foregroundStyle(Brand.muted)
                .multilineTextAlignment(.center)
            Text("Version \(version) (\(build))")
                .font(Brand.font(15))
                .foregroundStyle(Brand.muted)
            Spacer()
            Text("© 2026 Everitt Ventures LLC")
                .font(Brand.font(14))
                .foregroundStyle(Brand.muted)
        }
        .padding(Brand.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
    }
}

private struct LegalTextView: View {
    let title: String
    let sections: [(String, String)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandMark(size: 62)
                Text(title)
                    .font(Brand.font(30, weight: .heavy))

                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.0)
                            .font(Brand.font(19, weight: .heavy))
                        Text(section.1)
                            .font(Brand.font(16))
                            .foregroundStyle(Brand.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .standardNavigationControls()
    }
}
