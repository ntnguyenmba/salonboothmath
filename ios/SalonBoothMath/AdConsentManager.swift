import Foundation
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class AdConsentManager: ObservableObject {
    static let shared = AdConsentManager()

    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false

    private var mobileAdsStarted = false

    private init() {}

    func requestConsent() {
        let parameters = RequestParameters()

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }

                self.refreshState()
                self.startMobileAdsIfAllowed()

                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: nil)
                } catch {
                    // A previous valid consent state can still permit ads.
                }

                self.refreshState()
                self.startMobileAdsIfAllowed()
            }
        }
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            return
        }

        refreshState()
        startMobileAdsIfAllowed()
    }

    private func refreshState() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startMobileAdsIfAllowed() {
        guard canRequestAds, !mobileAdsStarted else { return }
        mobileAdsStarted = true
        MobileAds.shared.start()
    }
}
