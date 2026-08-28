import Foundation

struct WeekRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var weekStart: Date
    var servicesCents: Int
    var cashTipsCents: Int
    var cardTipsCents: Int
    var suppliesCents: Int
    var extraFeesCents: Int
    var hours: Double?
    var payModel: PayModel
    var takeHomeCents: Int

    init(
        id: UUID = UUID(),
        weekStart: Date,
        servicesCents: Int,
        cashTipsCents: Int,
        cardTipsCents: Int,
        suppliesCents: Int,
        extraFeesCents: Int = 0,
        hours: Double? = nil,
        payModel: PayModel,
        takeHomeCents: Int
    ) {
        self.id = id
        self.weekStart = weekStart
        self.servicesCents = servicesCents
        self.cashTipsCents = cashTipsCents
        self.cardTipsCents = cardTipsCents
        self.suppliesCents = suppliesCents
        self.extraFeesCents = extraFeesCents
        self.hours = hours
        self.payModel = payModel
        self.takeHomeCents = takeHomeCents
    }
}

@MainActor
final class WeekStore: ObservableObject {
    @Published private(set) var weeks: [WeekRecord] = []

    private let storageKey = "savedWeeks.v1"

    init() {
        load()
    }

    func save(_ week: WeekRecord) {
        if let index = weeks.firstIndex(where: { Calendar.current.isDate($0.weekStart, equalTo: week.weekStart, toGranularity: .weekOfYear) }) {
            weeks[index] = week
        } else {
            weeks.append(week)
        }
        weeks.sort { $0.weekStart > $1.weekStart }
        persist()
    }

    func week(for date: Date) -> WeekRecord? {
        weeks.first { Calendar.current.isDate($0.weekStart, equalTo: date, toGranularity: .weekOfYear) }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WeekRecord].self, from: data) else {
            weeks = []
            return
        }
        weeks = decoded.sorted { $0.weekStart > $1.weekStart }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(weeks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
