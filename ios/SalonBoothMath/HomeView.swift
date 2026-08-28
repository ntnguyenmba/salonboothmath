import SwiftUI
import UIKit

struct HomeView: View {
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

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()

    @State private var services = ""
    @State private var cashTips = ""
    @State private var cardTips = ""
    @State private var supplies = ""
    @State private var editingWeekStart: Date?
    @State private var showPaywall = false
    @State private var showBreakdown = false
    @State private var showCompare = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, compare, history }

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
    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : commissionTakeHome }
    private var currentWeekStart: Date { Calendar.current.startOfWeek(for: Date()) }
    private var activeWeekStart: Date { editingWeekStart ?? currentWeekStart }
    private var isCurrentWeek: Bool { Calendar.current.isDate(activeWeekStart, equalTo: currentWeekStart, toGranularity: .weekOfYear) }
    private var highRentRatio: Decimal? { guard payModel == .booth, grossCents > 0 else { return nil }; return Decimal(weeklyRentCents) / Decimal(grossCents) }
    private var payContext: String {
        if payModel == .booth { return "\(String(localized: "pay.booth")) · \(formatCurrency(weeklyRentCents))/\(String(localized: "rent.week"))" }
        let percent = commissionCutBasisPoints / 100
        return "\(percent)% · \(tipOwner == .you ? String(localized: "tips.you") : tipOwner == .house ? String(localized: "tips.house") : String(localized: "tips.split"))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.page.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        fields.padding(.top, 26)
                        result.padding(.top, 30)
                        actions.padding(.top, 22).padding(.bottom, 32)
                    }
                }.scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(Brand.ink)
            .navigationDestination(isPresented: $showBreakdown) {
                BreakdownView(grossCents: grossCents, rentCents: weeklyRentCents, houseCutCents: MoneyMath.houseCut(services: serviceCents, workerCut: commissionCut), cardFeesCents: payModel == .booth || workerPaysCardFees ? estimatedCardFees : 0, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, takeHomeCents: takeHomeCents, taxReserveCents: MoneyMath.taxReserve(takeHomeCents: takeHomeCents, rate: taxRate), payModel: payModel)
            }
            .navigationDestination(isPresented: $showCompare) { CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, commissionPercent: commissionCutBasisPoints / 100) }
            .navigationDestination(isPresented: $showHistory) { HistoryView(store: weekStore) { week in load(week); showHistory = false } }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(purchases: purchases) { unlocked in showPaywall = false; if unlocked { runPendingAction() } }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
        .sheet(isPresented: $showShare) { if let shareImage { ActivityShareView(items: [shareImage, formatCurrency(takeHomeCents), activeWeekStart.formatted(date: .abbreviated, time: .omitted)]) } }
        .onAppear { if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) } }
        .onChange(of: takeHomeCents) { _, newValue in if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: newValue) } }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 3) {
                Text(isCurrentWeek ? String(localized: "home.thisWeek") : weekRange(activeWeekStart)).font(Brand.font(19, weight: .bold))
                Text(payContext).font(Brand.font(16, weight: .bold)).foregroundStyle(Color.white)
            }
            HStack {
                if !isCurrentWeek { Button { returnToCurrentWeek() } label: { Image(systemName: "chevron.left").frame(width: 48, height: 48) }.accessibilityLabel(Text("home.thisWeek")) }
                Spacer()
                Menu {
                    Button("home.share") { shareCurrentWeek() }
                    Button("history.title") { requireUnlock(.history) }
                    Button("compare.title") { requireUnlock(.compare) }
                    Button("settings.title") { showSettings = true }
                } label: { Image(systemName: "ellipsis.circle.fill").font(.system(size: 23, weight: .bold)).frame(width: 48, height: 48) }.accessibilityLabel(Text("settings.title"))
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(Brand.berry)
        .overlay(alignment: .top) { Rectangle().fill(Brand.hotPink).frame(height: 4) }
    }

    private var fields: some View {
        VStack(spacing: 20) {
            HomeMoneyField(title: String(localized: "field.services"), text: $services)
            HomeMoneyField(title: String(localized: "field.tipsCash"), text: $cashTips)
            HomeMoneyField(title: String(localized: "field.tipsCard"), text: $cardTips)
            HomeMoneyField(title: String(localized: "field.supplies"), text: $supplies)
        }.padding(.horizontal, Brand.screenPadding)
    }

    private var result: some View {
        VStack(spacing: 8) {
            Text("home.youTookHome").font(Brand.font(17, weight: .bold)).foregroundStyle(Brand.berry)
            Text(formatCurrency(takeHomeCents))
                .font(Brand.font(52, weight: .heavy))
                .monospacedDigit()
                .minimumScaleFactor(0.82)
                .lineLimit(1)
                .accessibilityLabel(Text(String(format: String(localized: "a11y.takeHome %@"), formatCurrency(takeHomeCents))))
            if let ratio = highRentRatio, ratio >= Decimal(string: "0.40")! {
                Text(String(format: String(localized: "br.rentHigh"), NSDecimalNumber(decimal: ratio).doubleValue.formatted(.percent.precision(.fractionLength(0))))).font(Brand.font(16, weight: .bold)).foregroundStyle(Brand.warning).multilineTextAlignment(.center)
            }
        }.frame(maxWidth: .infinity).padding(.horizontal, Brand.screenPadding)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            PrimaryButton(title: String(localized: "home.save")) { requireUnlock(.save) }
            Button { showBreakdown = true } label: { Text("home.breakdown").font(Brand.font(18, weight: .bold)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 52) }
        }.padding(.horizontal, Brand.screenPadding)
    }

    private func load(_ week: WeekRecord) {
        editingWeekStart = week.weekStart
        services = inputCurrencyCents(week.servicesCents); cashTips = inputCurrencyCents(week.cashTipsCents); cardTips = inputCurrencyCents(week.cardTipsCents); supplies = inputCurrencyCents(week.suppliesCents)
        savedPayModel = week.payModel.rawValue
    }

    private func returnToCurrentWeek() {
        editingWeekStart = nil
        if let week = weekStore.week(for: currentWeekStart) { load(week); editingWeekStart = nil }
        else { services = ""; cashTips = ""; cardTips = ""; supplies = "" }
    }

    private func weekRange(_ start: Date) -> String { let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start; return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day()))" }
    private func shareCurrentWeek() { shareImage = ShareCardRenderer.image(takeHomeCents: takeHomeCents, weekStart: activeWeekStart); showShare = shareImage != nil }
    private func requireUnlock(_ action: LockedAction) { pendingAction = action; if purchases.isUnlocked { runPendingAction() } else { showPaywall = true } }
    private func runPendingAction() {
        guard let action = pendingAction else { return }
        switch action {
        case .save:
            weekStore.save(WeekRecord(weekStart: activeWeekStart, servicesCents: serviceCents, cashTipsCents: cashTipCents, cardTipsCents: cardTipCents, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, hours: nil, payModel: payModel, takeHomeCents: takeHomeCents))
            if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        case .compare: showCompare = true
        case .history: showHistory = true
        }
        pendingAction = nil
    }
}

private struct HomeMoneyField: View {
    let title: String
    @Binding var text: String
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(Brand.font(18, weight: .bold)).foregroundStyle(Brand.ink)
            HStack(spacing: 8) { Text(Locale.current.currencySymbol ?? "$"); TextField("0", text: $text).keyboardType(.decimalPad).focused($focused) }
                .font(Brand.font(29, weight: .heavy)).padding(.horizontal, 16).frame(minHeight: 64).background(Color.white).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.ink.opacity(0.42), lineWidth: focused ? 3 : 2))
        }.frame(maxWidth: .infinity)
    }
}

struct PaywallView: View {
    @ObservedObject var purchases: PurchaseManager
    let completion: (Bool) -> Void
    private var unlockTitle: String { guard let price = purchases.product?.displayPrice else { return String(localized: "paywall.cta") }; return String(format: String(localized: "paywall.unlockPrice %@"), price) }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule().fill(Brand.hotPink).frame(width: 54, height: 6)
            Text("paywall.title").font(Brand.font(28, weight: .heavy))
            Text("paywall.body").font(Brand.font(18, weight: .bold)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            PrimaryButton(title: unlockTitle) { Task { completion(await purchases.purchase()) } }
            Button { Task { await purchases.restore(); if purchases.isUnlocked { completion(true) } } } label: { Text("paywall.restore").font(Brand.font(18, weight: .bold)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 50) }
            Button { completion(false) } label: { Text("paywall.later").font(Brand.font(18, weight: .bold)).foregroundStyle(Brand.ink).frame(maxWidth: .infinity, minHeight: 50) }
        }.padding(Brand.screenPadding).background(Color.white)
    }
}
