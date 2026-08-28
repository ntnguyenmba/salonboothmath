import Foundation
import WidgetKit

enum WidgetBridge {
    static let appGroup = "group.com.everittventures.salonboothmath"
    static let takeHomeKey = "widget.currentWeek.takeHomeCents"

    static func updateCurrentWeek(takeHomeCents: Int) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(takeHomeCents, forKey: takeHomeKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: "widget.updatedAt")
        WidgetCenter.shared.reloadTimelines(ofKind: "SalonBoothMathWidget")
    }
}
