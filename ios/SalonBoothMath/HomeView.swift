import SwiftUI

struct HomeView: View {
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var savedCommissionCut = 0.55

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()

    @State private var services = "1240"
    @State private var tips = "160"
    @State private var supplies = "45"
    @State private var showPaywall = false
    @State private var showBreakdown = false
    @State private var showCompare = false
    @State private var showHistory = false
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, breakdown, compare, history }
    private var payModel: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var rentPeriod: RentPeriod { RentPeriod(rawValue: savedRentPeriod) ?? .week }
    private var serviceCents: Int { MoneyMath.cents(from: services) }
    private var tipCents: Int { MoneyMath.cents(from: tips) }
    private var supplyCents: Int { MoneyMath.cents(from: supplies) }
    private var weeklyRentCents: Int { MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod) }
    private var estimatedCardFees: Int { NSDecimalNumber(decimal: (Decimal(tipCents) + Decimal(serviceCents) * 0.70) * 0.029).intValue }
    private var grossCents: Int { serviceCents + tipCents }

    private var boothTakeHome: Int {
        MoneyMath.boothTakeHome(services: serviceCents, cashTips: 0, cardTips: tipCents, supplies: supplyCents, weeklyRent: weeklyRentCents)
    }

    private var commissionTakeHome: Int {
        MoneyMath.commissionTakeHome(services: serviceCents, cashTips: 0, cardTips: tipCents, supplies: supplyCents, cut: Decimal(savedCommissionCut), tipOwner: .you)
    }

    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : commissionTakeHome }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.page.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        fields.padding(.top, 30)
                        result.padding(.top, 36)
                        actions.padding(.top, 30).padding(.bottom, 30)
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
                    cardFeesCents: payModel == .booth ? estimatedCardFees : 0,
                    suppliesCents: supplyCents,
                    extraFeesCents: 0,
                    takeHomeCents: takeHomeCents,
                    hours: nil,
                    payModel: payModel
                )
            }
            .navigationDestination(isPresented: $showCompare) {
                CompareView(boothCents: boothTakeHome, commissionCents: commissionTakeHome, commissionPercent: Int(savedCommissionCut * 100))
            }
            .navigationDestination(isPresented: $showHistory) { HistoryView(store: weekStore) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchases: purchases) { unlocked in
                showPaywall = false
                if unlocked { runPendingAction() }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button { requireUnlock(.history) } label: {
                Image(systemName: "chevron.left").font(.system(size: 22, weight: .heavy)).frame(width: 48, height: 48)
            }
            .accessibilityLabel(Text("a11y.prevWeek"))
            Spacer()
            Text("home.thisWeek").font(Brand.font(20, weight: .heavy))
            Spacer()
            Button { requireUnlock(.history) } label: {
                Image(systemName: "chevron.right").font(.system(size: 22, weight: .heavy)).frame(width: 48, height: 48)
            }
            .accessibilityLabel(Text("a11y.nextWeek"))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 12)
        .background(Brand.berry)
    }

    private var fields: some View {
        VStack(spacing: 22) {
            HomeMoneyField(title: String(localized: "field.services"), text: $services)
            HomeMoneyField(title: String(localized: "field.tips"), text: $tips)
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
        }
        .frame(maxWidth: .infinity).padding(.horizontal, Brand.screenPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "a11y.takeHome \(formatCurrency(takeHomeCents))")))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: String(localized: "home.save")) { requireUnlock(.save) }
            Button { requireUnlock(.breakdown) } label: {
                Text("home.breakdown").font(Brand.font(18, weight: .heavy)).foregroundStyle(Brand.berry).frame(maxWidth: .infinity, minHeight: 52)
            }
            HStack(spacing: 12) {
                SecondaryAction(title: String(localized: "compare.title"), symbol: "arrow.left.arrow.right") { requireUnlock(.compare) }
                SecondaryAction(title: String(localized: "history.title"), symbol: "clock") { requireUnlock(.history) }
            }
        }
        .padding(.horizontal, Brand.screenPadding)
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
                weekStart: Calendar.current.startOfWeek(for: Date()), servicesCents: serviceCents,
                cashTipsCents: 0, cardTipsCents: tipCents, suppliesCents: supplyCents,
                payModel: payModel, takeHomeCents: takeHomeCents
            ))
        case .breakdown: showBreakdown = true
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
            Text(title).font(Brand.font(20, weight: .heavy))
            HStack(spacing: 8) {
                Text(Locale.current.currencySymbol ?? "$")
                TextField("0", text: $text).keyboardType(.decimalPad).focused($focused)
            }
            .font(Brand.font(31, weight: .heavy)).padding(.horizontal, 20).frame(minHeight: 64).background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line, lineWidth: focused ? 3 : 2))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius - 3).stroke(focused ? Brand.ink.opacity(0.55) : .clear, lineWidth: 1).padding(3))
        }
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
                Text(title).font(Brand.font(16, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.8)
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
            PrimaryButton(title: purchases.product?.displayPrice.map { String(localized: "paywall.unlockPrice \($0)") } ?? String(localized: "paywall.cta")) {
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
