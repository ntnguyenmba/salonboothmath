import Foundation

enum Trade: String, CaseIterable, Identifiable, Codable {
    case nail, hair, barber, esthetician
    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .nail: "trade.nail"
        case .hair: "trade.hair"
        case .barber: "trade.barber"
        case .esthetician: "trade.esthetician"
        }
    }
}

enum PayModel: String, CaseIterable, Identifiable, Codable {
    case booth, commission
    var id: String { rawValue }
}

enum RentPeriod: String, CaseIterable, Identifiable, Codable {
    case week, month
    var id: String { rawValue }
}

enum TipOwner: String, CaseIterable, Identifiable, Codable {
    case you, house, split
    var id: String { rawValue }
}

struct MoneyMath {
    static func cents(from text: String) -> Int {
        let normalized = text.replacingOccurrences(of: ",", with: "")
        guard let decimal = Decimal(string: normalized), decimal >= 0 else { return 0 }
        return roundedCents(decimal * 100)
    }

    static func cardFees(
        services: Int,
        cardTips: Int,
        cardFeeRate: Decimal,
        percentServicesOnCard: Decimal
    ) -> Int {
        let cardBase = Decimal(cardTips) + Decimal(services) * percentServicesOnCard
        return roundedCents(cardBase * cardFeeRate)
    }

    static func boothTakeHome(
        services: Int,
        cashTips: Int,
        cardTips: Int,
        supplies: Int,
        weeklyRent: Int,
        extraFees: Int = 0,
        cardFeeRate: Decimal = 0.029,
        percentServicesOnCard: Decimal = 0.70
    ) -> Int {
        services + cashTips + cardTips - weeklyRent -
            cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) -
            supplies - extraFees
    }

    static func commissionTakeHome(
        services: Int,
        cashTips: Int,
        cardTips: Int,
        supplies: Int,
        cut: Decimal,
        tipOwner: TipOwner,
        workerPaysCardFees: Bool = false,
        extraFees: Int = 0,
        cardFeeRate: Decimal = 0.029,
        percentServicesOnCard: Decimal = 0.70
    ) -> Int {
        let servicePay = roundedCents(Decimal(services) * cut)
        let allTips = cashTips + cardTips
        let tips: Int = switch tipOwner {
        case .you: allTips
        case .house: 0
        case .split: allTips / 2
        }
        let fees = workerPaysCardFees
            ? cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard)
            : 0
        return servicePay + tips - fees - supplies - extraFees
    }

    static func weeklyRent(cents: Int, period: RentPeriod) -> Int {
        period == .week ? cents : roundedCents(Decimal(cents) / Decimal(string: "4.3333")!)
    }

    private static func roundedCents(_ value: Decimal) -> Int {
        var value = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
