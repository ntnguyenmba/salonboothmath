import SwiftUI
import UIKit

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

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
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()
    @StateObject private var freeAccess = FreeAccessState()
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
    @State private var showDecisions = false
    @State private var showSettings = false
    @State private var showAddToday = false
    @State private var addedTodayGross: Int?
    @State private var sharePayload: SharePayload?
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, compare, history, decisions }
    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var didUseFreeSave: Bool { freeAccess.used(.save) }
    private var didUseFreeHistory: Bool { freeAccess.used(.history) }
    private var didUseFreeCompare: Bool { freeAccess.used(.compare) }
    private var didUseFreePayCheckup: Bool { freeAccess.used(.payCheckup) }
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
    private var takeHomeCents: Int {
        switch payModel {
        case .booth: return boothTakeHome
        case .commission: return commissionTakeHome
        case .hybrid: return hybridTakeHome
        }
    }
    private var hoursValue: Decimal? {
        guard let v = Decimal(string: hours.replacingOccurrences(of: ",", with: ".")), v > 0 else { return nil }
        return v
    }
    private var isCurrentWeek: Bool { editingWeekStart == nil }
    private var activeWeekStart: Date { editingWeekStart ?? Calendar.current.startOfWeek(for: Date()) }

    private var payContext: String {
        switch payModel {
        case .booth:
            return L("br.rent", language: appLanguage) + " · " + formatCurrency(weeklyRentCents, language: appLanguage) + "/" + L("rent.week", language: appLanguage)
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
                    if !purchases.isUnlocked {
                        FreeBannerAdView()
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Brand.page)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showBreakdown) {
                BreakdownView(grossCents: grossCents, rentCents: weeklyRentCents, yourShareCents: MoneyMath.servicePay(services: serviceCents, cut: commissionCut), houseCutCents: MoneyMath.houseCut(services: serviceCents, workerCut: commissionCut), yourTipsCents: MoneyMath.workerTips(cashTips: cashTipCents, cardTips: cardTipCents, tipOwner: tipOwner), houseTipsCents: MoneyMath.houseTips(cashTips: cashTipCents, cardTips: cardTipCents, tipOwner: tipOwner), cardFeesCents: estimatedCardFees, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, takeHomeCents: takeHomeCents, taxReserveCents: MoneyMath.taxReserve(takeHomeCents: takeHomeCents, rate: taxRate), payModel: payModel, hoursText: $hours)
            }
            .navigationDestination(isPresented: $showCompare) {
                CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, hybridCents: hybridTakeHome)
            }
            .navigationDestination(isPresented: $showHistory) {
                HistoryView(store: weekStore) { week in load(week); showHistory = false }
            }
            .navigationDestination(isPresented: $showDecisions) {
                DecisionsView(
                    servicesCents: serviceCents,
                    cashTipsCents: cashTipCents,
                    cardTipsCents: cardTipCents,
                    suppliesCents: supplyCents,
                    weeklyRentCents: weeklyRentCents,
                    commissionCut: commissionCut,
                    tipOwner: tipOwner,
                    workerPaysCardFees: workerPaysCardFees,
                    extraFeesCents: extraFeesCents,
                    cardFeeRate: cardFeeRate,
                    servicesOnCardRate: servicesOnCardRate,
                    isUnlocked: purchases.isUnlocked,
                    onRequestUnlock: {
                        pendingAction = .decisions
                        showPaywall = true
                    }
                )
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
        .sheet(isPresented: $showAddToday) {
            AddTodaySheet { addToday($0) }
                .environment(\.locale, language.locale)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchases: purchases, takeHomeCents: takeHomeCents) { unlocked in
                showPaywall = false
                if unlocked { runPendingAction() }
            }
            .environment(\.locale, language.locale)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareView(items: payload.items)
                .ignoresSafeArea()
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
            Button { showSettings = true } label: {
                VStack(spacing: 3) {
                    Text(isCurrentWeek ? L("home.thisWeek", language: appLanguage) : formatWeekRange(activeWeekStart, language: appLanguage))
                        .font(Brand.font(19))
                    Text(payContext)
                        .font(Brand.font(16))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            HStack {
                if !isCurrentWeek {
                    Button { returnToCurrentWeek() } label: {
                        Image(systemName: "chevron.left").frame(width: 48, height: 48)
                    }
                } else {
                    Menu {
                        Picker(language.languageTitle, selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang.rawValue)
                            }
                        }
                        Divider()
                        Button(L("settings.startOver", language: appLanguage)) {
                            didCompleteOnboarding = false
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "globe")
                            Text(appLanguage.uppercased())
                                .font(Brand.font(13, weight: .heavy))
                        }
                        .frame(minWidth: 54, minHeight: 48)
                    }
                    .accessibilityLabel(language.languageTitle)
                }
                Spacer()
                Menu {
                    Button(L("home.share", language: appLanguage)) { shareCurrentWeek() }
                    Button(L("history.title", language: appLanguage)) { openHistory() }
                    Button(L("decisions.title", table: "Hybrid", language: appLanguage)) { openPayCheckup() }
                    Button(L("compare.title", language: appLanguage)) { openCompare() }
                    Button(L("settings.title", language: appLanguage)) { showSettings = true }
                    Divider()
                    Button(L("settings.startOver", language: appLanguage)) { didCompleteOnboarding = false }
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
            Text(L("home.takeHome", table: "Hybrid", language: appLanguage))
                .font(Brand.font(16))
                .foregroundStyle(Brand.mutedInk)
            Text(formatCurrency(takeHomeCents, language: appLanguage))
                .font(Brand.font(48, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let added = addedTodayGross {
                Text(String(format: L("home.addedToday", table: "Hybrid", language: appLanguage), formatCurrency(added, language: appLanguage)))
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.mutedInk)
            }
        }
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
            Button { saveWithFreeTry() } label: {
                VStack(spacing: 4) {
                    Text(L("home.save", language: appLanguage))
                        .font(Brand.font(20, weight: .heavy))
                    if !purchases.isUnlocked {
                        Text(L(didUseFreeSave ? "free.used" : "free.trySave", language: appLanguage))
                            .font(Brand.font(16))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 68)
                .background(Brand.hotPink)
                .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            }
            .buttonStyle(.plain)
            Button { showBreakdown = true } label: {
                Text(L("home.breakdown", language: appLanguage))
                    .font(Brand.font(18, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
            }
            Button { openCompare() } label: {
                VStack(spacing: 4) {
                    Text(L("compare.title", language: appLanguage))
                        .font(Brand.font(18, weight: .heavy))
                    if !purchases.isUnlocked {
                        Text(L(didUseFreeCompare ? "free.used" : "free.tryCompare", language: appLanguage))
                            .font(Brand.font(14))
                            .foregroundStyle(Brand.hotPink)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
            }
            if !purchases.isUnlocked {
                Button { openPayCheckup() } label: {
                    VStack(spacing: 4) {
                        Text(L("decisions.title", table: "Hybrid", language: appLanguage))
                            .font(Brand.font(18, weight: .heavy))
                        Text(L(didUseFreePayCheckup ? "free.used" : "free.tryPayCheckup", language: appLanguage))
                            .font(Brand.font(14))
                            .foregroundStyle(Brand.hotPink)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 64)
                }
            }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private func addToday(_ line: DayLine) {
        services = inputCurrencyCents(serviceCents + line.servicesCents)
        cashTips = inputCurrencyCents(cashTipCents + line.cashTipsCents)
        cardTips = inputCurrencyCents(cardTipCents + line.cardTipsCents)
        supplies = inputCurrencyCents(supplyCents + line.suppliesCents)
        if let h = line.hours {
            let total = (hoursValue.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0) + h
            hours = total.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(total)) : String(total)
        }
        days.append(line)
        addedTodayGross = line.servicesCents + line.cashTipsCents + line.cardTipsCents
    }

    private func load(_ week: WeekRecord) {
        editingWeekStart = week.weekStart
        services = inputCurrencyCents(week.servicesCents)
        cashTips = inputCurrencyCents(week.cashTipsCents)
        cardTips = inputCurrencyCents(week.cardTipsCents)
        supplies = inputCurrencyCents(week.suppliesCents)
        if let h = week.hours {
            hours = h.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(h)) : String(h)
        } else { hours = "" }
        days = week.days
        savedPayModel = week.payModel.rawValue
    }

    private func returnToCurrentWeek() {
        editingWeekStart = nil
        restoreCurrentWeekDraft()
    }

    private func restoreCurrentWeekDraft() {
        services = currentWeekServices; cashTips = currentWeekCashTips; cardTips = currentWeekCardTips; supplies = currentWeekSupplies; hours = currentWeekHours
        if let data = currentWeekDaysJSON.data(using: .utf8), let decoded = try? JSONDecoder().decode([DayLine].self, from: data) { days = decoded }
    }

    private func persistCurrentWeekDraft() {
        guard isCurrentWeek else { return }
        currentWeekServices = services; currentWeekCashTips = cashTips; currentWeekCardTips = cardTips; currentWeekSupplies = supplies; currentWeekHours = hours
        if let data = try? JSONEncoder().encode(days), let s = String(data: data, encoding: .utf8) { currentWeekDaysJSON = s }
        currentWeekDraftStart = activeWeekStart.timeIntervalSince1970
    }

    private func shareCurrentWeek() {
        if let image = ShareCardRenderer.image(takeHomeCents: takeHomeCents, weekStart: activeWeekStart) {
            sharePayload = SharePayload(items: [image])
        }
    }

    private func requireUnlock(_ action: LockedAction) {
        if purchases.isUnlocked { pendingAction = action; runPendingAction() }
        else { pendingAction = action; showPaywall = true }
    }

    private func saveWithFreeTry() {
        if freeAccess.claim(.save, isUnlocked: purchases.isUnlocked) {
            pendingAction = .save
            runPendingAction()
        } else {
            requireUnlock(.save)
        }
    }

    private func openHistory() {
        if freeAccess.claim(.history, isUnlocked: purchases.isUnlocked) {
            showHistory = true
        } else {
            requireUnlock(.history)
        }
    }

    private func openCompare() {
        if freeAccess.claim(.compare, isUnlocked: purchases.isUnlocked) {
            showCompare = true
        } else {
            requireUnlock(.compare)
        }
    }

    private func openPayCheckup() {
        if freeAccess.claim(.payCheckup, isUnlocked: purchases.isUnlocked) {
            showDecisions = true
        } else {
            requireUnlock(.decisions)
        }
    }

    private func runPendingAction() {
        guard let action = pendingAction else { return }
        switch action {
        case .save:
            weekStore.save(WeekRecord(weekStart: activeWeekStart, servicesCents: serviceCents, cashTipsCents: cashTipCents, cardTipsCents: cardTipCents, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, hours: hoursValue.map { NSDecimalNumber(decimal: $0).doubleValue }, payModel: payModel, takeHomeCents: takeHomeCents, days: days))
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        case .compare: showCompare = true
        case .history: showHistory = true
        case .decisions: showDecisions = true
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
            .frame(minHeight: 60)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line, lineWidth: focused ? 2.5 : 1.5))
        }
    }
}

struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
