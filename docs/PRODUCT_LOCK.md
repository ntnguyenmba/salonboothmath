# Salon Booth Math — Product Lock

## The product

**Know What You Keep** is the whole product.

Salon Booth Math is a focused weekly take-home calculator for booth renters and commission salon professionals.

The free app answers tonight: **what did I keep?**

The paid product is memory and comparison: **$4.99 once to keep weeks, look back later, and compare booth vs commission.**

$4.99 is for the second week, not the first.

## Locked business model

### Free forever
- Weekly calculator
- Breakdown
- Booth rent math
- Commission math
- Cash tips and card tips
- Card fees
- Supplies
- Optional tax reserve estimate

### Lifetime — $4.99 once
- Save Week
- History
- Booth vs Commission Compare
- Restore Purchase

No subscription. No account. No cloud requirement.

The price appears only when the user asks to Save, open History, or open Compare. Home never sells Lifetime.

Paywall copy:

> **Keep this week. Look back later. Compare booth vs commission. Once. No subscription.**

## Do not reopen

Do not add:
- Booking
- Clients
- CRM
- Calendar
- Inventory
- SMS
- AI
- Payroll
- Team management
- Invoices
- Marketplace
- Subscriptions
- Blog
- A bigger website
- A fourth brand color
- A Free badge on Home
- “Lifetime” on the Save button
- Charts or sparklines

The website is a storefront, not a second product.

Trade (Nail / Hair / Barber / Esthetician) may stay in onboarding only as a greeting. It must not change math in v1. Do not build trade-specific themes.

## Home — iOS and Android

Home is calculator-only.

Order:
1. This week
2. Pay context
3. Services
4. Cash tips
5. Card tips
6. Supplies
7. YOU TOOK HOME
8. Take-home amount
9. Save week
10. See breakdown

No membership banner. No price card. No large logo lockup. No purchase copy before the user tries a paid action.

### Pay context

Booth example:

`Booth rent · $350/week`

Commission example:

`You keep 55% + tips`

Do not use shorthand such as `55% · You`.

### Field names

Use exactly:
- Services
- Cash tips
- Card tips
- Supplies

Do not shorten Cash tips / Card tips to Cash / Card.

### Take-home

The take-home amount is the dominant number.

Tax reserve is informational only and does not reduce the main take-home hero.

## Free Breakdown

Breakdown stays free.

Show only applicable rows:
- Gross
- Booth rent or owner cut
- Card fees
- Supplies
- Extra fees / tip-out if applicable
- Take-home
- Tax reserve estimate if enabled
- Optional hours field

The user should be able to understand why the take-home number is the number before being asked to pay.

## Paid features

### Save Week

The button always says **Save week**.

If the user is not unlocked, tapping it opens the lifetime purchase sheet.

### History

History is lifetime-only.

History is a weekly notebook, not analytics software.

Allowed compact summary at the top:
- Last 4 weeks total
- Average week
- Average hourly only when hours exist

Then a simple list: week/date and take-home. Tapping a saved week reopens it.

Do not add charts, sparklines, month dashboards, or comparison graphs on History.

### Compare

Compare is lifetime-only and may be the strongest day-one purchase trigger.

Show the user's actual week under:
- On booth
- On commission
- Difference where useful

Keep it simple. It exists to answer a pay-model decision, not to become a financial dashboard.

### Restore

Restore Purchase must work on both stores. It is not a selling point. It makes the one-time purchase feel safe.

## Languages

English, Spanish, and Vietnamese are release requirements on both iOS and Android.

- English
- Español
- Tiếng Việt

The selected language must persist.

Every user-facing string must be audited before release, including:
- Onboarding
- Home
- Pay context
- Field labels
- Buttons
- Overflow/menu
- Breakdown
- History
- Compare
- Settings
- Paywall
- Purchase errors
- Restore Purchase
- Legal & Support
- About
- Disclaimers

No new English-only strings may ship.

## Visual system

Locked palette:
- Wine: `#4B0728` — app page / salon dark
- Hot pink: `#FF3D6E` — tap only
- White: `#FFFFFF` — reading text on wine

Do not introduce blush, gold, orange, blue, beige, or another neon.

Pink is an accent, not the reading color for the whole product.

Use pink primarily for:
- Primary action
- Take-home label
- Selected states
- Small high-value highlights
- 4px header crown

Use white for reading text and important headings on wine.

The calculator Home stays wine. Do not revert to a white spreadsheet Home.

### Typography

Use native system rounded typography on both platforms.

Do not claim Nunito or any other custom face unless the font files are bundled and registered on iOS and Android.

Do not make every line ExtraBold. Reserve the strongest weight for the take-home amount, key headings, and primary actions.

Minimum visible text size is 16px.

## Branding inside the apps

The logo is not the Home product.

Use the real chair + pink dollar mark sparingly, such as onboarding or About. Keep it off the calculator Home if it consumes useful vertical space.

## Website

The website is a small storefront for the apps.

It does not need a blog, account, calculator clone, content hub, or feature maze.

### Hero

Use the exact wine / hot pink / white identity.

- Real logo, crisp and opaque
- **Salon Booth Math** in white
- **Know What You Keep** in hot pink
- Supporting line: **Booth or commission. See what you actually took home this week.**

Do not use a giant faded watermark behind the hero.

### Store buttons

Use real official App Store / Google Play badges only when their listing URLs are live.

Never show placeholder copy such as:
- Apple App Store link
- Android App link

If a listing is not live, hide its badge.

### Product proof

Show one clean calculator screenshot with realistic values and a visible take-home number such as **$818.25**.

The site should show the product result, not decorate around it.

### Privacy message

If the implementation remains accurate to this statement, the site may say:

**Private by design. No account required. Your weekly calculations stay on your device.**

### Website languages

The website must support:
- English
- Español
- Tiếng Việt

Legal and support content must also be available and understandable from the selected language experience.

### Website footer

Keep legal/support navigation in the footer so it does not compete with the primary product action.

Include:
- Privacy
- Terms
- Support
- Language
- `© 2026 Everitt Ventures LLC`

## Privacy, Terms, and Support

These must be live before store submission.

### Privacy Policy

Accurately describe:
- Local device storage
- Whether any data is collected
- Apple / Google purchase processing
- Support information the user voluntarily sends
- Analytics or telemetry only if actually present
- How local data can be removed

Do not claim zero collection if analytics, telemetry, advertising, or a backend is later introduced.

### Terms of Use

Cover at minimum:
- Calculations are estimates
- Not tax, accounting, financial, or legal advice
- User is responsible for entered values
- No guarantee estimates match payroll, tax, salon, or payment records
- One-time purchase terms
- Everitt Ventures LLC ownership / operator information

### Support

Provide a working public support destination with actual contact information and Restore Purchase guidance.

## Store screenshots

Do not use an empty `$0` state for the primary store screenshots.

Enter realistic demonstration data before capturing screenshots.

Recommended sequence:

1. Home — **Know what you keep** — calculator with a realistic take-home amount such as `$818.25`
2. Breakdown — **See where the money went**
3. Compare — **Booth or commission? Compare both.**
4. History if additional screenshots are useful
5. Language / privacy only if needed

Demo values are for screenshots only. Do not seed fake financial history into a real user's first-run app.

## Store positioning

Free download.

One-time non-consumable lifetime purchase: `$4.99`.

The paid boundary is:
- Save
- History
- Compare

The number itself and Breakdown remain free forever.

## Release order

1. Match copy and hierarchy to this document.
2. Replace commission shorthand with human pay context.
3. Confirm Cash tips / Card tips everywhere.
4. Reduce unnecessary pink headings and keep the take-home hierarchy dominant.
5. Remove large Home branding that competes with the calculator.
6. Use system rounded type, or bundle and verify a custom font before claiming it.
7. Complete EN / ES / VI audit on both platforms.
8. Test purchase and restore on Apple and Google.
9. Publish working Privacy, Terms, and Support URLs.
10. Finish the storefront website with crisp logo, white/pink hero, live badges only, and one real product screenshot.
11. Capture realistic App Store and Play Store screenshots.
12. Confirm iOS and Android money fixtures in `docs/MATH_PARITY.md` match.
13. Submit store builds.

## Product test

Every new idea must pass this question:

**Does this help a booth renter or commission professional know what they kept this week, remember a week, or compare booth vs commission?**

If not, it does not belong in Salon Booth Math v1.

## Why $4.99 works

The free screen earns trust first.

A user enters a real week and sees a number that matters. If they return next week, they may want to keep the previous week instead of treating the calculator as disposable. Save + History turns the calculator into their simple weekly notebook.

Compare can justify the purchase immediately for someone choosing between booth rent and commission because the decision can be worth far more than $4.99.

Most downloads do not need to convert. The goal is not to extract $4.99 from every user. The goal is to be a fair `$4.99` notebook for the people who need the notebook.

**Calculator first. Memory second. Once. No subscription.**
