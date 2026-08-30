# Home header tap

Android already opens Settings when the header pay-context line is tapped.

iOS HomeView header should wrap the week + pay-context stack:

```swift
Button { showSettings = true } label: {
    VStack(spacing: 3) {
        Text(isCurrentWeek ? L("home.thisWeek", language: appLanguage) : formatWeekRange(activeWeekStart, language: appLanguage))
            .font(Brand.font(19))
        Text(payContext)
            .font(Brand.font(16))
            .foregroundStyle(.white)
    }
}
.buttonStyle(.plain)
```

Share fallback if the card image is nil:

```swift
let text = "\(L("home.youTookHome", language: appLanguage)) \(amount) · \(week)"
sharePayload = SharePayload(items: image == nil ? [text] : [image!, text])
```
