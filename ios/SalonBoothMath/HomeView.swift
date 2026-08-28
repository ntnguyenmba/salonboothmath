import SwiftUI

struct HomeView: View {
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCut") private var savedCommissionCut = 0.55

    @State private var services = "1240"
    @State private var tips = "160"
    @State private var supplies = "45"
    @State private var showPaywall = false

    private var payModel: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var rentPeriod: RentPeriod { RentPeriod(rawValue: savedRentPeriod) ?? .week }

    private var takeHomeCents: Int {
        let serviceCents = MoneyMath.cents(from: services)
        let tipCents = MoneyMath.cents(from: tips)
        let supplyCents = MoneyMath.cents(from: supplies)

        if payModel == .booth {
            return MoneyMath.boothTakeHome(
                services: serviceCents,
                cashTips: 0,
                cardTips: tipCents,
                supplies: supplyCents,
                weeklyRent: MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod)
            )
        }

        return MoneyMath.commissionTakeHome(
            services: serviceCents,
            cashTips: 0,
            cardTips: tipCents,
            supplies: supplyCents,
            cut: Decimal(savedCommissionCut),
            tipOwner: .you
        )
    }

    var body: some View {
        ZStack {
            Brand.page.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    fields
                        .padding(.top, 30)
                    result
                        .padding(.top, 36)
                    actions
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(Brand.ink)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button { showPaywall = true } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .heavy))
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel(Text("a11y.prevWeek"))

            Spacer()
            Text("home.thisWeek")
                .font(Brand.font(20, weight: .heavy))
            Spacer()

            Button { showPaywall = true } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .heavy))
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel(Text("a11y.nextWeek"))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
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
            Text("home.youTookHome")
                .font(Brand.font(18, weight: .heavy))
                .foregroundStyle(Brand.berry)
            Text(currency(takeHomeCents))
                .font(Brand.font(60, weight: .heavy))
                .monospacedDigit()
                .minimumScaleFactor(0.62)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(takeHomeCents)))
                .animation(.spring(duration: 0.2), value: takeHomeCents)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Brand.screenPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "a11y.takeHome \(currency(takeHomeCents))")))
    }

    private var actions: some View {
        VStack(spacing: 14) {
            PrimaryButton(title: String(localized: "home.save")) { showPaywall = true }
            Button { showPaywall = true } label: {
                Text("home.breakdown")
                    .font(Brand.font(18, weight: .heavy))
                    .foregroundStyle(Brand.berry)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private func currency(_ cents: Int) -> String {
        let amount = Decimal(cents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
    }
}

private struct HomeMoneyField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Brand.font(20, weight: .heavy))
            HStack(spacing: 8) {
                Text(Locale.current.currencySymbol ?? "$")
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
            }
            .font(Brand.font(31, weight: .heavy))
            .padding(.horizontal, 20)
            .frame(minHeight: 64)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Capsule()
                .fill(Brand.hotPink)
                .frame(width: 54, height: 6)
            Text("paywall.title")
                .font(Brand.font(28, weight: .heavy))
            Text("paywall.body")
                .font(Brand.font(18, weight: .bold))
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 10)
            PrimaryButton(title: String(localized: "paywall.cta")) {
                // StoreKit 2 purchase is wired in the next build chunk.
            }
            Button { dismiss() } label: {
                Text("paywall.later")
                    .font(Brand.font(18, weight: .heavy))
                    .foregroundStyle(Brand.berry)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
        }
        .padding(Brand.screenPadding)
        .background(.white)
    }
}
