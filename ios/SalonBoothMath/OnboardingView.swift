import SwiftUI

struct OnboardingView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @AppStorage("trade") private var savedTrade = Trade.nail.rawValue
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var savedRentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var savedCommissionCut = 0.55

    @State private var step = 0
    @State private var trade: Trade = .nail
    @State private var payModel: PayModel = .booth
    @State private var rent = "250"
    @State private var rentPeriod: RentPeriod = .week
    @State private var commission = "55"

    var body: some View {
        ZStack {
            Brand.page.ignoresSafeArea()
            VStack(spacing: 0) {
                progress.padding(.horizontal, Brand.screenPadding).padding(.top, 18)
                Group {
                    switch step {
                    case 0: tradeStep
                    case 1: payStep
                    case 2: moneyStep
                    default: doneStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Brand.ink)
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Capsule().fill(index <= step ? Brand.berry : Brand.line).frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private var tradeStep: some View {
        ChoiceStep(title: String(localized: "onboarding.trade.title")) {
            ForEach(Trade.allCases) { item in
                ChoiceButton(title: String(localized: String.LocalizationValue(item.titleKey)), symbol: symbol(for: item), selected: trade == item) {
                    trade = item
                    withAnimation(.snappy(duration: 0.2)) { step = 1 }
                }
            }
        }
    }

    private var payStep: some View {
        ChoiceStep(title: String(localized: "onboarding.pay.title")) {
            ChoiceButton(title: String(localized: "pay.booth"), symbol: "chair.lounge.fill", selected: payModel == .booth) {
                payModel = .booth
                withAnimation(.snappy(duration: 0.2)) { step = 2 }
            }
            ChoiceButton(title: String(localized: "pay.commission"), symbol: "percent", selected: payModel == .commission) {
                payModel = .commission
                withAnimation(.snappy(duration: 0.2)) { step = 2 }
            }
        }
    }

    private var moneyStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text(payModel == .booth ? String(localized: "rent.weekly") : String(localized: "commission.cut"))
                .font(Brand.font(28, weight: .heavy))
            if payModel == .booth {
                MoneyEntryField(text: $rent, prefix: "$", suffix: nil)
                Picker("", selection: $rentPeriod) {
                    Text("rent.week").tag(RentPeriod.week)
                    Text("rent.month").tag(RentPeriod.month)
                }
                .pickerStyle(.segmented)
                .frame(height: 56)
                Text("rent.orMonthly").font(Brand.font(18, weight: .bold)).foregroundStyle(Brand.berry)
            } else {
                MoneyEntryField(text: $commission, prefix: nil, suffix: "%")
                HStack(spacing: 10) {
                    ForEach([50, 55, 60], id: \.self) { value in
                        Button("\(value)%") { commission = "\(value)" }
                            .font(Brand.font(18, weight: .bold))
                            .foregroundStyle(commission == "\(value)" ? Color.white : Brand.ink)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(commission == "\(value)" ? Brand.berry : Brand.ink.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(commission == "\(value)" ? Brand.hotPink : Brand.ink.opacity(0.35), lineWidth: 2))
                    }
                }
            }
            Spacer()
            PrimaryButton(title: String(localized: "onboarding.cta")) {
                saveDefaults()
                withAnimation(.snappy(duration: 0.2)) { step = 3 }
            }
        }
        .padding(Brand.screenPadding)
    }

    private var doneStep: some View {
        ZStack {
            Brand.berry.ignoresSafeArea()
            VStack(spacing: 30) {
                Spacer()
                Text("onboarding.done").font(Brand.font(36, weight: .heavy)).foregroundStyle(.white).multilineTextAlignment(.center)
                Spacer()
                PrimaryButton(title: String(localized: "onboarding.cta")) { didCompleteOnboarding = true }
            }
            .padding(Brand.screenPadding)
        }
    }

    private func saveDefaults() {
        savedTrade = trade.rawValue
        savedPayModel = payModel.rawValue
        if payModel == .booth {
            savedRentCents = MoneyMath.cents(from: rent)
            savedRentPeriod = rentPeriod.rawValue
        } else {
            savedCommissionCut = (Double(commission) ?? 55) / 100
        }
    }

    private func symbol(for trade: Trade) -> String {
        switch trade {
        case .nail: "hand.raised.fill"
        case .hair: "scissors"
        case .barber: "scissors"
        case .esthetician: "sparkles"
        }
    }
}

private struct ChoiceStep<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text(title).font(Brand.font(32, weight: .heavy))
            VStack(spacing: 16) { content }
            Spacer()
        }
        .padding(Brand.screenPadding)
    }
}

struct ChoiceButton: View {
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: symbol).font(.system(size: 25, weight: .bold)).frame(width: 34)
                Text(title).font(Brand.font(20, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(selected ? Color.white : Brand.ink)
            .padding(.horizontal, 20)
            .frame(minHeight: 68)
            .background(selected ? Brand.berry : Brand.ink.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay { RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(selected ? Brand.hotPink : Brand.ink.opacity(0.35), lineWidth: selected ? 3 : 2) }
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Brand.font(20, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: Brand.controlHeight)
                .background(Brand.hotPink)
                .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        }
        .buttonStyle(.plain)
    }
}

struct MoneyEntryField: View {
    @Binding var text: String
    let prefix: String?
    let suffix: String?
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 8) {
            if let prefix { Text(prefix) }
            TextField("0", text: $text).keyboardType(.decimalPad).multilineTextAlignment(.leading).focused($focused)
            if let suffix { Text(suffix) }
        }
        .font(Brand.font(32, weight: .heavy))
        .foregroundStyle(Brand.ink)
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
        .background(Brand.ink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.ink.opacity(0.42), lineWidth: focused ? 3 : 2))
    }
}
