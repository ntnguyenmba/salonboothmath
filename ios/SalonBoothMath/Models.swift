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
        return NSDecimalNumber(decimal: decimal * 100).intValue
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
        let cardBase = Decimal(cardTips) + Decimal(services) * percentServicesOnCard
        let cardFees = NSDecimalNumber(decimal: cardBase * cardFeeRate).intValue
        return services + cashTips + cardTips - weeklyRent - cardFees - supplies - extraFees
    }

    static func commissionTakeHome(
        services: Int,
        cashTips: Int,
        cardTips: Int,
        supplies: Int,
        cut: Decimal,
        tipOwner: TipOwner,
        workerPaysCardFees: Bool = false,
        cardFeeRate: Decimal = 0.029,
        percentServicesOnCard: Decimal = 0.70
    ) -> Int {
        let servicePay = NSDecimalNumber(decimal: Decimal(services) * cut).intValue
        let allTips = cashTips + cardTips
        let tips: Int = switch tipOwner {
        case .you: allTips
        case .house: 0
        case .split: allTips / 2
        }
        let fees: Int
        if workerPaysCardFees {
            let cardBase = Decimal(cardTips) + Decimal(services) * percentServicesOnCard
            fees = NSDecimalNumber(decimal: cardBase * cardFeeRate).intValue
        } else {
            fees = 0
        }
        return servicePay + tips - fees - supplies
    }

    static func weeklyRent(cents: Int, period: RentPeriod) -> Int {
        period == .week ? cents : NSDecimalNumber(decimal: Decimal(cents) / Decimal(string: "4.3333")!).intValue
    }
}
