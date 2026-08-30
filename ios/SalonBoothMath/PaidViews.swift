import SwiftUI

struct BreakdownView: View {
    let grossCents: Int, rentCents: Int, houseCutCents: Int, yourShareCents: Int, cardFeesCents: Int, suppliesCents: Int, extraFeesCents: Int, takeHomeCents: Int
    let taxReserveCents: Int
    let payModel: PayModel
    @Binding var hoursText: String
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @FocusState private var hoursFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("home.breakdown").font(Brand.font(28, weight: .heavy))
                VStack(spacing: 0) {
                    row("br.gross", grossCents)
                    if payModel != .commission { row("br.rent", rentCents) }
                    if payModel != .booth {
                        namedRow(L("br.yourShare", table: "Hybrid", language: appLanguage), yourShareCents)
                        namedRow(L("br.houseShare", table: "Hybrid", language: appLanguage), houseCutCents)
                    }
                    if cardFeesCents > 0 { row("br.cardFeesEst", cardFeesCents) }
                    row("br.supplies", suppliesCents)
                    if extraFeesCents > 0 { row("br.extra", extraFeesCents) }
                    row("br.takeHome", takeHomeCents, strong: true)
                    if taxReserveCents > 0 { row("br.taxReserve", taxReserveCents) }
                }
                .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))

                Text(L("br.taxNote", table: "Hybrid", language: appLanguage))
                    .font(Brand.font(16))
                    .foregroundStyle(Brand.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("settings.hours").font(Brand.font(17))
                    TextField("0", text: $hoursText)
                        .keyboardType(.decimalPad)
                        .focused($hoursFocused)
                        .font(Brand.font(24, weight: .heavy))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 58)
                        .background(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(hoursFocused ? Brand.hotPink : Brand.line, lineWidth: hoursFocused ? 3 : 2))
                    if let hourly = hourlyCents {
                        HStack {
                            Text(L("br.effectiveHourly", table: "Hybrid", language: appLanguage)).font(Brand.font(17))
                            Spacer()
                            Text("\(formatCurrency(hourly, language: appLanguage))/hr").font(Brand.font(22, weight: .heavy)).monospacedDigit()
                        }
                    }
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .standardNavigationControls()
    }

    private var hourlyCents: Int? {
        let normalized = hoursText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let hours = Decimal(string: normalized), hours > 0 else { return nil }
        return MoneyMath.hourlyTakeHome(takeHomeCents: takeHomeCents, hours: hours)
    }

    private func row(_ key: LocalizedStringKey, _ cents: Int, strong: Bool = false) -> some View {
        namedRow(String(localized: key, locale: Locale(identifier: appLanguage)), cents, strong: strong)
    }

    private func namedRow(_ label: String, _ cents: Int, strong: Bool = false) -> some View {
        HStack { Text(label); Spacer(); Text(formatCurrency(cents, language: appLanguage)).monospacedDigit() }
            .font(Brand.font(strong ? 20 : 18, weight: .heavy))
            .padding(.horizontal, 18)
            .frame(minHeight: 58)
            .background(strong ? Brand.berry : Brand.surface)
            .overlay(alignment: .bottom) { Rectangle().fill(Brand.line).frame(height: 1) }
    }
}

struct CompareView: View {
    let boothCents: Int, commissionCents: Int, hybridCents: Int, commissionPercent: Int
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    private var winner: Int { max(boothCents, commissionCents, hybridCents) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("compare.title").font(Brand.font(28, weight: .heavy))
                comparison(label: L("compare.onBooth", language: appLanguage), amount: boothCents, selected: boothCents == winner)
                comparison(label: String(format: L("compare.onCommission", language: appLanguage), "\(commissionPercent)%"), amount: commissionCents, selected: commissionCents == winner)
                comparison(label: L("compare.onHybrid", table: "Hybrid", language: appLanguage), amount: hybridCents, selected: hybridCents == winner)
                Text("compare.note").font(Brand.font(18)).foregroundStyle(Brand.mutedInk)
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .standardNavigationControls()
    }

    private func comparison(label: String, amount: Int, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(Brand.font(18))
                Text(formatCurrency(amount, language: appLanguage)).font(Brand.font(42, weight: .heavy)).monospacedDigit()
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Brand.hotPink)
                    .accessibilityLabel(Text("a11y.selected"))
            }
        }
        .padding(20)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(selected ? Brand.hotPink : Brand.line, lineWidth: selected ? 3 : 2))
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
                if !store.weeks.isEmpty { metrics }
                ForEach(store.weeks.prefix(12)) { week in
                    Button { onSelect(week) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatWeekRange(week.weekStart, language: appLanguage)).font(Brand.font(18))
                                if let hours = week.hours, hours > 0 {
                                    Text("\(hours.formatted(.number.precision(.fractionLength(0...1)))) \(L("history.hours", language: appLanguage))").font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
                                }
                            }
                            Spacer()
                            Text(formatCurrency(week.takeHomeCents, language: appLanguage)).font(Brand.font(22, weight: .heavy)).monospacedDigit()
                        }
                        .foregroundStyle(Brand.ink)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 68)
                        .background(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
                        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Brand.screenPadding)
        }
        .background(Brand.page.ignoresSafeArea())
        .foregroundStyle(Brand.ink)
        .standardNavigationControls()
    }

    private var metrics: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(label: L("history.lastFour", language: appLanguage), value: formatCurrency(fourWeekTotal, language: appLanguage))
                metricCard(label: L("history.averageWeek", language: appLanguage), value: formatCurrency(averageWeek, language: appLanguage))
            }
            if let averageHourlyCents {
                metricCard(label: L("history.averageHourly", language: appLanguage), value: "\(formatCurrency(averageHourlyCents, language: appLanguage))/hr")
            }
        }
    }

    private func metricCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(Brand.font(16)).foregroundStyle(Brand.mutedInk)
            Text(value).font(Brand.font(23, weight: .heavy)).monospacedDigit().minimumScaleFactor(0.75).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.controlRadius))
        .overlay(RoundedRectangle(cornerRadius: Brand.controlRadius).stroke(Brand.line, lineWidth: 1.5))
    }
}
