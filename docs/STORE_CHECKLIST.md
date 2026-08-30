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

## Still outside the repo

- Create IAP `com.everittventures.salonboothmath.lifetime` as a $9.99 non-consumable on both stores.
- Sandbox purchase + Restore on a device.
- Signed iOS archive and Android AAB.
- Screenshots with a realistic take-home such as $818.25, not $0.
