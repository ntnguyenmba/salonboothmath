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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 14) {
                    BrandMark(size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Salon Booth Math").font(Brand.font(22, weight: .heavy))
                        Text(copy(en: "Simple money math for salon professionals", es: "Cálculos simples de dinero para profesionales de salón", vi: "Tính tiền đơn giản cho người làm salon"))
                            .font(Brand.font(16)).foregroundStyle(Brand.muted)
                    }
                }

                sectionTitle(language.languageTitle)
                LanguagePicker(selection: $appLanguage)

                sectionTitle(String(localized: "settings.trade"))
                Picker("settings.trade", selection: $savedTrade) {
                    ForEach(Trade.allCases) { trade in Text(String(localized: String.LocalizationValue(trade.titleKey))).tag(trade.rawValue) }
                }.pickerStyle(.segmented)

                sectionTitle(String(localized: "settings.payModel"))
                Picker("settings.payModel", selection: $savedPayModel) {
                    Text("pay.booth").tag(PayModel.booth.rawValue)
                    Text("pay.commission").tag(PayModel.commission.rawValue)
                    Text("pay.hybrid").tag(PayModel.hybrid.rawValue)
                }.pickerStyle(.segmented)

                if model != .commission {
                    settingField("rent.weekly", text: $rentText, prefix: "$", suffix: nil)
                    Picker("", selection: $savedRentPeriod) {
                        Text("rent.week").tag(RentPeriod.week.rawValue)
                        Text("rent.month").tag(RentPeriod.month.rawValue)
                    }.pickerStyle(.segmented)
                }

                if model != .booth {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "settings.serviceSplit", table: "Hybrid")).font(Brand.font(18))
                        MoneyEntryField(text: $commissionText, prefix: nil, suffix: "%")
                        Text(String(format: String(localized: "settings.houseKeeps", table: "Hybrid"), max(0, 100 - commissionCutBasisPoints / 100)))
                            .font(Brand.font(16))
                            .foregroundStyle(Brand.mutedInk)
                    }
                    sectionTitle(String(localized: "commission.tipsWho"))
                    Picker("commission.tipsWho", selection: $tipOwner) {
                        Text("tips.you").tag(TipOwner.you.rawValue)
                        Text("tips.house").tag(TipOwner.house.rawValue)
                        Text(String(localized: "tips.split5050", table: "Hybrid")).tag(TipOwner.split.rawValue)
                    }.pickerStyle(.segmented)
                    Toggle("settings.workerCardFees", isOn: $workerPaysCardFees).font(Brand.font(18)).tint(Brand.hotPink)
                }

                settingField("settings.cardFee", text: $cardFeeText, prefix: nil, suffix: "%")
                settingField("settings.pctCard", text: $cardShareText, prefix: nil, suffix: "%")
                settingField("settings.tax", text: $taxText, prefix: nil, suffix: "%")
                Text("settings.taxNote").font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                settingField("settings.extraFees", text: $extraFeesText, prefix: "$", suffix: nil)

                Text("settings.disclaimer").font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                PrimaryButton(title: String(localized: "settings.save")) { save() }
                legalSupportSection
            }.padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink)
        .navigationTitle(Text("settings.title")).navigationBarTitleDisplayMode(.inline).standardNavigationControls().onAppear(perform: load)
    }

    private var legalSupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(copy(en: "Legal & Support", es: "Legal y soporte", vi: "Pháp lý & hỗ trợ"))
            Link(destination: LegalURLs.privacy) { settingsRow(copy(en: "Privacy Policy", es: "Política de privacidad", vi: "Chính sách quyền riêng tư"), icon: "hand.raised.fill") }
            Link(destination: LegalURLs.terms) { settingsRow(copy(en: "Terms of Use", es: "Términos de uso", vi: "Điều khoản sử dụng"), icon: "doc.text.fill") }
            Link(destination: LegalURLs.support) { settingsRow(copy(en: "Contact Support", es: "Contactar soporte", vi: "Liên hệ hỗ trợ"), icon: "envelope.fill") }
            Button { Task { await purchases.restore() } } label: { settingsRow(copy(en: "Restore Purchases", es: "Restaurar compras", vi: "Khôi phục giao dịch mua"), icon: "arrow.clockwise") }
            NavigationLink { AboutSalonBoothMathView() } label: { settingsRow(copy(en: "About", es: "Acerca de", vi: "Giới thiệu"), icon: "info.circle.fill") }
            Text(copy(en: "Calculations and tax reserve estimates are for informational purposes only and are not tax, accounting, financial, or legal advice.", es: "Los cálculos y las estimaciones de reserva para impuestos son solo informativos y no constituyen asesoría fiscal, contable, financiera ni legal.", vi: "Các phép tính và ước tính khoản để dành cho thuế chỉ mang tính thông tin, không phải tư vấn thuế, kế toán, tài chính hoặc pháp lý."))
                .font(Brand.font(16)).foregroundStyle(Brand.muted).fixedSize(horizontal: false, vertical: true)
            Text("© 2026 Everitt Ventures LLC").font(Brand.font(16)).foregroundStyle(Brand.muted)
        }.padding(.top, 8)
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(Brand.hotPink).frame(width: 24)
            Text(title).font(Brand.font(17)).foregroundStyle(Brand.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold)).foregroundStyle(Brand.muted)
        }.padding(.horizontal, 16).frame(minHeight: 56).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1))
    }
    private func sectionTitle(_ title: String) -> some View { Text(title).font(Brand.font(22, weight: .heavy)) }
    private func settingField(_ key: LocalizedStringKey, text: Binding<String>, prefix: String?, suffix: String?) -> some View { VStack(alignment: .leading, spacing: 10) { Text(key).font(Brand.font(18)); MoneyEntryField(text: text, prefix: prefix, suffix: suffix) } }
    private func load() { rentText = inputCurrencyCents(rentCents); commissionText = MoneyMath.percentText(fromBasisPoints: commissionCutBasisPoints); cardFeeText = MoneyMath.percentText(fromBasisPoints: cardFeeBasisPoints); cardShareText = MoneyMath.percentText(fromBasisPoints: servicesOnCardBasisPoints); taxText = MoneyMath.percentText(fromBasisPoints: taxBasisPoints); extraFeesText = inputCurrencyCents(extraFeesCents) }
    private func save() { rentCents = MoneyMath.cents(from: rentText); commissionCutBasisPoints = MoneyMath.basisPoints(fromPercentText: commissionText, fallback: 5500); cardFeeBasisPoints = MoneyMath.basisPoints(fromPercentText: cardFeeText, fallback: 290); servicesOnCardBasisPoints = MoneyMath.basisPoints(fromPercentText: cardShareText, fallback: 7000); taxBasisPoints = MoneyMath.basisPoints(fromPercentText: taxText, fallback: 2500); extraFeesCents = MoneyMath.cents(from: extraFeesText) }
    private func copy(en: String, es: String, vi: String) -> String { switch language { case .english: en; case .spanish: es; case .vietnamese: vi } }
}

private struct AboutSalonBoothMathView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }
    var body: some View {
        VStack(spacing: 18) {
            BrandMark(size: 92); Text("Salon Booth Math").font(Brand.font(30, weight: .heavy))
            Text(localized(language, en: "Booth, commission, and hybrid take-home math without salon-management clutter.", es: "Cálculo de ingresos netos para puesto, comisión e híbrido, sin el exceso de gestión de salón.", vi: "Tính tiền còn lại cho thuê booth, chia phần dịch vụ và kiểu kết hợp, không kèm phần mềm quản lý salon rườm rà."))
                .font(Brand.font(17)).foregroundStyle(Brand.muted).multilineTextAlignment(.center)
            Text(localized(language, en: "Version", es: "Versión", vi: "Phiên bản") + " \(version) (\(build))").font(Brand.font(16)).foregroundStyle(Brand.muted)
            Spacer(); Text("© 2026 Everitt Ventures LLC").font(Brand.font(16)).foregroundStyle(Brand.muted)
        }.padding(Brand.screenPadding).frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).navigationTitle(localized(language, en: "About", es: "Acerca de", vi: "Giới thiệu")).navigationBarTitleDisplayMode(.inline).standardNavigationControls()
    }
}

private func localized(_ language: AppLanguage, en: String, es: String, vi: String) -> String { switch language { case .english: en; case .spanish: es; case .vietnamese: vi } }
