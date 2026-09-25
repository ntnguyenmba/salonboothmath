import SwiftUI

struct PaywallView: View {
    @ObservedObject var purchases: PurchaseManager
    let takeHomeCents: Int
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
            Text(L("paywall.lifetimeTitle", table: "Hybrid", language: appLanguage))
                .font(Brand.font(27, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if takeHomeCents > 0 {
                Text(String(format: L("paywall.takeHomeLead", table: "Hybrid", language: appLanguage), formatCurrency(takeHomeCents, language: appLanguage)))
                    .font(Brand.font(18, weight: .heavy))
                    .foregroundStyle(Brand.hotPink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("• " + L("paywall.benefitCompare", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.benefitDifference", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.benefitDecisions", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.benefitTrack", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.benefitHistory", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.benefitNoAds", table: "Hybrid", language: appLanguage))
                Text("• " + L("paywall.once", table: "Hybrid", language: appLanguage))
            }
            .font(Brand.font(17))
            .foregroundStyle(Brand.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
            if purchases.errorMessage != nil {
                Text(L("paywall.purchaseError", language: appLanguage))
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.hotPink)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        .environment(\.locale, AppLanguage.current(appLanguage).locale)
    }
}
