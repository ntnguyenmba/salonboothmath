# Salon Booth Math v1

## Product rule

One job: **what did I take home this week?**

Do not add features outside this spec before first store submission.

## Free

- Onboarding
- Pick Nail / Hair / Barber / Esthetician
- Pick Booth rent / Commission
- Set weekly or monthly booth rent, or commission cut
- One current week
- Services
- Tips
- Supplies
- Live `YOU TOOK HOME` hero
- Native Share take-home card

## $4.99 lifetime unlock

One non-consumable purchase. No subscription.

- Save weeks
- Other weeks
- History
- See breakdown
- Booth vs commission
- Both pay models saved
- Cash/card tips
- Extra booth fees
- Hours and per-hour result
- Tax set-aside line
- Month total
- High-rent flag

Paywall triggers on Save week, See breakdown, week navigation, Compare, or History.

## Onboarding

1. `What do you do?`
2. `How do you get paid?`
3. Weekly booth rent OR commission cut
4. `Let’s see this week.`

One question per screen. No setup dump.

## Home

Berry top bar with `This week` and large previous/next controls.

Stack three large fields vertically:

1. Services
2. Tips
3. Supplies

Always-visible result:

`YOU TOOK HOME`

Large locale-formatted amount in ink.

Primary: `Save week`

Secondary: `See breakdown`

No grid. No dashboard. No chart.

## Calculations

Use integer cents internally.

Gross = services + cash tips + card tips

Card base = card tips + services × percent-on-card

Default percent-on-card = 70%

Card fees = card base × card-fee rate

Monthly booth rent converted to weekly = monthly rent / 4.3333

Booth take-home = gross - weekly rent - card fees - supplies - extra fees

Commission take-home = services × user cut + user tips - user card fees - supplies

Tips rules: user keeps all, house keeps all, or split; default split is 50/50.

Per hour = take-home / hours when hours > 0.

Tax set-aside = take-home × tax percent. Display only. Never subtract it from the hero.

High-rent warning when weekly rent / gross >= 40% and gross > 0.

If take-home is negative, keep the signed amount and make the breakdown available to explain it.

## Sample week

Ship a preloaded sample week so Store Review never lands on an empty product.

## Accessibility

- WCAG 2.2 AA contrast target
- Never rely on color alone
- Dynamic Type must not clip the money hero
- VoiceOver reads the amount as currency
- Minimum visible UI text size 16px
- Minimum practical tap target 44pt, with primary controls 56-64pt

## Localization

Ship English, Vietnamese, and Spanish together in v1. Device language selects localization. Currency uses locale formatting.

## iOS widget

One small Home Screen widget only.

- Berry background
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

Review note should explain booth/commission niche, offline saved weeks, sample week, native share, widget, one-time StoreKit purchase, and no account.
