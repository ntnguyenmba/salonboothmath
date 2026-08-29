import SwiftUI

struct BreakdownView: View {
    let grossCents: Int, rentCents: Int, houseCutCents: Int, cardFeesCents: Int, suppliesCents: Int, extraFeesCents: Int, takeHomeCents: Int
    let taxReserveCents: Int
    let payModel: PayModel
    @Binding var hoursText: String
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @FocusState private var hoursFocused: Bool

    private var hoursLabel: String {
        switch AppLanguage.current(appLanguage) {
        case .english: "Hours this week (optional)"
        case .spanish: "Horas esta semana (opcional)"
        case .vietnamese: "Số giờ tuần này (không bắt buộc)"
        }
    }

    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 28) {
            Text("home.breakdown").font(Brand.font(28, weight: .heavy))
            VStack(spacing: 0) {
                row("br.gross", grossCents); if payModel == .booth { row("br.rent", rentCents) }; if payModel == .commission { row("br.houseCut", houseCutCents) }; if cardFeesCents > 0 { row("br.cardFeesEst", cardFeesCents) }; row("br.supplies", suppliesCents); if extraFeesCents > 0 { row("br.extra", extraFeesCents) }; row("br.takeHome", takeHomeCents, strong: true); if taxReserveCents > 0 { row("br.taxReserve", taxReserveCents) }
            }.clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))

            VStack(alignment: .leading, spacing: 10) {
                Text(hoursLabel).font(Brand.font(17))
                TextField("0", text: $hoursText)
                    .keyboardType(.decimalPad)
                    .focused($hoursFocused)
                    .font(Brand.font(24, weight: .heavy))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 58)
                    .background(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                    .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(hoursFocused ? Brand.hotPink : Brand.line, lineWidth: hoursFocused ? 3 : 2))
            }
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
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    private var recentWeeks: [WeekRecord] { Array(store.weeks.prefix(4)) }
    private var fourWeekTotal: Int { recentWeeks.reduce(0) { $0 + $1.takeHomeCents } }
    private var averageWeek: Int { recentWeeks.isEmpty ? 0 : fourWeekTotal / recentWeeks.count }
    private var hourlyWeeks: [WeekRecord] { recentWeeks.filter { ($0.hours ?? 0) > 0 } }
    private var averageHourlyCents: Int? {
        let totalHours = hourlyWeeks.compactMap(\.hours).reduce(0, +)
        guard totalHours > 0 else { return nil }
        let totalTakeHome = hourlyWeeks.reduce(0) { $0 + $1.takeHomeCents }
        return Int((Double(totalTakeHome) / totalHours).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("history.title").font(Brand.font(28, weight: .heavy))
                if !store.weeks.isEmpty { metrics; trend }
                ForEach(store.weeks.prefix(12)) { week in
                    Button { onSelect(week) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(weekRange(week.weekStart)).font(Brand.font(18))
                                if let hours = week.hours, hours > 0 { Text("\(hours.formatted(.number.precision(.fractionLength(0...1)))) \(label(.hours))").font(Brand.font(14)).foregroundStyle(Brand.mutedInk) }
                            }
                            Spacer()
                            Text(formatCurrency(week.takeHomeCents)).font(Brand.font(22, weight: .heavy)).monospacedDigit()
                        }.foregroundStyle(Brand.ink).padding(.horizontal, 18).frame(minHeight: 68).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
                    }.buttonStyle(.plain)
                }
            }.padding(Brand.screenPadding)
        }.background(Brand.page.ignoresSafeArea()).foregroundStyle(Brand.ink).standardNavigationControls()
    }

    private var metrics: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) { metricCard(label: label(.lastFourWeeks), value: formatCurrency(fourWeekTotal)); metricCard(label: label(.averageWeek), value: formatCurrency(averageWeek)) }
            if let averageHourlyCents { metricCard(label: label(.averageHourly), value: "\(formatCurrency(averageHourlyCents))/hr") }
        }
    }

    private func metricCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(label).font(Brand.font(14)).foregroundStyle(Brand.mutedInk); Text(value).font(Brand.font(23, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.75).lineLimit(1) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1.5))
    }

    private var trend: some View {
        VStack(alignment: .leading, spacing: 10) { Text(label(.takeHomeTrend)).font(Brand.font(16)); HistorySparkline(values: Array(recentWeeks.reversed()).map(\.takeHomeCents)).frame(height: 72) }
            .padding(16).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1.5))
    }

    private func weekRange(_ start: Date) -> String { let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start; return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day()))" }
    private enum HistoryLabel { case lastFourWeeks, averageWeek, averageHourly, takeHomeTrend, hours }
    private func label(_ key: HistoryLabel) -> String {
        switch (AppLanguage.current(appLanguage), key) {
        case (.english, .lastFourWeeks): "Last 4 weeks"; case (.english, .averageWeek): "Average week"; case (.english, .averageHourly): "Average hourly"; case (.english, .takeHomeTrend): "Take-home trend"; case (.english, .hours): "hrs"
        case (.spanish, .lastFourWeeks): "Últimas 4 semanas"; case (.spanish, .averageWeek): "Promedio semanal"; case (.spanish, .averageHourly): "Promedio por hora"; case (.spanish, .takeHomeTrend): "Tendencia del neto"; case (.spanish, .hours): "h"
        case (.vietnamese, .lastFourWeeks): "4 tuần gần nhất"; case (.vietnamese, .averageWeek): "Trung bình mỗi tuần"; case (.vietnamese, .averageHourly): "Trung bình mỗi giờ"; case (.vietnamese, .takeHomeTrend): "Xu hướng tiền còn lại"; case (.vietnamese, .hours): "giờ"
        }
    }
}

private struct HistorySparkline: View {
    let values: [Int]
    var body: some View {
        GeometryReader { geometry in
            let usable = values.isEmpty ? [0] : values
            let minValue = usable.min() ?? 0; let maxValue = usable.max() ?? 0; let span = max(maxValue - minValue, 1)
            Path { path in
                for (index, value) in usable.enumerated() {
                    let x = usable.count == 1 ? geometry.size.width / 2 : geometry.size.width * CGFloat(index) / CGFloat(usable.count - 1)
                    let normalized = CGFloat(value - minValue) / CGFloat(span); let y = geometry.size.height - (normalized * (geometry.size.height - 12)) - 6
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }.stroke(Brand.hotPink, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
    }
}

func formatCurrency(_ cents: Int) -> String { let amount = Decimal(cents) / 100; return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2))) }
func inputCurrencyCents(_ cents: Int) -> String { NSDecimalNumber(decimal: Decimal(cents) / 100).stringValue }
