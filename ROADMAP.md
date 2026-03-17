# LeakSentry — Development Roadmap

Swift package that detects memory leaks in UIViewControllers, UIViews, and SwiftUI ViewModels automatically.

**Platforms:** iOS 15+, tvOS 15+, macOS 12+ (Catalyst), visionOS 1+
**Swift:** 5.9+

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                   App Target                      │
│  LeakSentry.start() — called once at launch       │
└──────────┬──────────────────────┬────────────────┘
           │                      │
    ┌──────▼──────┐      ┌───────▼────────┐
    │ LeakSentry  │      │ LeakSentry     │
    │ UIKit       │      │ SwiftUI        │
    │             │      │                │
    │ Swizzling   │      │ LeakSentinel   │
    │ VC + View   │      │ protocol       │
    └──────┬──────┘      └───────┬────────┘
           │                      │
      ┌────▼──────────────────────▼────┐
      │        LeakSentry (Core)       │
      │                                │
      │  LeakDetector   — engine       │
      │  LeakReport     — model        │
      │  LeakReporter   — protocol     │
      │  OSLogReporter  — default      │
      └────────────────────────────────┘
```

### Three SPM Targets

| Target | Depends On | Purpose |
|--------|-----------|---------|
| `LeakSentry` | — | Core engine, reporter protocol, models |
| `LeakSentryUIKit` | `LeakSentry` | UIViewController/UIView swizzling |
| `LeakSentrySwiftUI` | `LeakSentry` | `LeakSentinel` protocol, Combine subscriber tracking |

---

## Detection Mechanism

### Core (shared)

```
Object registered → weak reference stored
                  ↓
       Exit event fires (dismiss, disappear, unsubscribe)
                  ↓
       Configurable delay (default 1.5s)
                  ↓
       Weak ref still alive? → LEAK detected → LeakReport
                  ↓
       Object eventually deallocates → resolution notified
```

### UIKit (automatic via swizzling)

Swizzled methods:
- `UIViewController.viewDidDisappear(_:)`
- `UIViewController.removeFromParent()`
- `UIViewController.dismiss(animated:completion:)`
- `UIView.removeFromSuperview()`
- `UIView.didMoveToWindow()` (window becomes nil)

This also catches `UIHostingController` — so SwiftUI views presented via navigation/sheets are monitored for free.

### SwiftUI ViewModels (semi-automatic via protocol)

```swift
class MyViewModel: ObservableObject, LeakSentinel { ... }
```

Detection via Combine subscriber counting:
1. `init` → registers with LeakDetector
2. `objectWillChange` gains subscriber → VM is "in use"
3. `objectWillChange` loses all subscribers → view disappeared
4. Delay → weak ref alive? → LEAK

---

## Milestones

### M0 — Project Setup
- [x] Git repository initialized
- [x] Development roadmap
- [ ] `Package.swift` with three targets (created via Xcode)
- [ ] `.gitignore` for Swift/Xcode
- [ ] Base folder structure (`Sources/`, `Tests/`)

### M1 — Core Engine
> The detection brain. No UI framework dependencies.

Files:
- `Sources/LeakSentry/LeakSentry.swift` — public config & `start()`
- `Sources/LeakSentry/LeakDetector.swift` — weak ref tracking, delay check, resolution
- `Sources/LeakSentry/LeakReport.swift` — model (object type, description, backtrace)
- `Sources/LeakSentry/LeakReporter.swift` — protocol for report destinations
- `Sources/LeakSentry/Reporters/OSLogReporter.swift` — default reporter via `os.log`
- `Sources/LeakSentry/Reporters/AssertionReporter.swift` — `assertionFailure` in DEBUG

Key decisions:
- `@MainActor` isolation for all detection logic
- `Task`-based delay instead of `DispatchQueue.asyncAfter`
- Thread-safe tracking via actor or `OSAllocatedUnfairLock`

Deliverable: `LeakDetector` can register/unregister objects and fire reports.

### M2 — UIKit Module
> Automatic detection for all UIViewControllers and UIViews.

Files:
- `Sources/LeakSentryUIKit/Swizzling.swift` — `method_exchangeImplementations` helpers
- `Sources/LeakSentryUIKit/UIViewController+LeakSentry.swift` — lifecycle swizzle
- `Sources/LeakSentryUIKit/UIView+LeakSentry.swift` — removal swizzle
- `Sources/LeakSentryUIKit/IgnoredClasses.swift` — system classes to skip

Key decisions:
- Swizzling activated on `LeakSentry.start()`, not on module load
- Ignore list for known Apple internal VCs/Views (keyboard, remote input, etc.)
- Associated object (`objc_setAssociatedObject`) to attach watcher per instance

Deliverable: import + `start()` = all VCs/Views monitored. Zero per-file code.

### M3 — SwiftUI Module
> Semi-automatic detection for ObservableObject ViewModels.

Files:
- `Sources/LeakSentrySwiftUI/LeakSentinel.swift` — protocol + default implementation
- `Sources/LeakSentrySwiftUI/SubscriberTracker.swift` — Combine subscription counting

`LeakSentinel` protocol:
```swift
public protocol LeakSentinel: AnyObject, ObservableObject {
    // No required members — all provided by extension
}

extension LeakSentinel {
    // Default init registration + objectWillChange wrapping
}
```

How subscriber tracking works:
```swift
// Wraps objectWillChange to intercept subscription lifecycle
objectWillChange
    .handleEvents(
        receiveSubscription: { _ in subscriberCount += 1 },
        receiveCancel: { subscriberCount -= 1 }
    )
// When count drops to 0 → start leak detection timer
```

Deliverable: adding `, LeakSentinel` to any ObservableObject enables monitoring.

### M4 — Debug Alerting
> Visual feedback during development.

- Alert overlay showing leaked object info (UIKit)
- Console-formatted report with object graph snapshot
- Optional screenshot of leaked view (UIKit only)
- Conditional compilation: `#if DEBUG` only

### M5 — Tests
> Validate detection accuracy, avoid false positives.

Test scenarios:
- VC dismissed and deallocated → no report (true negative)
- VC dismissed but retained by closure → report (true positive)
- System VC in ignore list → no report (filtered)
- ObservableObject with active subscribers → no report
- ObservableObject with zero subscribers, still alive → report
- Resolution callback when late dealloc happens
- Configurable delay respected

### M6 — Documentation & Release
> Ship it.

- README with setup instructions, examples, common leak causes
- DocC documentation for public API
- Example project (UIKit + SwiftUI app with intentional leaks)
- GitHub release v0.1.0
- Swift Package Index submission

---

## Public API Surface (Target)

```swift
// --- Core ---
public enum LeakSentry {
    static func start(configuration: Configuration = .default)
}

public struct Configuration {
    var detectionDelay: TimeInterval    // default 1.5
    var reporters: [LeakReporter]       // default [OSLogReporter()]
    var isEnabled: Bool                 // default true, respects DEBUG
    var ignoredClassNames: Set<String>  // custom additions
}

public protocol LeakReporter {
    func report(_ leak: LeakReport)
    func resolved(_ leak: LeakReport)
}

public struct LeakReport {
    let objectType: String
    let objectDescription: String
    let detectedAt: Date
    let isResolved: Bool
}

// --- SwiftUI ---
public protocol LeakSentinel: AnyObject, ObservableObject {}
```

---

## Open Questions

1. **Macro vs Protocol for SwiftUI?** — Macro (`@Tracked`) is more ergonomic but requires Swift 5.9 macro infrastructure. Protocol (`: LeakSentinel`) is simpler. Start with protocol, add macro later.
2. **visionOS support?** — UIKit exists on visionOS. Worth adding to platform list.
3. **Minimum iOS version?** — iOS 15 for `Task` async. iOS 14 possible with `DispatchQueue` fallback, but adds complexity.
4. **Production reporter examples?** — Ship with OSLog + Assertion. Provide example code for Firebase Crashlytics, Sentry, Datadog as recipes in docs (not as dependencies).
