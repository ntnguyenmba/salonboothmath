import SwiftUI
import GoogleMobileAds

@main
struct SalonBoothMathApp: App {
    init() {
        MobileAds.shared.start()
    }

    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    var body: some Scene {
        WindowGroup {
            Group {
                if didCompleteOnboarding {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .environment(\.locale, AppLanguage.current(appLanguage).locale)
            .preferredColorScheme(.dark)
            .tint(Brand.hotPink)
        }
    }
}
