# LeakSentry — Implementation Prompt

Copy and paste this entire prompt into your AI assistant to get step-by-step guidance on integrating LeakSentry into your iOS project.

---

## Prompt

```
I want to integrate LeakSentry into my iOS project. LeakSentry is a Swift Package that automatically detects memory leaks at runtime for UIViewControllers, UIViews, and SwiftUI ViewModels.

Repository: https://github.com/iamjoaovytor/LeakSentry

Here is everything you need to know about the package:

## What it does

LeakSentry monitors objects (view controllers, views, view models) after they should have been deallocated. If an object is still alive after a configurable delay, it reports a memory leak with details like type name, memory address, retain count, and context (parent VC, nav stack, trigger).

It also tracks resolution — if the leaked object eventually deallocates, it notifies that the leak was resolved.

## Package structure

Three modules — import only what you need:

| Module | Purpose |
|---|---|
| `LeakSentry` | Core detection engine, reporters, configuration |
| `LeakSentryUIKit` | Auto-detection for UIViewController and UIView via method swizzling |
| `LeakSentrySwiftUI` | Manual tracking for SwiftUI ViewModels via `.trackLeaks(for:)` modifier |

## Installation

Add via Swift Package Manager:
1. Xcode → File → Add Package Dependencies
2. URL: https://github.com/iamjoaovytor/LeakSentry
3. Select the modules you need (LeakSentryUIKit for UIKit, LeakSentrySwiftUI for SwiftUI, or both)

Requirements: iOS 15+, tvOS 15+, macOS 12+, visionOS 1+, Swift 5.9+

## Setup — UIKit

Call once at app launch. All UIViewController and UIView subclasses are automatically monitored.

```swift
import LeakSentryUIKit

// In AppDelegate or @main App struct
LeakSentry.startUIKit(
    configuration: Configuration(
        detectionDelay: 1.5,
        reporters: [OSLogReporter(), ConsoleReporter(), AlertReporter()],
        isEnabled: true,
        ignoredClassNames: []
    )
)
```

For SceneDelegate / SwiftUI App struct, wrap in `MainActor.assumeIsolated { }` if calling from `init()`.

## Setup — SwiftUI

1. Start the engine (once, at launch):

```swift
import LeakSentrySwiftUI

// In your @main App init
LeakSentry.startSwiftUI()
```

2. Adopt `LeakSentinel` protocol on your ViewModel:

```swift
// With ObservableObject
class ProfileViewModel: ObservableObject, LeakSentinel {
    @Published var name = ""
}

// With @Observable (iOS 17+)
@Observable
class ProfileViewModel: LeakSentinel {
    var name = ""
}
```

3. Add `.trackLeaks(for:)` on the View:

```swift
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel() // or @State for @Observable

    var body: some View {
        Text(viewModel.name)
            .trackLeaks(for: viewModel)
    }
}
```

## Setup — Hybrid UIKit + SwiftUI

Use `startUIKit()` — it covers both UIKit auto-detection and allows SwiftUI manual tracking.

## Available reporters

| Reporter | Where | Behavior |
|---|---|---|
| `OSLogReporter()` | Core | Logs to `os.log` (visible in Console.app) — default |
| `ConsoleReporter()` | Core | Formatted table printed to Xcode console (DEBUG only) |
| `AssertionReporter()` | Core | Crashes with `assertionFailure` in DEBUG |
| `AlertReporter()` | UIKit module | Shows a UIAlertController popup in DEBUG |

You can combine multiple reporters. You can also create custom reporters:

```swift
struct CrashlyticsReporter: LeakReporter {
    func report(_ leak: LeakReport) {
        // Log to Crashlytics, Sentry, Datadog, etc.
        // leak.objectType, leak.memoryAddress, leak.retainCount, leak.context
    }
    func resolved(_ leak: LeakReport) {
        // Optional: log resolution
    }
}
```

## Configuration options

| Option | Default | Description |
|---|---|---|
| `detectionDelay` | 1.5s | How long to wait after disappear before checking |
| `reporters` | `[OSLogReporter()]` | Array of reporters to notify |
| `isEnabled` | `true` | Kill switch (set `false` for production) |
| `ignoredClassNames` | `[]` | Class names to skip (e.g. `["MyBaseVC"]`) |

## How detection works

### UIKit (automatic)
- Method swizzling on `viewDidDisappear(_:)` and `removeFromSuperview()`
- Checks `isMovingFromParent`, `isBeingDismissed`, or parent being dismissed
- Filters out system/framework classes automatically (prefix `_`, `UI`, non-main-bundle views)
- After the delay, if the object is still alive → leak reported

### SwiftUI (manual via modifier)
- `.trackLeaks(for:)` uses `onDisappear` with a 300ms grace period
- Grace period prevents false positives from NavigationStack (where `onDisappear` fires on push)
- If the view doesn't reappear within 300ms, the ViewModel is tracked for leaks
- After the configurable delay (default 1.5s), if still alive → leak reported

## What to do now

Based on my project, please:

1. **Identify my project type** (UIKit, SwiftUI, or hybrid) by looking at my code
2. **Add the SPM dependency** to my project
3. **Configure LeakSentry** at app launch with appropriate reporters
4. **Add leak tracking** to my ViewModels (SwiftUI) — adopt `LeakSentinel` and add `.trackLeaks(for:)` to Views
5. **Test it works** by creating a deliberate leak (e.g., strong self capture in a closure stored as a property) and verifying the report appears in the console
6. **Ignore known false positives** by adding class names to `ignoredClassNames` if needed

Start by searching my project for the entry point (AppDelegate, SceneDelegate, or @main App struct) and existing ViewModels.
```
