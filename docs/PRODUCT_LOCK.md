# Salon Booth Math — Product Lock

## Product

**Know What You Keep** is the product.

Salon Booth Math is a focused weekly take-home calculator for booth renters, commission professionals, and hybrid pay arrangements.

**Rule: day is how money enters. Week is what the user keeps.**

Home remains **This week**. Add Today is an input shortcut, not a daily dashboard, calendar, or daily take-home product.

## Business model

### Free
- Current-week calculator
- Services, Cash tips, Card tips, Supplies
- **Add today** into the current week
- Booth, Commission, and Hybrid math
- Live weekly take-home
- Breakdown
- Share
- Current-week widget
- Optional tax set-aside estimate, informational only

### Lifetime — $9.99 once
- Save week
- History
- Open saved weeks and retained day lines when available
- Booth vs Commission vs Hybrid Compare
- Restore Purchase

No subscription. No account. No cloud requirement.

Paid triggers are Save week, History, Compare, and paid saved-week detail. Home, Add Today, take-home, Breakdown, and Share remain free.

Paywall promise:

> **Keep every day you added. Look back later. Compare booth vs commission. $9.99 once. No subscription.**

The purchase button uses the localized StoreKit / Google Play price when available. `$9.99` is the offline fallback and US base-price target.

Product ID on both stores:

`com.everittventures.salonboothmath.lifetime`

## Home

Order:
1. This week
2. Pay context
3. Services
4. Cash tips
5. Card tips
6. Supplies
7. Weekly TAKE-HOME
8. Add today
9. Save week
10. See breakdown

Add Today opens a sheet with Services, Cash tips, Card tips, Supplies, and optional hours. Tapping **Add to this week** adds cents to the existing weekly fields, records a local DayLine, clears the sheet, and updates the weekly hero/widget.

Manual weekly entry remains supported. Never force users to create day lines.

Do not show a day Home, seven-day strip, calendar, per-day take-home hero, or per-day rent deduction.

## Math

Money math remains weekly. Add Today only changes weekly inputs.

- Booth rent is normalized to a weekly amount and deducted once from the week.
- Commission is calculated against weekly services/tips/costs.
- Hybrid is commission-style earnings minus weekly booth rent and applicable costs.
- Card fees use integer cents and the configured services-on-card percentage.
- Tax set-aside is optional planning and never reduces the take-home hero.
- Hours do not affect take-home.

Both platforms must continue to match `docs/MATH_PARITY.md`.

## History

History is a weekly notebook, not analytics software.

Allowed summary:
- Last 4 weeks total
- Average week
- Average hourly only when hours exist

Saved weeks may retain their DayLines. Do not turn History into a calendar or chart dashboard.

## Languages

English, Español, and Tiếng Việt ship together on iOS and Android. New user-facing strings must be localized across all three before release.

## Visual lock

- Wine `#4B0728`
- Hot pink `#FF3D6E`
- White `#FFFFFF`
- Native system rounded typography
- Minimum visible text 16px
- Primary controls 56–64px
- No beige, gold, orange, blue, blush, gradients, dashboards, or sparklines

Wine is the surface. White is the reading color. Pink is the tap/accent.

## Do not add

- Booking
- Clients / CRM
- Calendar
- Inventory
- SMS
- AI
- Payroll
- Team management
- Invoices
- Marketplace
- Subscription
- Blog
- Daily take-home product
- Day/month analytics dashboard
- Fourth brand color

## Privacy / legal

Public destinations used by both apps:
- Privacy: `https://sites.google.com/everittventures.com/salon-booth-math/privacy`
- Terms: `https://sites.google.com/everittventures.com/salon-booth-math/terms`
- Support: `https://sites.google.com/everittventures.com/salon-booth-math/support`

They must load signed-out/incognito before submission.

The app stores calculator/history data locally. Store purchases are processed by Apple or Google. Tax calculations are estimates and not tax, accounting, financial, or legal advice.

## Store screenshots

Never lead with `$0`.

Recommended sequence:
1. Home with a realistic weekly take-home such as **$818.25**, with Add Today visible
2. Breakdown
3. Compare
4. History
5. Language/privacy if useful

## Release gate

Do not call the app store-ready until all are true:
1. iOS and Android CI green at current `main`.
2. Public Privacy, Terms, and Support URLs work signed-out.
3. `$9.99` lifetime non-consumable exists on both stores with the exact product ID.
4. Sandbox purchase and Restore succeed on physical devices.
5. Signed iOS archive and Android AAB are uploaded.
6. Store privacy/data-safety/content-rating metadata is complete.
7. Real screenshots are uploaded.
8. EN/ES/VI smoke test shows no raw keys or English-only release UI.

**Calculator first. Weekly memory second. Once. No subscription.**
