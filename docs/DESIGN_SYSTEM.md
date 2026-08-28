# Salon Booth Math Design System

## Character

Bold, grown-up, easy to read, beauty-industry friendly, and deliberately simple for a tired or overloaded user.

Pacing can feel immediate, but there are no mascots, streaks, confetti, childish rewards, or game chrome.

## Type

Brand face: **native system rounded** on both platforms. iOS uses SwiftUI's rounded system design; Android uses the platform system sans with bold/extrabold weights. Do not claim or require a bundled custom font unless the font asset is actually shipped.

Do not use Inter or serif faces.

- Chrome/week label: 18px / 700
- Field labels: 18-20px / 700
- Field numbers: 28-32px / 800
- Section heads: 22-28px / 800
- Take-home label: 18px / 700
- Take-home amount: 52-64px / 800, line-height 1.0, tabular figures
- Breakdown rows: 18px / 700
- Buttons: 18-20px / 800

Never go below 16px. Do not use 300 or 400 weights for visible app copy.

## Colors

- Page/cards: `#FFFFFF`
- Ink: `#0B1220`
- Berry: `#4A1835`
- Text on berry: `#FFFFFF`
- Hot pink: `#FF3D6E`
- Warning: `#C2410C`
- Error: `#B42318`
- Dividers: ink at 8% opacity

Rule: **Berry is the salon dark. Pink is the tap. Ink does the reading.**

Hot pink is for primary buttons, focus rings, the 4px header crown, and tiny decorative accents only. Do not use it for paragraphs, money, headings, or small labels.

## Controls

- Height: 56-64px
- Radius: 16-20px
- Large internal padding
- Fields: true white with a clearly visible ink border; active fields use a stronger hot-pink focus edge
- Focus must not depend on low-contrast color alone
- Selected trade/pay tile: berry fill, white icon and label, optional pink ring
- Unselected tile: white, ink icon and label

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

Home is a single vertical flow: berry header with 4px hot-pink crown, four money fields (Services, Cash tips, Card tips, Supplies), the take-home result, Save, then Breakdown. Secondary destinations live behind the overflow menu.

Secondary math is behind `Breakdown`.

## Ban list

- Beige
- Navy
- Blush backgrounds
- Pink body text/headlines
- Gold
- Pastel rainbow
- Black + neon
- Thin gray typography
- Tiny captions
- Hairline-only interaction states
- Dense dashboards
- Metric card grids
- Multi-column forms
- Charts on launch
- Gradients
- Decorative filler
- Trade-specific themes

## Accessibility

Ink and berry are the reading colors. White is the primary surface. Text on berry/dark surfaces is full `#FFFFFF`, not muted white.

Warnings and errors use text/icon/shape in addition to color.

Dynamic Type should expand layouts vertically. Never truncate the take-home amount merely to preserve a fixed card height.

The hero result announces the take-home context plus the localized currency amount to screen readers.
