# Salon Booth Math

## Product rule

One job: **what did I take home this week?**

The week is the book. Today is only a fast way to add money into the current week.

## Free

- Onboarding
- Optional trade greeting: Nail / Hair / Barber / Esthetician (no math change)
- Pick Booth rent / Commission / Hybrid
- Set weekly or monthly booth rent, commission cut, or hybrid terms
- One current week
- Services
- Cash tips
- Card tips
- Supplies
- Add today into the current week
- Live `YOU TOOK HOME` weekly hero
- Free Breakdown
- Native Share take-home card

## $9.99 lifetime unlock

One non-consumable purchase. No subscription.

- Save weeks
- History notebook with compact last-4-weeks total and average
- Open saved weeks and their recorded day lines when available
- Booth vs Commission vs Hybrid comparison
- Extra fees
- Hours and per-hour result
- Tax set-aside line
- Restore Purchase

Paywall triggers on Save week, opening History, Compare, or paid saved-week detail. Add today and Breakdown remain free.

Paywall promise:

`Keep every day you just added. Look back later. Compare booth vs commission. $9.99 once. No subscription.`

The purchase button must use the localized StoreKit / Play Billing price when available. `$9.99` is the offline fallback and US base-price target.

## Home

Wine page. White reading text. Hot-pink 4pt crown.

Berry/wine top bar with `This week` and pay context.

Stack four large weekly fields vertically:

1. Services
2. Cash tips
3. Card tips
4. Supplies

Always-visible result:

`YOU TOOK HOME`

Large locale-formatted weekly amount in white.

Actions:

1. `Add today` secondary/free
2. `Save week` primary/paid
3. `See breakdown` secondary/free

Add today opens a sheet. It is not a daily Home, calendar, or daily take-home screen. The entered cents add to the current weekly totals and the sheet clears after adding.

## Calculations

Use integer cents internally. Platforms must match `docs/MATH_PARITY.md`.

Gross = services + cash tips + card tips

Card base = card tips + services × percent-on-card

Default percent-on-card = 70%

Card fees = card base × card-fee rate

Monthly booth rent converted to weekly = monthly rent / 4.3333

Booth take-home = gross - weekly rent - card fees - supplies - extra fees

Commission take-home = services × user cut + user tips - user card fees - supplies - extra fees

Hybrid take-home = commission-style earnings minus weekly booth rent and applicable costs.

Tips rules: user keeps all, house keeps all, or split; default split is 50/50.

Per hour = take-home / hours when hours > 0.

Tax set-aside = take-home × tax percent. Display only. Never subtract it from the hero.

High-rent warning when weekly rent / gross >= 40% and gross > 0.

If take-home is negative, keep the signed amount and make the breakdown available to explain it.

## Accessibility

- WCAG 2.2 AA contrast target on wine
- Never rely on color alone
- Dynamic Type must not clip the money hero
- VoiceOver reads the amount as currency
- Minimum visible UI text size 16px
- Minimum practical tap target 44pt, with primary controls 56-64pt

## Localization

Ship English, Vietnamese, and Spanish together. The selected app language persists. Currency uses locale/store formatting. No user-facing English-only strings may ship.

## Widget

One small Home Screen widget.

- Wine background
- 4pt hot-pink top edge
- White label and amount
- Current calendar week only
- Shows latest calculated take-home for current week
- Tap opens Home/current week
- Offline
- No configuration, paywall, editing, Live Activity, Lock Screen widget, Watch app, or Dynamic Island

## Store positioning

App Store title: `Salon Booth Math: Booth Rent`

Subtitle: `Take-home for nail & hair`

Business category.

Review note should explain the booth/commission/hybrid niche, offline weekly notebook, free calculator and Breakdown, one-time $9.99 non-consumable, native share, widget, Restore Purchase, and no account.
