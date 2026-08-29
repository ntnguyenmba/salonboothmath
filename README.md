# Salon Booth Math

**What did I take home this week?**

A focused offline take-home tool for nail techs, hair stylists, barbers, and estheticians working on booth rent or commission.

iOS + Android · English + Vietnamese + Spanish · $4.99 once · No subscription

## v1

- No account
- Free current-week calculator: Services + Cash tips + Card tips + Supplies + live take-home
- Breakdown is free
- One-time $4.99 lifetime unlock
- Saved weeks and History
- Booth vs Commission comparison
- Rent, commission, card fee, tax set-aside, and extra-fee settings
- Native Share take-home card
- Small Home Screen widget
- Offline, on-device data
- No booking, clients, calendar, inventory, SMS, AI, or cloud sync

## Locked visual system

Wine is the app surface. White is the reading color. Pink is the tap.

- Native system rounded typography; no bundled custom font
- Wine `#4B0728` page
- White `#FFFFFF` reading text
- Hot pink `#FF3D6E` actions, focus, 4px crown
- Warning and error use shape/text as well as color
- Minimum text size 16px
- Controls 56-64px high
- Radius 16-20px
- Home: four vertical money fields → take-home → Save → Breakdown
- One action and one dominant number per screen
- No beige, navy, blush fills, tiny text, dashboard grids, gradients, sparklines, or faded copy

## Repository rule

All work goes directly to `main`. Cursor and Codex should also work on `main` and must not create feature branches.

## Platform structure

- `ios/` SwiftUI + StoreKit 2 + WidgetKit
- `android/` Jetpack Compose + Google Play Billing
- `docs/` locked product/design/localization/release specifications

First implementation target: onboarding → This Week → live take-home math.

Not tax, legal, or financial advice.
