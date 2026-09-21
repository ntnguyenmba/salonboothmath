import SwiftUI

struct DecisionsView: View {
    let servicesCents: Int
    let cashTipsCents: Int
    let cardTipsCents: Int
    let suppliesCents: Int
    let weeklyRentCents: Int
    let commissionCut: Decimal
    let tipOwner: TipOwner
    let workerPaysCardFees: Bool
    let extraFeesCents: Int
    let cardFeeRate: Decimal
    let servicesOnCardRate: Decimal

    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @State private var targetText = ""

    private var targetCents: Int { MoneyMath.cents(from: targetText) }

    private var requiredServices: Int {
        guard targetCents > 0 else { return 0 }
        return MoneyMath.requiredServicesBooth(
            targetTakeHome: targetCents,
            cashTips: cashTipsCents,
            cardTips: cardTipsCents,
            weeklyRent: weeklyRentCents,
            supplies: suppliesCents,
            extraFees: extraFeesCents,
            cardFeeRate: cardFeeRate,
            percentServicesOnCard: servicesOnCardRate
        )
    }

    private var maxRent: Int {
        MoneyMath.maxRentToBeatCommission(
            services: servicesCents,
            cashTips: cashTipsCents,
            cardTips: cardTipsCents,
            supplies: suppliesCents,
            cut: commissionCut,
            tipOwner: tipOwner,
            workerPaysCardFees: workerPaysCardFees,
            extraFees: extraFeesCents,
            cardFeeRate: cardFeeRate,
            percentServicesOnCard: servicesOnCardRate
        )
    }

    private var breakEvenCutBP: Int {
        MoneyMath.breakEvenCutBasisPoints(
            services: servicesCents,
            cashTips: cashTipsCents,
            cardTips: cardTipsCents,
            supplies: suppliesCents,
            weeklyRent: weeklyRentCents,
            tipOwner: tipOwner,
            workerPaysCardFees: workerPaysCardFees,
            extraFees: extraFeesCents,
            cardFeeRate: cardFeeRate,
            percentServicesOnCard: servicesOnCardRate
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(L("decisions.title", table: "Hybrid", language: appLanguage))
                    .font(Brand.font(28, weight: .heavy))
                Text(L("decisions.subtitle", table: "Hybrid", language: appLanguage))
                    .font(Brand.font(17))
                    .foregroundStyle(Brand.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                card {
                    Text(L("decisions.needSalesTitle", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(18, weight: .heavy))
                    Text(L("decisions.needSalesHint", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.mutedInk)
                    HStack(spacing: 8) {
                        Text(appCurrencySymbol(appLanguage))
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                    }
                    .font(Brand.font(28, weight: .heavy))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 60)
                    .background(Brand.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                    if targetCents > 0 {
                        resultRow(
                            label: L("decisions.needSalesResult", table: "Hybrid", language: appLanguage),
                            value: formatCurrency(requiredServices, language: appLanguage)
                        )
                    }
                }

                card {
                    Text(L("decisions.maxRentTitle", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(18, weight: .heavy))
                    Text(L("decisions.maxRentHint", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.mutedInk)
                    resultRow(
                        label: L("decisions.maxRentResult", table: "Hybrid", language: appLanguage),
                        value: formatCurrency(maxRent, language: appLanguage) + "/" + L("rent.week", language: appLanguage)
                    )
                }

                card {
                    Text(L("decisions.breakEvenCutTitle", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(18, weight: .heavy))
                    Text(L("decisions.breakEvenCutHint", table: "Hybrid", language: appLanguage))
                        .font(Brand.font(16))
                        .foregroundStyle(Brand.mutedInk)
                    resultRow(
                        label: L("decisions.breakEvenCutResult", table: "Hybrid", language: appLanguage),
                        value: "\(breakEvenCutBP / 100)%"
                    )
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .standardNavigationControls()
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
    }

    private func resultRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
            Text(value)
                .font(Brand.font(32, weight: .heavy))
                .foregroundStyle(Brand.hotPink)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(.top, 4)
    }
}
