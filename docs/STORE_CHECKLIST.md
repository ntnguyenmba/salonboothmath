# Store checklist

## Legal pages used in the apps

- Privacy: https://sites.google.com/everittventures.com/salon-booth-math/privacy
- Terms: https://sites.google.com/everittventures.com/salon-booth-math/terms
- Support: https://sites.google.com/everittventures.com/salon-booth-math/support

Use these exact URLs in App Store Connect and Google Play Console.

## Must be public

Apple and Google reviewers will open these links while signed out.

In Google Sites:

1. Open the site → Settings → Published site.
2. Publish to the web.
3. Audience must be **Anyone** / public, not Restricted to Everitt Ventures.
4. Confirm each URL loads in a private browser window with no Google login.

If a private window hits a Google sign-in page, review will bounce.

## In-app wiring

iOS Settings and Android Settings open the three URLs above.
iOS also ships:

- `ITSAppUsesNonExemptEncryption = false`
- `PrivacyInfo.xcprivacy` (no tracking, UserDefaults for app settings only)

## Store purchase configuration

The apps use the existing one-time product ID:

- `com.everittventures.salonboothmath.lifetime`
- iOS: non-consumable
- Google Play: one-time in-app product
- Intended price: $9.99, with the displayed price loaded from the store

Do not create a new product ID for this update. Keep the existing store product active and available in the release countries.

## Release versions

- iOS: 1.1, build 2
- Android: 1.1.0, versionCode 3

## Before submitting the update

- Test Buy and Restore Purchase with an Apple sandbox/test account on a physical iPhone.
- Test Buy and restore/owned-product recognition through a Google Play testing track on an Android device.
- Confirm the existing product is approved/active and attached to the app version where each store requires it.
- Build the signed iOS archive and Android AAB.
- Use screenshots with a realistic take-home such as $818.25, not $0.
