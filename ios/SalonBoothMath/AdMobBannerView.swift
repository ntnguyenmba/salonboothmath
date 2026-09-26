import SwiftUI
import GoogleMobileAds
import UIKit

enum AdMobConfig {
    static let bannerAdUnitID = "ca-app-pub-1237434632796366/2950294014"
}

struct FreeBannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobConfig.bannerAdUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first

        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        banner.load(request)

        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
