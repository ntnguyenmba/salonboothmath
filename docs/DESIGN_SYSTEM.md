# Salon Booth Math Design System

## Character

Bold, grown-up, easy to read, beauty-industry friendly, and deliberately simple for a tired or overloaded user.

Pacing can feel immediate, but there are no mascots, streaks, confetti, childish rewards, or game chrome.

## Surface

The app is a wine room, not a white spreadsheet.

- Page: wine `#4B0728`
- Raised fields / cards: darker wine `#35051D` to `#5A0A31`
- Reading text on wine: `#FFFFFF`
- Hot pink `#FF3D6E` is tap, focus, crown, and selected accent only
- Warning: warm highlight plus words, never color alone
- Error: distinct from warning plus words

Rule: **Wine is the salon dark. White does the reading. Pink is the tap.**

Do not flip Home back to a white page. The website storefront may use wine/pink/white in a marketing layout; the calculator itself stays wine.

## Type

Brand face: **native system rounded** on both platforms. iOS uses SwiftUI rounded system design. Android uses the platform sans with bold/extrabold weights.

Do not claim Nunito, Inter, or any bundled custom font unless the font files are actually shipped and registered.

- Chrome/week label: 18px / 700
- Field labels: 18-20px / 700
- Field numbers: 28-32px / 800
- Section heads: 22-28px / 800
- Take-home label: 18px / 700
- Take-home amount: 52-64px / 800, line-height 1.0, tabular figures
- Breakdown rows: 18px / 700
- Buttons: 18-20px / 800
- History metric labels: 16px minimum

Never go below 16px. Do not use 300 or 400 weights for visible app copy.

## Controls

- Height: 56-64px
- Radius: 16-20px
- Large internal padding
- Fields: darker wine fill with a visible white/pink edge; active fields use a stronger hot-pink focus edge
- Focus must not depend on low-contrast color alone
- Selected trade/pay tile: wine fill, white icon and label, optional pink ring

## Spacing

Use generous vertical rhythm rather than filling the viewport.

- Screen horizontal padding: 20-24px phone
- Major section gap: 28-36px
- Field stack gap: 20-24px
- Label-to-control gap: 10-12px
- Button stack gap: 12-16px
- Bottom safe-area breathing room: at least 20px

Do not push cards or text against screen edges.

## Screen rule

One screen = one obvious action + one dominant number or choice.

Home is a single vertical flow: wine header with 4px hot-pink crown, four money fields (Services, Cash tips, Card tips, Supplies), the take-home result, Save, then Breakdown. Secondary destinations live behind the overflow menu.

Secondary math is behind `Breakdown`.

History may show a compact last-4-weeks total, average week, and optional average hourly. It must not show charts, sparklines, or a metric dashboard.

## Ban list

- Beige
- Navy
- Blush backgrounds
- Pink body text used as the reading color
- Gold
- Pastel rainbow
- Black + neon
- Thin gray typography
- Tiny captions under 16px
- Hairline-only interaction states
- Dense dashboards
- Charts and sparklines
- Multi-column forms
- Gradients
- Decorative filler
- Trade-specific themes
- Claiming a custom font that is not bundled

## Accessibility

White on wine is the reading pair. Text on wine/dark surfaces is full `#FFFFFF`, not muted white for primary copy. Muted white is allowed only for secondary support lines at 16px+.

Warnings and errors use text/icon/shape in addition to color.

Dynamic Type should expand layouts vertically. Never truncate the take-home amount merely to preserve a fixed card height.

The hero result announces the take-home context plus the localized currency amount to screen readers.
