import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCutBasisPoints") private var commissionCutBasisPoints = 5500
    @AppStorage("tipOwner") private var savedTipOwner = TipOwner.you.rawValue
    @AppStorage("cardFeeBasisPoints") private var cardFeeBasisPoints = 290
    @AppStorage("servicesOnCardBasisPoints") private var servicesOnCardBasisPoints = 7000
    @AppStorage("extraFeesCents") private var extraFeesCents = 0
    @AppStorage("workerPaysCardFees") private var workerPaysCardFees = false
    @AppStorage("taxBasisPoints") private var taxBasisPoints = 2500
    @AppStorage("currentWeekDraftStart") private var currentWeekDraftStart = 0.0
    @AppStorage("currentWeekServices") private var currentWeekServices = ""
    @AppStorage("currentWeekCashTips") private var currentWeekCashTips = ""
    @AppStorage("currentWeekCardTips") private var currentWeekCardTips = ""
    @AppStorage("currentWeekSupplies") private var currentWeekSupplies = ""
    @AppStorage("currentWeekHours") private var currentWeekHours = ""
    @AppStorage("currentWeekDaysJSON") private var currentWeekDaysJSON = "[]"
    @AppStorage("didUseFreeCompare") private var didUseFreeCompare = false

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()
    @State private var services = ""
    @State private var cashTips = ""
    @State private var cardTips = ""
    @State private var supplies = ""
    @State private var hours = ""
    @State private var days: [DayLine] = []
    @State private var editingWeekStart: Date?
    @State private var showPaywall = false
    @State private var showBreakdown = false
    @State private var showCompare = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShare = false
    @State private var showAddToday = false
    @State private var addedTodayGross: Int?
    @State private var shareImage: UIImage?
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, compare, history }
    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var payModel: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var rentPeriod: RentPeriod { RentPeriod(rawValue: savedRentPeriod) ?? .week }
    private var tipOwner: TipOwner { TipOwner(rawValue: savedTipOwner) ?? .you }
    private var commissionCut: Decimal { MoneyMath.rate(fromBasisPoints: commissionCutBasisPoints) }
    private var cardFeeRate: Decimal { MoneyMath.rate(fromBasisPoints: cardFeeBasisPoints) }
    private var servicesOnCardRate: Decimal { MoneyMath.rate(fromBasisPoints: servicesOnCardBasisPoints) }
    private var taxRate: Decimal { MoneyMath.rate(fromBasisPoints: taxBasisPoints) }
    private var serviceCents: Int { MoneyMath.cents(from: services) }
    private var cashTipCents: Int { MoneyMath.cents(from: cashTips) }
    private var cardTipCents: Int { MoneyMath.cents(from: cardTips) }
    private var supplyCents: Int { MoneyMath.cents(from: supplies) }
    private var weeklyRentCents: Int { MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod) }
    private var grossCents: Int { serviceCents + cashTipCents + cardTipCents }
    private var estimatedCardFees: Int { MoneyMath.cardFees(services: serviceCents, cardTips: cardTipCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var boothTakeHome: Int { MoneyMath.boothTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, weeklyRent: weeklyRentCents, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var commissionTakeHome: Int { MoneyMath.commissionTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, cut: commissionCut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var hybridTakeHome: Int { MoneyMath.hybridTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, weeklyRent: weeklyRentCents, cut: commissionCut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : (payModel == .commission ? commissionTakeHome : hybridTakeHome) }
    private var currentWeekStart: Date { Calendar.current.startOfWeek(for: Date()) }
    private var activeWeekStart: Date { editingWeekStart ?? currentWeekStart }
    private var isCurrentWeek: Bool { Calendar.current.isDate(activeWeekStart, equalTo: currentWeekStart, toGranularity: .weekOfYear) }
    private var highRentRatio: Decimal? { guard payModel != .commission, grossCents > 0 else { return nil }; return Decimal(weeklyRentCents) / Decimal(grossCents) }
    private var hoursValue: Double? {
        let n = hours.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(n), v > 0 else { return nil }
        return v
    }
    private var lifetimePrice: String { purchases.product?.displayPrice ?? "$9.99" }
    private var payContext: String {
        switch payModel {
        case .booth:
            return "\(L("br.rent", language: appLanguage)) · \(formatCurrency(weeklyRentCents, language: appLanguage))/\(L("rent.week", language: appLanguage))"
        case .commission:
            return String(format: L("home.payContextSplit", table: "Hybrid", language: appLanguage), commissionCutBasisPoints / 100, max(0, 100 - commissionCutBasisPoints / 100))
        case .hybrid:
            return String(format: L("home.hybridContext", table: "Hybrid", language: appLanguage), formatCurrency(weeklyRentCents, language: appLanguage), L("rent.week", language: appLanguage), commissionCutBasisPoints / 100)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.page.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(spacing: 0) {
                            fields.padding(.top, 26)
                            result.padding(.top, 30)
                            actions.padding(.top, 24).padding(.bottom, 32)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .foregroundStyle(Brand.ink)
            .navigationDestination(isPresented: $showBreakdown) {
                BreakdownView(
                    grossCents: grossCents,
                    rentCents: weeklyRentCents,
                    yourShareCents: MoneyMath.servicePay(services: serviceCents, cut: commissionCut),
                    houseCutCents: MoneyMath.houseCut(services: serviceCents, workerCut: commissionCut),
                    yourTipsCents: MoneyMath.workerTips(cashTips: cashTipCents, cardTips: cardTipCents, tipOwner: tipOwner),
                    houseTipsCents: MoneyMath.houseTips(cashTips: cashTipCents, cardTips: cardTipCents, tipOwner: tipOwner),
                    cardFeesCents: payModel == .booth || workerPaysCardFees ? estimatedCardFees : 0,
                    suppliesCents: supplyCents,
                    extraFeesCents: extraFeesCents,
                    takeHomeCents: takeHomeCents,
                    taxReserveCents: MoneyMath.taxReserve(takeHomeCents: takeHomeCents, rate: taxRate),
                    payModel: payModel,
                    hoursText: $hours
                )
            }
            .navigationDestination(isPresented: $showCompare) {
                CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, hybridCents: hybridTakeHome)
            }
            .navigationDestination(isPresented: $showHistory) {
                HistoryView(store: weekStore) { week in
                    load(week)
                    showHistory = false
                }
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
        .sheet(isPresented: $showAddToday) {
            AddTodaySheet { addToday($0) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchases: purchases) { unlocked in
                showPaywall = false
                if unlocked { runPendingAction() }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ActivityShareView(items: [shareImage, formatCurrency(takeHomeCents, language: appLanguage), formatWeekRange(activeWeekStart, language: appLanguage)])
            }
        }
        .onAppear {
            restoreCurrentWeekDraft()
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        }
        .onChange(of: services) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: cashTips) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: cardTips) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: supplies) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: hours) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: days) { _, _ in persistCurrentWeekDraft() }
        .onChange(of: takeHomeCents) { _, value in
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: value) }
        }
        .onChange(of: appLanguage) { _, _ in
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(isCurrentWeek ? L("home.thisWeek", language: appLanguage) : formatWeekRange(activeWeekStart, language: appLanguage))
                    .font(Brand.font(19))
                Text(payContext)
                    .font(Brand.font(16))
                    .foregroundStyle(.white)
            }
            HStack {
                if !isCurrentWeek {
                    Button { returnToCurrentWeek() } label: {
                        Image(systemName: "chevron.left").frame(width: 48, height: 48)
                    }
                }
                Spacer()
                Menu {
                    Picker(language.languageTitle, selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    Divider()
                    if !purchases.isUnlocked {
                        Button(String(format: L("paywall.unlockLifetime", language: appLanguage), lifetimePrice)) {
                            pendingAction = nil
                            showPaywall = true
                        }
                    }
                    Button(L("home.share", language: appLanguage)) { shareCurrentWeek() }
                    Button(L("history.title", language: appLanguage)) { requireUnlock(.history) }
                    Button(L("compare.title", language: appLanguage)) { openCompare() }
                    Button(L("settings.title", language: appLanguage)) { showSettings = true }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 23, weight: .bold))
                        .frame(width: 48, height: 48)
                        .accessibilityLabel(L("nav.menu", language: appLanguage))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(Brand.berry)
        .overlay(alignment: .top) { Rectangle().fill(Brand.hotPink).frame(height: 4) }
    }

    private var fields: some View {
        VStack(spacing: 20) {
            HomeMoneyField(title: L("field.services", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $services)
            HomeMoneyField(title: L("field.tipsCash", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $cashTips)
            HomeMoneyField(title: L("field.tipsCard", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $cardTips)
            HomeMoneyField(title: L("field.supplies", language: appLanguage), currencySymbol: appCurrencySymbol(appLanguage), text: $supplies)
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private var result: some View {
        VStack(spacing: 8) {
            Text(L("home.youTookHome", language: appLanguage))
                .font(Brand.font(17))
                .foregroundStyle(Brand.hotPink)
            Text(formatCurrency(takeHomeCents, language: appLanguage))
                .font(Brand.font(52, weight: .heavy))
                .monospacedDigit()
                .minimumScaleFactor(0.82)
                .lineLimit(1)
            if let ratio = highRentRatio, ratio >= Decimal(string: "0.40")! {
                Text(String(format: L("br.rentHigh", language: appLanguage), NSDecimalNumber(decimal: ratio).doubleValue.formatted(.percent.precision(.fractionLength(0)).locale(language.locale))))
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.warning)
                    .multilineTextAlignment(.center)
            }
            if let addedTodayGross {
                Text(String(format: L("home.addedToday", table: "Hybrid", language: appLanguage), formatCurrency(addedTodayGross, language: appLanguage)))
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.mutedInk)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Brand.screenPadding)
    }

    private var actions: some View {
        VStack(spacing: 14) {
            if isCurrentWeek {
                Button { showAddToday = true } label: {
                    Text(L("home.addToday", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(18, weight: .heavy))
                        .foregroundStyle(Brand.hotPink)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                }
            }
            PrimaryButton(title: L("home.save", language: appLanguage)) { requireUnlock(.save) }
            Button { showBreakdown = true } label: {
                Text(L("home.breakdown", language: appLanguage))
                    .font(Brand.font(18))
                    .foregroundStyle(Brand.ink)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            }
            Button { openCompare() } label: {
                Text(L("compare.title", language: appLanguage))
                    .font(Brand.font(18))
                    .foregroundStyle(Brand.ink)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private func addToday(_ line: DayLine) {
        services = inputCurrencyCents(serviceCents + line.servicesCents)
        cashTips = inputCurrencyCents(cashTipCents + line.cashTipsCents)
        cardTips = inputCurrencyCents(cardTipCents + line.cardTipsCents)
        supplies = inputCurrencyCents(supplyCents + line.suppliesCents)
        if let hoursToday = line.hours {
            let total = (hoursValue ?? 0) + hoursToday
            hours = total.formatted(.number.precision(.fractionLength(0...1)))
        }
        days.append(line)
        addedTodayGross = line.grossCents
        persistCurrentWeekDraft()
        WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents)
    }

    private func restoreCurrentWeekDraft() {
        let start = currentWeekStart.timeIntervalSince1970
        if abs(currentWeekDraftStart - start) > 1 {
            currentWeekDraftStart = start
            currentWeekServices = ""
            currentWeekCashTips = ""
            currentWeekCardTips = ""
            currentWeekSupplies = ""
            currentWeekHours = ""
            currentWeekDaysJSON = "[]"
        }
        guard isCurrentWeek else { return }
        services = currentWeekServices
        cashTips = currentWeekCashTips
        cardTips = currentWeekCardTips
        supplies = currentWeekSupplies
        hours = currentWeekHours
        if let data = currentWeekDaysJSON.data(using: .utf8), let decoded = try? JSONDecoder().decode([DayLine].self, from: data) {
            days = decoded
        } else {
            days = []
        }
    }

    private func persistCurrentWeekDraft() {
        guard isCurrentWeek else { return }
        currentWeekDraftStart = currentWeekStart.timeIntervalSince1970
        currentWeekServices = services
        currentWeekCashTips = cashTips
        currentWeekCardTips = cardTips
        currentWeekSupplies = supplies
        currentWeekHours = hours
        if let data = try? JSONEncoder().encode(days), let json = String(data: data, encoding: .utf8) {
            currentWeekDaysJSON = json
        }
    }

    private func load(_ week: WeekRecord) {
        editingWeekStart = week.weekStart
        services = inputCurrencyCents(week.servicesCents)
        cashTips = inputCurrencyCents(week.cashTipsCents)
        cardTips = inputCurrencyCents(week.cardTipsCents)
        supplies = inputCurrencyCents(week.suppliesCents)
        hours = week.hours.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? ""
        days = week.days
        savedPayModel = week.payModel.rawValue
    }

    private func returnToCurrentWeek() {
        editingWeekStart = nil
        restoreCurrentWeekDraft()
    }

    private func shareCurrentWeek() {
        shareImage = ShareCardRenderer.image(takeHomeCents: takeHomeCents, weekStart: activeWeekStart)
        showShare = shareImage != nil
    }

    private func openCompare() {
        if purchases.isUnlocked || !didUseFreeCompare {
            didUseFreeCompare = true
            showCompare = true
        } else {
            requireUnlock(.compare)
        }
    }

    private func requireUnlock(_ action: LockedAction) {
        pendingAction = action
        if purchases.isUnlocked {
            runPendingAction()
        } else {
            showPaywall = true
        }
    }

    private func runPendingAction() {
        guard let action = pendingAction else { return }
        switch action {
        case .save:
            weekStore.save(WeekRecord(weekStart: activeWeekStart, servicesCents: serviceCents, cashTipsCents: cashTipCents, cardTipsCents: cardTipCents, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, hours: hoursValue, payModel: payModel, takeHomeCents: takeHomeCents, days: days))
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        case .compare:
            showCompare = true
        case .history:
            showHistory = true
        }
        pendingAction = nil
    }
}

private struct HomeMoneyField: View {
    let title: String
    let currencySymbol: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(Brand.font(18)).foregroundStyle(Brand.ink)
            HStack(spacing: 8) {
                Text(currencySymbol)
                TextField("0", text: $text).keyboardType(.decimalPad).focused($focused)
            }
            .font(Brand.font(29, weight: .heavy))
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line, lineWidth: focused ? 3 : 2))
        }
        .frame(maxWidth: .infinity)
    }
}

struct PaywallView: View {
    @ObservedObject var purchases: PurchaseManager
    let completion: (Bool) -> Void
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    private var unlockTitle: String {
        String(format: L("paywall.unlockLifetime", language: appLanguage), purchases.product?.displayPrice ?? "$9.99")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Capsule().fill(Brand.hotPink).frame(width: 54, height: 6)
                Spacer()
                Button(L("paywall.continueFree", language: appLanguage)) { completion(false) }
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.ink)
            }
            Text(L("paywall.lifetimeTitle", language: appLanguage))
                .font(Brand.font(27, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(L("paywall.lifetimeBody", language: appLanguage))
                .font(Brand.font(18))
                .foregroundStyle(Brand.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: unlockTitle) {
                Task {
                    let ok = await purchases.purchase()
                    if ok { completion(true) }
                }
            }
            Button {
                Task {
                    await purchases.restore()
                    if purchases.isUnlocked { completion(true) }
                }
            } label: {
                Text(L("paywall.restore", language: appLanguage))
                    .font(Brand.font(17))
                    .foregroundStyle(Brand.ink)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            Button { completion(false) } label: {
                Text(L("paywall.continueFree", language: appLanguage))
                    .font(Brand.font(17))
                    .foregroundStyle(Brand.muted)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
        }
        .padding(24)
        .background(Brand.page)
        .foregroundStyle(Brand.ink)
    }
}

struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
