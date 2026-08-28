import SwiftUI

@main
struct SalonBoothMathApp: App {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didCompleteOnboarding {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.light)
            .tint(Brand.hotPink)
        }
    }
}
