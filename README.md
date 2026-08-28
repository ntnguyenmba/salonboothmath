# Salon Booth Math

**What did I take home this week?**

A focused offline take-home tool for nail techs, hair stylists, barbers, and estheticians working on booth rent or commission.

iOS + Android · English + Vietnamese + Spanish · $4.99 once · No subscription

## v1

- No account
- Free first week: Services + Tips + Supplies + live take-home
- One-time $4.99 lifetime unlock
- Saved weeks and History
- Full Breakdown
- Booth vs Commission comparison
- Rent, commission, card fee, hours, tax set-aside, and extra-fee settings
- Native Share take-home card
- Small iOS Home Screen widget
- Offline, on-device data
- No booking, clients, calendar, inventory, SMS, AI, or cloud sync

## Locked visual system

- Nunito Sans only, weights 700-800
- White `#FFFFFF`
- Ink `#0B1220`
- Berry `#4A1835`
- Hot pink `#FF3D6E`
- Warning `#C2410C`
- Error `#B42318`
- Minimum text size 16px
- Controls 56-64px high
- Radius 16-20px
- One action and one dominant number per screen
- No beige, navy, blush fills, tiny text, dashboard grids, gradients, or faded copy

## Repository rule

All work goes directly to `main`. Cursor and Codex should also work on `main` and must not create feature branches.

## Platform structure

- `ios/` SwiftUI + StoreKit 2 + WidgetKit
- `android/` Jetpack Compose + Google Play Billing
- `docs/` locked product/design/localization/release specifications

First implementation target: onboarding → This Week → live take-home math.

Not tax, legal, or financial advice.
