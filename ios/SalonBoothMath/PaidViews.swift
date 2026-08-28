import SwiftUI

struct BreakdownView: View {
    let grossCents: Int, rentCents: Int, houseCutCents: Int, cardFeesCents: Int, suppliesCents: Int, extraFeesCents: Int, takeHomeCents: Int
    let taxReserveCents: Int
    let payModel: PayModel
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 28) {
            Text("home.breakdown").font(Brand.font(28, weight: .heavy))
            VStack(spacing: 0) {
                row("br.gross", grossCents); if payModel == .booth { row("br.rent", rentCents) }; if payModel == .commission { row("br.houseCut", houseCutCents) }; if cardFeesCents > 0 { row("br.cardFeesEst", cardFeesCents) }; row("br.supplies", suppliesCents); if extraFeesCents > 0 { row("br.extra", extraFeesCents) }; row("br.takeHome", takeHomeCents, strong: true); if taxReserveCents > 0 { row("br.taxReserve", taxReserveCents) }
            }.clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
        }.padding(Brand.screenPadding) }
        .background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).standardNavigationControls()
    }
    private func row(_ key: LocalizedStringKey, _ cents: Int, strong: Bool = false) -> some View {
        HStack { Text(key); Spacer(); Text(formatCurrency(cents)).monospacedDigit() }.font(Brand.font(strong ? 20 : 18, weight: .heavy)).padding(.horizontal, 18).frame(minHeight: 58).background(strong ? Brand.berry : Brand.surface).overlay(alignment: .bottom) { Rectangle().fill(Brand.line).frame(height: 1) }
    }
}

struct CompareView: View {
    let boothCents: Int, commissionCents: Int, commissionPercent: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("compare.title").font(Brand.font(28, weight: .heavy))
            comparison(label: String(localized: "compare.onBooth"), amount: boothCents, winner: boothCents >= commissionCents)
            comparison(label: String(format: String(localized: "compare.onCommission"), "\(commissionPercent)%"), amount: commissionCents, winner: commissionCents > boothCents)
            Text("compare.note").font(Brand.font(18)).foregroundStyle(Brand.mutedInk); Spacer()
        }.padding(Brand.screenPadding).background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).standardNavigationControls()
    }
    private func comparison(label: String, amount: Int, winner: Bool) -> some View {
        HStack { VStack(alignment: .leading, spacing: 6) { Text(label).font(Brand.font(18)); Text(formatCurrency(amount)).font(Brand.font(42, weight: .heavy)).monospacedDigit() }; Spacer(); if winner { Image(systemName: "checkmark.circle.fill").font(.system(size: 34, weight: .bold)).foregroundStyle(Brand.hotPink).accessibilityLabel(Text("a11y.selected")) } }.padding(20).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(winner ? Brand.hotPink : Brand.line, lineWidth: winner ? 3 : 2))
    }
}

struct HistoryView: View {
    @ObservedObject var store: WeekStore
    let onSelect: (WeekRecord) -> Void
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 22) {
            Text("history.title").font(Brand.font(28, weight: .heavy))
            ForEach(store.weeks.prefix(12)) { week in Button { onSelect(week) } label: {
                HStack { Text(weekRange(week.weekStart)).font(Brand.font(18)); Spacer(); Text(formatCurrency(week.takeHomeCents)).font(Brand.font(22, weight: .heavy)).monospacedDigit() }.foregroundStyle(Brand.ink).padding(.horizontal, 18).frame(minHeight: 68).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
            }.buttonStyle(.plain) }
        }.padding(Brand.screenPadding) }.background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).standardNavigationControls()
    }
    private func weekRange(_ start: Date) -> String { let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start; return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day()))" }
}

func formatCurrency(_ cents: Int) -> String { let amount = Decimal(cents) / 100; return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2))) }
func inputCurrencyCents(_ cents: Int) -> String { NSDecimalNumber(decimal: Decimal(cents) / 100).stringValue }
