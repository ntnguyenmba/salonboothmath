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
            NavigationLink { PrivacyPolicyView() } label: { settingsRow(copy(en: "Privacy Policy", es: "Política de privacidad", vi: "Chính sách quyền riêng tư"), icon: "hand.raised.fill") }
            NavigationLink { TermsOfUseView() } label: { settingsRow(copy(en: "Terms of Use", es: "Términos de uso", vi: "Điều khoản sử dụng"), icon: "doc.text.fill") }
            Link(destination: URL(string: "mailto:support@everittventures.com?subject=Salon%20Booth%20Math%20Support")!) { settingsRow(copy(en: "Contact Support", es: "Contactar soporte", vi: "Liên hệ hỗ trợ"), icon: "envelope.fill") }
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

private struct PrivacyPolicyView: View { @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue; private var language: AppLanguage { AppLanguage.current(appLanguage) }; var body: some View { let content = privacyContent(language); LegalTextView(title: content.title, sections: content.sections) } }
private struct TermsOfUseView: View { @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue; private var language: AppLanguage { AppLanguage.current(appLanguage) }; var body: some View { let content = termsContent(language); LegalTextView(title: content.title, sections: content.sections) } }

private struct AboutSalonBoothMathView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }
    var body: some View {
        VStack(spacing: 18) {
            BrandMark(size: 92); Text("Salon Booth Math").font(Brand.font(30, weight: .heavy))
            Text(localized(language, en: "Booth, commission, and hybrid take-home math without salon-management clutter.", es: "Cálculo de ingresos netos para puesto, comisión e híbrido, sin el exceso de gestión de salón.", vi: "Tính tiền còn lại cho booth, hoa hồng và hybrid, không kèm phần mềm quản lý salon rườm rà."))
                .font(Brand.font(17)).foregroundStyle(Brand.muted).multilineTextAlignment(.center)
            Text(localized(language, en: "Version", es: "Versión", vi: "Phiên bản") + " \(version) (\(build))").font(Brand.font(16)).foregroundStyle(Brand.muted)
            Spacer(); Text("© 2026 Everitt Ventures LLC").font(Brand.font(16)).foregroundStyle(Brand.muted)
        }.padding(Brand.screenPadding).frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).navigationTitle(localized(language, en: "About", es: "Acerca de", vi: "Giới thiệu")).navigationBarTitleDisplayMode(.inline).standardNavigationControls()
    }
}

private struct LegalTextView: View {
    let title: String; let sections: [(String, String)]
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 22) { BrandMark(size: 62); Text(title).font(Brand.font(30, weight: .heavy)); ForEach(Array(sections.enumerated()), id: \.offset) { _, section in VStack(alignment: .leading, spacing: 8) { Text(section.0).font(Brand.font(19, weight: .heavy)); Text(section.1).font(Brand.font(16)).foregroundStyle(Brand.muted).fixedSize(horizontal: false, vertical: true) } } }.padding(Brand.screenPadding) }.background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).navigationTitle(title).navigationBarTitleDisplayMode(.inline).standardNavigationControls() }
}

private func privacyContent(_ language: AppLanguage) -> (title: String, sections: [(String, String)]) {
    switch language {
    case .english: return ("Privacy Policy", [("Privacy first", "Salon Booth Math works without an account. Your calculator entries, settings, and saved week history are stored on your device."), ("Data collection", "You do not need to provide a name, email address, salon name, client information, or personal profile to use the calculator."), ("Purchases", "Lifetime purchases are processed by Apple through the App Store. Apple handles payment information. Salon Booth Math uses StoreKit only to determine whether Lifetime access is unlocked."), ("Support", "If you contact support, we receive only the information you choose to include so we can respond."), ("Your control", "You can remove locally stored app data by deleting the app from your device."), ("Contact", "Privacy questions may be sent to support@everittventures.com. Salon Booth Math is provided by Everitt Ventures LLC.")])
    case .spanish: return ("Política de privacidad", [("Privacidad primero", "Salon Booth Math funciona sin una cuenta. Tus datos del cálculo, configuración e historial de semanas guardadas se almacenan en tu dispositivo."), ("Recopilación de datos", "No necesitas proporcionar nombre, correo electrónico, nombre del salón, información de clientes ni un perfil personal para usar la calculadora."), ("Compras", "Las compras Lifetime se procesan por Apple mediante App Store. Apple gestiona la información de pago. Salon Booth Math usa StoreKit solo para saber si Lifetime está desbloqueado."), ("Soporte", "Si contactas soporte, recibimos únicamente la información que decidas incluir para poder responder."), ("Tu control", "Puedes eliminar los datos guardados localmente borrando la app de tu dispositivo."), ("Contacto", "Puedes enviar preguntas de privacidad a support@everittventures.com. Salon Booth Math es ofrecida por Everitt Ventures LLC.")])
    case .vietnamese: return ("Chính sách quyền riêng tư", [("Ưu tiên quyền riêng tư", "Salon Booth Math hoạt động không cần tài khoản. Dữ liệu tính toán, cài đặt và lịch sử tuần đã lưu được lưu trên thiết bị của bạn."), ("Thu thập dữ liệu", "Bạn không cần cung cấp tên, email, tên salon, thông tin khách hàng hoặc hồ sơ cá nhân để dùng máy tính."), ("Giao dịch mua", "Gói Lifetime được Apple xử lý qua App Store. Apple quản lý thông tin thanh toán. Salon Booth Math chỉ dùng StoreKit để xác định Lifetime đã được mở khóa hay chưa."), ("Hỗ trợ", "Nếu bạn liên hệ hỗ trợ, chúng tôi chỉ nhận thông tin bạn chủ động gửi để có thể phản hồi."), ("Quyền kiểm soát", "Bạn có thể xóa dữ liệu lưu cục bộ bằng cách xóa ứng dụng khỏi thiết bị."), ("Liên hệ", "Câu hỏi về quyền riêng tư có thể gửi đến support@everittventures.com. Salon Booth Math do Everitt Ventures LLC cung cấp.")])
    }
}

private func termsContent(_ language: AppLanguage) -> (title: String, sections: [(String, String)]) {
    switch language {
    case .english: return ("Terms of Use", [("Purpose", "Salon Booth Math is a calculation and record-keeping tool for salon professionals. It provides estimates based on the information and settings you enter."), ("No professional advice", "Results, including take-home amounts and tax reserve estimates, are informational only and are not tax, accounting, financial, employment, or legal advice."), ("Your inputs", "You are responsible for checking your booth rent, commission or hybrid terms, card fees, tips, expenses, taxes, and other inputs. Actual earnings and obligations may differ from app estimates."), ("Lifetime Access", "Lifetime Access is a one-time, non-consumable in-app purchase tied to the Apple account used to purchase it. Eligible purchases can be restored through the app."), ("Availability", "We may update the app to improve reliability, compatibility, calculations, or presentation. We do not guarantee that every estimate will match payroll, tax filings, salon statements, or payment processor records."), ("Provider", "Salon Booth Math is provided by Everitt Ventures LLC. Questions may be sent to support@everittventures.com.")])
    case .spanish: return ("Términos de uso", [("Propósito", "Salon Booth Math es una herramienta de cálculo y registro para profesionales de salón. Ofrece estimaciones basadas en la información y configuración que ingresas."), ("Sin asesoría profesional", "Los resultados, incluidos los ingresos netos y las reservas estimadas para impuestos, son solo informativos y no constituyen asesoría fiscal, contable, financiera, laboral ni legal."), ("Tus datos", "Eres responsable de verificar renta de puesto, comisión o términos híbridos, cargos de tarjeta, propinas, gastos, impuestos y otros valores. Los ingresos y obligaciones reales pueden ser diferentes."), ("Acceso Lifetime", "Lifetime es una compra única no consumible vinculada a la cuenta Apple utilizada. Las compras elegibles pueden restaurarse desde la app."), ("Disponibilidad", "Podemos actualizar la app para mejorar fiabilidad, compatibilidad, cálculos o presentación. No garantizamos que cada estimación coincida con nómina, impuestos, estados del salón o procesadores de pago."), ("Proveedor", "Salon Booth Math es ofrecida por Everitt Ventures LLC. Puedes enviar preguntas a support@everittventures.com.")])
    case .vietnamese: return ("Điều khoản sử dụng", [("Mục đích", "Salon Booth Math là công cụ tính toán và lưu theo dõi dành cho người làm salon. Ứng dụng đưa ra ước tính dựa trên thông tin và cài đặt bạn nhập."), ("Không phải tư vấn chuyên môn", "Kết quả, gồm tiền còn lại và khoản để dành thuế ước tính, chỉ mang tính thông tin và không phải tư vấn thuế, kế toán, tài chính, lao động hoặc pháp lý."), ("Dữ liệu bạn nhập", "Bạn có trách nhiệm kiểm tra tiền booth, điều khoản hoa hồng hoặc hybrid, phí thẻ, tiền tip, chi phí, thuế và các dữ liệu khác. Thu nhập và nghĩa vụ thực tế có thể khác với ước tính trong ứng dụng."), ("Quyền truy cập Lifetime", "Lifetime là giao dịch mua một lần, không tiêu hao, gắn với tài khoản Apple đã dùng để mua. Giao dịch đủ điều kiện có thể được khôi phục trong ứng dụng."), ("Khả dụng", "Chúng tôi có thể cập nhật ứng dụng để cải thiện độ ổn định, tương thích, phép tính hoặc cách hiển thị. Không bảo đảm mọi ước tính sẽ khớp với bảng lương, hồ sơ thuế, sao kê salon hoặc dữ liệu bộ xử lý thanh toán."), ("Nhà cung cấp", "Salon Booth Math do Everitt Ventures LLC cung cấp. Câu hỏi có thể gửi đến support@everittventures.com.")])
    }
}

private func localized(_ language: AppLanguage, en: String, es: String, vi: String) -> String { switch language { case .english: en; case .spanish: es; case .vietnamese: vi } }
