import Foundation

enum Trade: String, CaseIterable, Identifiable, Codable {
    case nail, hair, barber, esthetician
    var id: String { rawValue }
    var titleKey: String { switch self { case .nail: "trade.nail"; case .hair: "trade.hair"; case .barber: "trade.barber"; case .esthetician: "trade.esthetician" } }
}

enum PayModel: String, CaseIterable, Identifiable, Codable { case booth, commission, hybrid; var id: String { rawValue } }
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
    static func workerTips(cashTips: Int, cardTips: Int, tipOwner: TipOwner) -> Int {
        let allTips = cashTips + cardTips
        switch tipOwner {
        case .you: return allTips
        case .house: return 0
        case .split: return roundedCents(Decimal(allTips) / 2)
        }
    }
    static func houseTips(cashTips: Int, cardTips: Int, tipOwner: TipOwner) -> Int {
        cashTips + cardTips - workerTips(cashTips: cashTips, cardTips: cardTips, tipOwner: tipOwner)
    }
    static func hourlyTakeHome(takeHomeCents: Int, hours: Decimal) -> Int? { hours > 0 ? roundedCents(Decimal(takeHomeCents) / hours) : nil }
    static func taxReserve(takeHomeCents: Int, rate: Decimal) -> Int { takeHomeCents > 0 ? roundedCents(Decimal(takeHomeCents) * rate) : 0 }

    static func boothTakeHome(services: Int, cashTips: Int, cardTips: Int, supplies: Int, weeklyRent: Int, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        services + cashTips + cardTips - weeklyRent - cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) - supplies - extraFees
    }

    static func commissionTakeHome(services: Int, cashTips: Int, cardTips: Int, supplies: Int, cut: Decimal, tipOwner: TipOwner, workerPaysCardFees: Bool = false, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        let tips = workerTips(cashTips: cashTips, cardTips: cardTips, tipOwner: tipOwner)
        let fees = workerPaysCardFees ? cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) : 0
        return servicePay(services: services, cut: cut) + tips - fees - supplies - extraFees
    }

    static func hybridTakeHome(services: Int, cashTips: Int, cardTips: Int, supplies: Int, weeklyRent: Int, cut: Decimal, tipOwner: TipOwner, workerPaysCardFees: Bool = true, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        commissionTakeHome(services: services, cashTips: cashTips, cardTips: cardTips, supplies: supplies, cut: cut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFees, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) - weeklyRent
    }

    static func weeklyRent(cents: Int, period: RentPeriod) -> Int { period == .week ? cents : roundedCents(Decimal(cents) / Decimal(string: "4.3333")!) }

    /// Services cents needed to hit a target take-home under booth (current tips/fees/rent/supplies).
    static func requiredServicesBooth(targetTakeHome: Int, cashTips: Int, cardTips: Int, weeklyRent: Int, supplies: Int, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        let coef = Decimal(1) - percentServicesOnCard * cardFeeRate
        guard coef > 0 else { return 0 }
        let fixed = Decimal(cashTips) + Decimal(cardTips) * (Decimal(1) - cardFeeRate) - Decimal(weeklyRent) - Decimal(supplies) - Decimal(extraFees)
        let needed = (Decimal(targetTakeHome) - fixed) / coef
        return max(0, roundedCents(needed))
    }

    /// Services cents needed under commission (or hybrid when weeklyRent is applied after).
    static func requiredServicesCommission(targetTakeHome: Int, cashTips: Int, cardTips: Int, supplies: Int, cut: Decimal, tipOwner: TipOwner, workerPaysCardFees: Bool, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70, weeklyRent: Int = 0) -> Int {
        guard cut > 0 else { return 0 }
        let tips = workerTips(cashTips: cashTips, cardTips: cardTips, tipOwner: tipOwner)
        var services = 0
        for _ in 0..<8 {
            let fees = workerPaysCardFees ? cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) : 0
            let rhs = Decimal(targetTakeHome) - Decimal(tips) + Decimal(fees) + Decimal(supplies) + Decimal(extraFees) + Decimal(weeklyRent)
            let next = roundedCents(rhs / cut)
            if abs(next - services) <= 1 { return max(0, next) }
            services = max(0, next)
        }
        return max(0, services)
    }

    /// Max weekly rent such that booth take-home >= commission take-home at this volume.
    static func maxRentToBeatCommission(services: Int, cashTips: Int, cardTips: Int, supplies: Int, cut: Decimal, tipOwner: TipOwner, workerPaysCardFees: Bool, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        let commission = commissionTakeHome(services: services, cashTips: cashTips, cardTips: cardTips, supplies: supplies, cut: cut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFees, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard)
        let fees = cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard)
        let gross = services + cashTips + cardTips
        return max(0, gross - fees - supplies - extraFees - commission)
    }

    /// Commission cut (basis points, user keep %) that matches booth take-home at this volume.
    static func breakEvenCutBasisPoints(services: Int, cashTips: Int, cardTips: Int, supplies: Int, weeklyRent: Int, tipOwner: TipOwner, workerPaysCardFees: Bool, extraFees: Int = 0, cardFeeRate: Decimal = 0.029, percentServicesOnCard: Decimal = 0.70) -> Int {
        guard services > 0 else { return 0 }
        let booth = boothTakeHome(services: services, cashTips: cashTips, cardTips: cardTips, supplies: supplies, weeklyRent: weeklyRent, extraFees: extraFees, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard)
        let tips = workerTips(cashTips: cashTips, cardTips: cardTips, tipOwner: tipOwner)
        let fees = workerPaysCardFees ? cardFees(services: services, cardTips: cardTips, cardFeeRate: cardFeeRate, percentServicesOnCard: percentServicesOnCard) : 0
        let rhs = Decimal(booth) - Decimal(tips) + Decimal(fees) + Decimal(supplies) + Decimal(extraFees)
        let cut = rhs / Decimal(services)
        let clamped = min(max(cut, 0), 1)
        return roundedCents(clamped * 10_000)
    }

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
