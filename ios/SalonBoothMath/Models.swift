import Foundation

enum Trade: String, CaseIterable, Identifiable, Codable {
    case nail, hair, barber, esthetician
    var id: String { rawValue }
    var titleKey: String { switch self { case .nail: "trade.nail"; case .hair: "trade.hair"; case .barber: "trade.barber"; case .esthetician: "trade.esthetician" } }
}

enum PayModel: String, CaseIterable, Identifiable, Codable { case booth, commission; var id: String { rawValue } }
enum RentPeriod: String, CaseIterable, Identifiable, Codable { case week, month; var id: String { rawValue } }
enum TipOwner: String, CaseIterable, Identifiable, Codable { case you, house, split; var id: String { rawValue } }

struct MoneyMath {
    static func cents(from text: String) -> Int {
        guard !text.contains("-"), let decimal = parseNumber(text), decimal >= 0 else { return 0 }
        return roundedCents(decimal * 100)
    }

    static func basisPoints(fromPercentText text: String, fallback: Int) -> Int {
        guard !text.contains("-"), let percent = parseNumber(text), percent >= 0 else { return fallback }
        return roundedCents(percent * 100)
    }

    static func rate(fromBasisPoints basisPoints: Int) -> Decimal { Decimal(basisPoints) / Decimal(10_000) }
    static func percentText(fromBasisPoints basisPoints: Int) -> String { NSDecimalNumber(decimal: Decimal(basisPoints) / 100).stringValue }
    static func cardFees(services: Int, cardTips: Int, cardFeeRate: Decimal, percentServicesOnCard: Decimal) -> Int { roundedCents((Decimal(cardTips) + Decimal(services) * percentServicesOnCard) * cardFeeRate) }
    static func servicePay(services: Int, cut: Decimal) -> Int { roundedCents(Decimal(services) * cut) }
    static func houseCut(services: Int, workerCut: Decimal) -> Int { services - servicePay(services: services, cut: workerCut) }
    static func hourlyTakeHome(takeHomeCents: Int, hours: Decimal) -> Int? { hours > 0 ? roundedCents(Decimal(takeHomeCents) / hours) : nil }
    static func taxReserve(takeHomeCents: Int, rate: Decimal) -> Int { takeHomeCents > 0 ? roundedCents(Decimal(takeHomeCents) * rate) : 0 }
    static func boothTakeHome(services: Int, cashTips: Int, cardTips: Int, supplies: Int, weeklyRent: Int, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int { services + cashTips + cardTips - weeklyRent - cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) - supplies - extraFees }
    static func commissionTakeHome(services: Int, cashTips: Int, cardTips: Int, supplies: Int, cut: Decimal, tipOwner: TipOwner, workerPaysCardFees: Bool = false, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        let allTips = cashTips + cardTips
        let tips: Int = switch tipOwner { case .you: allTips; case .house: 0; case .split: roundedCents(Decimal(allTips) / 2) }
        let fees = workerPaysCardFees ? cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) : 0
        return servicePay(services: services, cut: cut) + tips - fees - supplies - extraFees
    }
    static func weeklyRent(cents: Int, period: RentPeriod) -> Int { period == .week ? cents : roundedCents(Decimal(cents) / Decimal(string: "4.3333")!) }

    private static func parseNumber(_ raw: String) -> Decimal? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return 0 }
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        value = String(value.unicodeScalars.filter { allowed.contains($0) })
        guard !value.isEmpty else { return nil }
        let dot = value.lastIndex(of: "."); let comma = value.lastIndex(of: ",")
        let decimalSeparator: Character? = {
            if let dot, let comma { return dot > comma ? "." : "," }
            if let dot { let digitsAfter = value.distance(from: value.index(after: dot), to: value.endIndex); return digitsAfter == 1 || digitsAfter == 2 ? "." : nil }
            if let comma { let digitsAfter = value.distance(from: value.index(after: comma), to: value.endIndex); return digitsAfter == 1 || digitsAfter == 2 ? "," : nil }
            return nil
        }()
        var normalized = ""
        for character in value { if character.isNumber { normalized.append(character) } else if let decimalSeparator, character == decimalSeparator { normalized.append(".") } }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func roundedCents(_ value: Decimal) -> Int { var value = value; var rounded = Decimal(); NSDecimalRound(&rounded, &value, 0, .plain); return NSDecimalNumber(decimal: rounded).intValue }
}
