# LeakSentry

Automatic memory leak detection for UIViewControllers, UIViews, and SwiftUI ViewModels.

---

## Installation

Add the package via Swift Package Manager:

```
https://github.com/iamjoaovytor/LeakSentry
```

Choose the module for your stack:

| Module | Use when |
|---|---|
| `LeakSentry` | Core only (custom integration) |
| `LeakSentryUIKit` | UIKit app |
| `LeakSentrySwiftUI` | SwiftUI app |

---

## Usage

### UIKit

Call once at launch — all `UIViewController` and `UIView` subclasses are monitored automatically via swizzling.

```swift
import LeakSentryUIKit

// AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    LeakSentry.startUIKit()
    return true
}
```

### SwiftUI

1. Adopt `LeakSentinel` on any `ObservableObject` ViewModel:

```swift
import LeakSentrySwiftUI

class ProfileViewModel: ObservableObject, LeakSentinel { ... }
```

2. Add `.trackLeaks(for:)` to the View that owns it:

```swift
ProfileView()
    .trackLeaks(for: viewModel)
```

Detection triggers automatically when the view disappears.

---

## Configuration

```swift
LeakSentry.startUIKit(
    configuration: Configuration(
        detectionDelay: 1.5,              // seconds after disappear to check (default: 1.5)
        reporters: [OSLogReporter(),      // where to send leak reports
                    ConsoleReporter()],
        isEnabled: true,                  // set false in production if needed
        ignoredClassNames: ["MyBaseVC"]   // additional classes to skip
    )
)
```

---

## Reporters

| Reporter | Module | Output |
|---|---|---|
| `OSLogReporter` | Core | `os.log` (default) |
| `ConsoleReporter` | Core | Formatted print to console |
| `AssertionReporter` | Core | `assertionFailure` in DEBUG |
| `AlertReporter` | UIKit | `UIAlertController` popup in DEBUG |

Custom reporter:

```swift
struct MyReporter: LeakReporter {
    func report(_ leak: LeakReport) {
        // send to Crashlytics, Sentry, Datadog, etc.
    }
    func resolved(_ leak: LeakReport) { }
}
```

---

## Requirements

- iOS 15+ / tvOS 15+ / macOS 12+ / visionOS 1+
- Swift 5.9+

---

## License

MIT
