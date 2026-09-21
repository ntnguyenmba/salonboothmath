# Ads and privacy release checklist

## Product rule

- Free users may see one banner ad on the Home screen.
- Lifetime users see no ads after the purchase entitlement is active.
- Ads never gate the free calculator.
- Do not use interstitial or rewarded ads in this app.

## iOS AdMob

Configured:

- App Store ID: 6806374138
- AdMob app ID: ca-app-pub-1237434632796366~9757490921
- Banner ad unit: ca-app-pub-1237434632796366/2950294014
- app-ads.txt publisher line: google.com, pub-1237434632796366, DIRECT, f08c47fec0942fa0

Before App Store submission:

1. Build and run on a real iPhone.
2. Confirm a free account/device shows the banner.
3. Complete a sandbox lifetime purchase.
4. Confirm the banner disappears immediately and stays gone after relaunch.
5. Confirm Restore Purchase also removes the banner.
6. In App Store Connect, update App Privacy for Google Mobile Ads SDK data use. Do not leave Data Not Collected selected.
7. Review the Xcode privacy report generated from the app and bundled SDK privacy manifests before submission.

Google documents that the Mobile Ads SDK may collect IP address/general location, crash and performance data, device identifiers, advertising data, and product interactions for advertising and analytics. App Store Connect answers must match the final build and configuration.

## Android AdMob

Do not enable production ads until the Android AdMob app ID and Android banner ad unit ID are added.

When those IDs are available:

1. Add the Google Mobile Ads SDK.
2. Add the Android AdMob app ID to AndroidManifest.xml.
3. Initialize Mobile Ads.
4. Show one banner only when BillingManager.isUnlocked is false.
5. Remove the banner immediately when BillingManager.isUnlocked becomes true.
6. Test a Google Play license-test purchase and Restore Purchase.
7. Update Google Play Console > App content > Data safety.

Google documents that the Mobile Ads SDK automatically collects or shares IP address/general location, user product interactions, diagnostics, and device/account identifiers for advertising, analytics, and fraud prevention. Data is encrypted in transit. The final Data Safety answers must reflect the exact SDK configuration used in the released build.

## app-ads.txt

Developer website root must serve:

google.com, pub-1237434632796366, DIRECT, f08c47fec0942fa0

The developer website domain in App Store Connect and Google Play must match the domain hosting this file.
