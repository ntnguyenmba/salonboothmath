import Foundation

enum PremiumFeature {
    case save
    case history
    case compare
    case payCheckup
}

@MainActor
final class FreeAccessState: ObservableObject {
    @Published private(set) var usedSave: Bool
    @Published private(set) var usedHistory: Bool
    @Published private(set) var usedCompare: Bool
    @Published private(set) var usedPayCheckup: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        usedSave = defaults.bool(forKey: Keys.save)
        usedHistory = defaults.bool(forKey: Keys.history)
        usedCompare = defaults.bool(forKey: Keys.compare)
        usedPayCheckup = defaults.bool(forKey: Keys.payCheckup)
    }

    func used(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .save: return usedSave
        case .history: return usedHistory
        case .compare: return usedCompare
        case .payCheckup: return usedPayCheckup
        }
    }

    func claim(_ feature: PremiumFeature, isUnlocked: Bool) -> Bool {
        if isUnlocked { return true }
        if used(feature) { return false }
        setUsed(feature)
        return true
    }

    private func setUsed(_ feature: PremiumFeature) {
        switch feature {
        case .save:
            usedSave = true
            defaults.set(true, forKey: Keys.save)
        case .history:
            usedHistory = true
            defaults.set(true, forKey: Keys.history)
        case .compare:
            usedCompare = true
            defaults.set(true, forKey: Keys.compare)
        case .payCheckup:
            usedPayCheckup = true
            defaults.set(true, forKey: Keys.payCheckup)
        }
    }

    private enum Keys {
        static let save = "didUseFreeSave"
        static let history = "didUseFreeHistory"
        static let compare = "didUseFreeCompare"
        static let payCheckup = "didUseFreePayCheckup"
    }
}
