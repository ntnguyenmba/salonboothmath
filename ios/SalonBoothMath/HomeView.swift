import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var savedCommissionCut = 0.55
    @AppStorage("tipOwner") private var savedTipOwner = TipOwner.you.rawValue
    @AppStorage("cardFeeRate") private var cardFeeRate = 0.029
    @AppStorage("percentServicesOnCard") private var percentServicesOnCard = 0.70
    @AppStorage("extraFeesCents") private var extraFeesCents = 0
    @AppStorage("workerPaysCardFees") private var workerPaysCardFees = false
    @AppStorage("taxRate") private var taxRate = 0.25
    @AppStorage("hoursThisWeek") private var hoursThisWeek = 0.0

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()
    @State private var services = "", cashTips = "", cardTips = "", supplies = ""
    @State private var editingWeekStart: Date?
    @State private var showPaywall = false, showBreakdown = false, showCompare = false, showHistory = false, showSettings = false, showShare = false
    @State private var shareImage: UIImage?
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, compare, history }
    private var payModel: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var rentPeriod: RentPeriod { RentPeriod(rawValue: savedRentPeriod) ?? .week }
    private var tipOwner: TipOwner { TipOwner(rawValue: savedTipOwner) ?? .you }
    private var serviceCents: Int { MoneyMath.cents(from: services) }, cashTipCents: Int { MoneyMath.cents(from: cashTips) }, cardTipCents: Int { MoneyMath.cents(from: cardTips) }, supplyCents: Int { MoneyMath.cents(from: supplies) }
    private var weeklyRentCents: Int { MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod) }
    private var grossCents: Int { serviceCents + cashTipCents + cardTipCents }
    private var estimatedCardFees: Int { MoneyMath.cardFees(services: serviceCents, cardTips: cardTipCents, cardFeeRate: Decimal(cardFeeRate), percentServicesOnCard: Decimal(percentServicesOnCard)) }
    private var boothTakeHome: Int { MoneyMath.boothTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, weeklyRent: weeklyRentCents, extraFees: extraFeesCents, cardFeeRate: Decimal(cardFeeRate), percentServicesOnCard: Decimal(percentServicesOnCard)) }
    private var commissionTakeHome: Int { MoneyMath.commissionTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, cut: Decimal(savedCommissionCut), tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents, cardFeeRate: Decimal(cardFeeRate), percentServicesOnCard: Decimal(percentServicesOnCard)) }
    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : commissionTakeHome }
    private var currentWeekStart: Date { Calendar.current.startOfWeek(for: Date()) }
    private var activeWeekStart: Date { editingWeekStart ?? currentWeekStart }
    private var isCurrentWeek: Bool { Calendar.current.isDate(activeWeekStart, equalTo: currentWeekStart, toGranularity: .weekOfYear) }
    private var highRent: Bool { payModel == .booth && grossCents > 0 && weeklyRentCents * 100 >= grossCents * 40 }

    var body: some View {
        NavigationStack {
            ZStack { Brand.page.ignoresSafeArea(); ScrollView { VStack(spacing: 0) { header; fields.padding(.top, 28); result.padding(.top, 32); actions.padding(.top, 24).padding(.bottom, 30) } }.scrollDismissesKeyboard(.interactively) }.foregroundStyle(Brand.ink)
            .navigationDestination(isPresented: $showBreakdown) { BreakdownView(grossCents: grossCents, rentCents: weeklyRentCents, houseCutCents: MoneyMath.houseCut(services: serviceCents, workerCut: Decimal(savedCommissionCut)), cardFeesCents: payModel == .booth || workerPaysCardFees ? estimatedCardFees : 0, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, takeHomeCents: takeHomeCents, hours: hoursThisWeek > 0 ? hoursThisWeek : nil, taxReserveCents: MoneyMath.taxReserve(takeHomeCents: takeHomeCents, rate: Decimal(taxRate)), payModel: payModel) }
            .navigationDestination(isPresented: $showCompare) { CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, commissionPercent: Int(savedCommissionCut * 100)) }
            .navigationDestination(isPresented: $showHistory) { HistoryView(store: weekStore) { week in load(week); showHistory = false } }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(purchases: purchases) { unlocked in showPaywall = false; if unlocked { runPendingAction() } }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
        .sheet(isPresented: $showShare) { if let shareImage { ActivityShareView(items: [shareImage, formatCurrency(takeHomeCents), activeWeekStart.formatted(date: .abbreviated, time: .omitted)]) } }
        .onAppear { if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) } }
        .onChange(of: takeHomeCents) { _, newValue in if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: newValue) } }
    }

    private var header: some View { ZStack { Text(isCurrentWeek ? String(localized: "home.thisWeek") : weekRange(activeWeekStart)).font(Brand.font(20, weight: .heavy)); HStack { if !isCurrentWeek { Button { returnToCurrentWeek() } label: { Image(systemName: "chevron.left").frame(width: 48, height: 48) }.accessibilityLabel(Text("history.backCurrent")) }; Spacer(); Button { showSettings = true } label: { Image(systemName: "gearshape.fill").font(.system(size: 20, weight: .bold)).frame(width: 48, height: 48) }.accessibilityLabel(Text("settings.title")) } }.foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 12).background(Brand.berry) }
    private var fields: some View { VStack(spacing: 22) { HomeMoneyField(title: String(localized: "field.services"), text: $services); HomeMoneyField(title: String(localized: "field.cashTips"), text: $cashTips); HomeMoneyField(title: String(localized: "field.cardTips"), text: $cardTips); HomeMoneyField(title: String(localized: "field.supplies"), text: $supplies) }.padding(.horizontal, Brand.screenPadding) }
    private var result: some View { VStack(spacing: 10) { Text("home.youTookHome").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry); Text(formatCurrency(takeHomeCents)).font(Brand.font(52, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.75).lineLimit(1); if highRent { Text("br.rentHighHome").font(Brand.font(16, weight: .heavy)).foregroundStyle(Brand.warning).multilineTextAlignment(.center) } }.frame(maxWidth: .infinity).padding(.horizontal, Brand.screenPadding) }
    private var actions: some View { VStack(spacing: 10) { PrimaryButton(title: String(localized: "home.save")) { requireUnlock(.save) }; Button { showBreakdown = true } label: { Text("home.breakdown").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 52) }; Button { shareCurrentWeek() } label: { Text("home.share").font(Brand.font(17, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 48) }; Button { requireUnlock(.history) } label: { Text("history.short").font(Brand.font(17, weight: .bold)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 48) }; Button { requireUnlock(.compare) } label: { Text("compare.short").font(Brand.font(17, weight: .bold)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 48) } }.padding(.horizontal, Brand.screenPadding) }

    private func load(_ week: WeekRecord) { editingWeekStart = week.weekStart; services = inputCurrencyCents(week.servicesCents); cashTips = inputCurrencyCents(week.cashTipsCents); cardTips = inputCurrencyCents(week.cardTipsCents); supplies = inputCurrencyCents(week.suppliesCents); savedPayModel = week.payModel.rawValue; hoursThisWeek = week.hours ?? 0 }
    private func returnToCurrentWeek() { editingWeekStart = nil; if let week = weekStore.week(for: currentWeekStart) { load(week); editingWeekStart = nil } else { services = ""; cashTips = ""; cardTips = ""; supplies = ""; hoursThisWeek = 0 } }
    private func weekRange(_ start: Date) -> String { let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start; return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day()))" }
    private func shareCurrentWeek() { shareImage = ShareCardRenderer.image(takeHomeCents: takeHomeCents, weekStart: activeWeekStart); showShare = shareImage != nil }
    private func requireUnlock(_ action: LockedAction) { pendingAction = action; if purchases.isUnlocked { runPendingAction() } else { showPaywall = true } }
    private func runPendingAction() { guard let action = pendingAction else { return }; switch action { case .save: weekStore.save(WeekRecord(weekStart: activeWeekStart, servicesCents: serviceCents, cashTipsCents: cashTipCents, cardTipsCents: cardTipCents, suppliesCents: supplyCents, extraFeesCents: extraFeesCents, hours: hoursThisWeek > 0 ? hoursThisWeek : nil, payModel: payModel, takeHomeCents: takeHomeCents)); if isCurrentWeek { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }; case .compare: showCompare = true; case .history: showHistory = true }; pendingAction = nil }
}

private struct HomeMoneyField: View { let title: String; @Binding var text: String; @FocusState private var focused: Bool; var body: some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(Brand.font(18, weight: .heavy)); HStack(spacing: 8) { Text(Locale.current.currencySymbol ?? "$"); TextField("0", text: $text).keyboardType(.decimalPad).focused($focused) }.font(Brand.font(29, weight: .heavy)).padding(.horizontal, 16).frame(minHeight: 64).background(Brand.ink.opacity(0.035)).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.ink.opacity(0.22), lineWidth: focused ? 3 : 2)) }.frame(maxWidth: .infinity) } }

struct PaywallView: View { @ObservedObject var purchases: PurchaseManager; let completion: (Bool) -> Void; var body: some View { VStack(alignment: .leading, spacing: 20) { Capsule().fill(Brand.hotPink).frame(width: 54, height: 6); Text("paywall.title").font(Brand.font(28, weight: .heavy)); Text("paywall.body").font(Brand.font(18, weight: .bold)).fixedSize(horizontal: false, vertical: true); Spacer(minLength: 8); PrimaryButton(title: purchases.product?.displayPrice.map { String(format: String(localized: "paywall.unlockPrice"), $0) } ?? String(localized: "paywall.cta")) { Task { completion(await purchases.purchase()) } }; Button { Task { await purchases.restore(); if purchases.isUnlocked { completion(true) } } } label: { Text("paywall.restore").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 50) }; Button { completion(false) } label: { Text("paywall.later").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.ink).frame(maxWidth: .infinity, minHeight: 50) } }.padding(Brand.screenPadding).background(.white) } }
