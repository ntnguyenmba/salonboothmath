import Foundation

struct DayLine: Codable, Identifiable, Equatable {
    let id: UUID
    var dateStart: Date
    var servicesCents: Int
    var cashTipsCents: Int
    var cardTipsCents: Int
    var suppliesCents: Int
    var hours: Double?

    init(
        id: UUID = UUID(),
        dateStart: Date,
        servicesCents: Int,
        cashTipsCents: Int,
        cardTipsCents: Int,
        suppliesCents: Int,
        hours: Double? = nil
    ) {
        self.id = id
        self.dateStart = Calendar.current.startOfDay(for: dateStart)
        self.servicesCents = servicesCents
        self.cashTipsCents = cashTipsCents
        self.cardTipsCents = cardTipsCents
        self.suppliesCents = suppliesCents
        self.hours = hours
    }

    var grossCents: Int { servicesCents + cashTipsCents + cardTipsCents }
}

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
    var days: [DayLine]

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
        takeHomeCents: Int,
        days: [DayLine] = []
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
        self.days = days
    }

    private enum CodingKeys: String, CodingKey {
        case id, weekStart, servicesCents, cashTipsCents, cardTipsCents, suppliesCents, extraFeesCents, hours, payModel, takeHomeCents, days
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        weekStart = try c.decode(Date.self, forKey: .weekStart)
        servicesCents = try c.decode(Int.self, forKey: .servicesCents)
        cashTipsCents = try c.decode(Int.self, forKey: .cashTipsCents)
        cardTipsCents = try c.decode(Int.self, forKey: .cardTipsCents)
        suppliesCents = try c.decode(Int.self, forKey: .suppliesCents)
        extraFeesCents = try c.decodeIfPresent(Int.self, forKey: .extraFeesCents) ?? 0
        hours = try c.decodeIfPresent(Double.self, forKey: .hours)
        payModel = try c.decodeIfPresent(PayModel.self, forKey: .payModel) ?? .booth
        takeHomeCents = try c.decode(Int.self, forKey: .takeHomeCents)
        days = try c.decodeIfPresent([DayLine].self, forKey: .days) ?? []
    }
}

@MainActor
final class WeekStore: ObservableObject {
    @Published private(set) var weeks: [WeekRecord] = []

    private let storageKey = "savedWeeks.v1"

    init() { load() }

    func save(_ week: WeekRecord) {
        if let index = weeks.firstIndex(where: { Calendar.current.isDate($0.weekStart, equalTo: week.weekStart, toGranularity: .weekOfYear) }) {
            weeks[index] = week
        } else {
            weeks.append(week)
        }
        weeks.sort { $0.weekStart > $1.weekStart }
        if weeks.count > 52 { weeks = Array(weeks.prefix(52)) }
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
