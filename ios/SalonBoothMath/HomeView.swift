import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var savedCommissionCut = 0.55
    @AppStorage("cardFeeRate") private var cardFeeRate = 0.029
    @AppStorage("percentServicesOnCard") private var percentServicesOnCard = 0.70
    @AppStorage("extraFeesCents") private var extraFeesCents = 0
    @AppStorage("workerPaysCardFees") private var workerPaysCardFees = false

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()

    @State private var services = ""
    @State private var cashTips = ""
    @State private var cardTips = ""
    @State private var supplies = ""
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
    private var serviceCents: Int { MoneyMath.cents(from: services) }
    private var cashTipCents: Int { MoneyMath.cents(from: cashTips) }
    private var cardTipCents: Int { MoneyMath.cents(from: cardTips) }
    private var supplyCents: Int { MoneyMath.cents(from: supplies) }
    private var weeklyRentCents: Int { MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod) }
    private var grossCents: Int { serviceCents + cashTipCents + cardTipCents }
    private var estimatedCardFees: Int {
        MoneyMath.cardFees(
            services: serviceCents,
            cardTips: cardTipCents,
            cardFeeRate: Decimal(cardFeeRate),
            percentServicesOnCard: Decimal(percentServicesOnCard)
        )
    }

    private var boothTakeHome: Int {
        MoneyMath.boothTakeHome(
            services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents,
            weeklyRent: weeklyRentCents, extraFees: extraFeesCents,
            cardFeeRate: Decimal(cardFeeRate), percentServicesOnCard: Decimal(percentServicesOnCard)
        )
    }

    private var commissionTakeHome: Int {
        MoneyMath.commissionTakeHome(
            services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents,
            cut: Decimal(savedCommissionCut), tipOwner: .you,
            workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents,
            cardFeeRate: Decimal(cardFeeRate), percentServicesOnCard: Decimal(percentServicesOnCard)
        )
    }

    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : commissionTakeHome }
    private var currentWeekStart: Date { Calendar.current.startOfWeek(for: Date()) }
    private var highRent: Bool { payModel == .booth && grossCents > 0 && Double(weeklyRentCents) / Double(grossCents) >= 0.40 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.page.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        fields.padding(.top, 30)
                        result.padding(.top, 34)
                        actions.padding(.top, 26).padding(.bottom, 30)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(Brand.ink)
            .navigationDestination(isPresented: $showBreakdown) {
                BreakdownView(
                    grossCents: grossCents,
                    rentCents: weeklyRentCents,
                    houseCutCents: max(0, serviceCents - Int(Double(serviceCents) * savedCommissionCut)),
                    cardFeesCents: payModel == .booth || workerPaysCardFees ? estimatedCardFees : 0,
                    suppliesCents: supplyCents,
                    extraFeesCents: extraFeesCents,
                    takeHomeCents: takeHomeCents,
                    hours: nil,
                    payModel: payModel
                )
            }
            .navigationDestination(isPresented: $showCompare) {
                CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, commissionPercent: Int(savedCommissionCut * 100))
            }
            .navigationDestination(isPresented: $showHistory) { HistoryView(store: weekStore) }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
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
                ActivityShareView(items: [shareImage, formatCurrency(takeHomeCents), currentWeekStart.formatted(date: .abbreviated, time: .omitted)])
            }
        }
        .onAppear { WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents) }
        .onChange(of: takeHomeCents) { _, newValue in WidgetBridge.updateCurrentWeek(takeHomeCents: newValue) }
    }

    private var header: some View {
        ZStack {
            Text("home.thisWeek").font(Brand.font(20, weight: .heavy))
            HStack {
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(Text("settings.title"))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 12)
        .background(Brand.berry)
    }

    private var fields: some View {
        VStack(spacing: 22) {
            HomeMoneyField(title: String(localized: "field.services"), text: $services)
            HStack(alignment: .top, spacing: 12) {
                HomeMoneyField(title: "Cash tips", text: $cashTips)
                HomeMoneyField(title: "Card tips", text: $cardTips)
            }
            HomeMoneyField(title: String(localized: "field.supplies"), text: $supplies)
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private var result: some View {
        VStack(spacing: 10) {
            Text("home.youTookHome").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry)
            Text(formatCurrency(takeHomeCents))
                .font(Brand.font(60, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.62).lineLimit(1)
                .contentTransition(.numericText(value: Double(takeHomeCents))).animation(.spring(duration: 0.2), value: takeHomeCents)
            if highRent {
                Text("Booth rent is 40% or more of this week’s gross.")
                    .font(Brand.font(16, weight: .heavy))
                    .foregroundStyle(Brand.warning)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity).padding(.horizontal, Brand.screenPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(format: String(localized: "a11y.takeHome %@"), formatCurrency(takeHomeCents))))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button { showBreakdown = true } label: {
                Text("home.breakdown").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 52)
            }
            HStack(spacing: 12) {
                SecondaryAction(title: String(localized: "home.share"), symbol: "square.and.arrow.up") { shareCurrentWeek() }
                SecondaryAction(title: String(localized: "compare.short"), symbol: "arrow.left.arrow.right") { requireUnlock(.compare) }
                SecondaryAction(title: String(localized: "history.short"), symbol: "clock") { requireUnlock(.history) }
            }
            PrimaryButton(title: String(localized: "home.save")) { requireUnlock(.save) }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private func shareCurrentWeek() {
        shareImage = ShareCardRenderer.image(takeHomeCents: takeHomeCents, weekStart: currentWeekStart)
        showShare = shareImage != nil
    }

    private func requireUnlock(_ action: LockedAction) {
        pendingAction = action
        if purchases.isUnlocked { runPendingAction() } else { showPaywall = true }
    }

    private func runPendingAction() {
        guard let action = pendingAction else { return }
        switch action {
        case .save:
            weekStore.save(WeekRecord(
                weekStart: currentWeekStart, servicesCents: serviceCents,
                cashTipsCents: cashTipCents, cardTipsCents: cardTipCents, suppliesCents: supplyCents,
                extraFeesCents: extraFeesCents, payModel: payModel, takeHomeCents: takeHomeCents
            ))
            WidgetBridge.updateCurrentWeek(takeHomeCents: takeHomeCents)
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Brand.font(18, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.8)
            HStack(spacing: 8) {
                Text(Locale.current.currencySymbol ?? "$")
                TextField("0", text: $text).keyboardType(.decimalPad).focused($focused)
            }
            .font(Brand.font(29, weight: .heavy)).padding(.horizontal, 16).frame(minHeight: 64).background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line, lineWidth: focused ? 3 : 2))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SecondaryAction: View {
    let title: String
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 22, weight: .bold))
                Text(title).font(Brand.font(16, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.75)
            }
            .foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 72)
            .background(.white).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

struct PaywallView: View {
    @ObservedObject var purchases: PurchaseManager
    let completion: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule().fill(Brand.hotPink).frame(width: 54, height: 6)
            Text("paywall.title").font(Brand.font(28, weight: .heavy))
            Text("paywall.body").font(Brand.font(18, weight: .bold)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            PrimaryButton(title: purchases.product?.displayPrice.map { String(format: String(localized: "paywall.unlockPrice"), $0) } ?? String(localized: "paywall.cta")) {
                Task { completion(await purchases.purchase()) }
            }
            Button { Task { await purchases.restore(); if purchases.isUnlocked { completion(true) } } } label: {
                Text("paywall.restore").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 50)
            }
            Button { completion(false) } label: {
                Text("paywall.later").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.ink).frame(maxWidth: .infinity, minHeight: 50)
            }
        }
        .padding(Brand.screenPadding).background(.white)
    }
}
