# LeakSentry — Implementation Prompt

> Copy the text block below and paste it into your AI assistant.

```
I want to integrate LeakSentry into my iOS project. LeakSentry is a Swift Package that automatically detects memory leaks at runtime for UIViewControllers, UIViews, and SwiftUI ViewModels. Repository: https://github.com/iamjoaovytor/LeakSentry

Here is everything you need to know about the package:

WHAT IT DOES: LeakSentry monitors objects (view controllers, views, view models) after they should have been deallocated. If an object is still alive after a configurable delay, it reports a memory leak with details like type name, memory address, retain count, and context (parent VC, nav stack, trigger). It also tracks resolution — if the leaked object eventually deallocates, it notifies that the leak was resolved.

PACKAGE STRUCTURE — three modules, import only what you need:
- "LeakSentry" — Core detection engine, reporters, configuration
- "LeakSentryUIKit" — Auto-detection for UIViewController and UIView via method swizzling
- "LeakSentrySwiftUI" — Manual tracking for SwiftUI ViewModels via .trackLeaks(for:) modifier

INSTALLATION: Add via Swift Package Manager: Xcode → File → Add Package Dependencies → URL: https://github.com/iamjoaovytor/LeakSentry → Select the modules you need (LeakSentryUIKit for UIKit, LeakSentrySwiftUI for SwiftUI, or both). Requirements: iOS 15+, tvOS 15+, macOS 12+, visionOS 1+, Swift 5.9+.

SETUP FOR UIKIT: Call once at app launch. All UIViewController and UIView subclasses are automatically monitored via swizzling:

import LeakSentryUIKit
LeakSentry.startUIKit(
    configuration: Configuration(
        detectionDelay: 1.5,
        reporters: [OSLogReporter(), ConsoleReporter(), AlertReporter()],
        isEnabled: true,
        ignoredClassNames: []
    )
)

For SceneDelegate or SwiftUI App struct, wrap in MainActor.assumeIsolated { } if calling from init().

SETUP FOR SWIFTUI: First start the engine once at launch: LeakSentry.startSwiftUI(). Then adopt LeakSentinel protocol on your ViewModel. It works with both ObservableObject and @Observable (iOS 17+):

// With ObservableObject
class ProfileViewModel: ObservableObject, LeakSentinel {
    @Published var name = ""
}

// With @Observable (iOS 17+)
@Observable
class ProfileViewModel: LeakSentinel {
    var name = ""
}

Then add .trackLeaks(for:) on the View that owns the ViewModel:

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    var body: some View {
        Text(viewModel.name)
            .trackLeaks(for: viewModel)
    }
}

For @Observable ViewModels, use @State instead of @StateObject.

SETUP FOR HYBRID UIKIT + SWIFTUI: Use startUIKit() — it covers both UIKit auto-detection and allows SwiftUI manual tracking.

AVAILABLE REPORTERS:
- OSLogReporter() [Core module] — Logs to os.log, visible in Console.app. This is the default.
- ConsoleReporter() [Core module] — Formatted table printed to Xcode console (DEBUG only).
- AssertionReporter() [Core module] — Crashes with assertionFailure in DEBUG.
- AlertReporter() [UIKit module] — Shows a UIAlertController popup in DEBUG.

You can combine multiple reporters. You can also create custom ones by conforming to LeakReporter:

struct CrashlyticsReporter: LeakReporter {
    func report(_ leak: LeakReport) {
        // leak.objectType, leak.memoryAddress, leak.retainCount, leak.context
    }
    func resolved(_ leak: LeakReport) { }
}

CONFIGURATION OPTIONS:
- detectionDelay (default 1.5s) — How long to wait after disappear before checking.
- reporters (default [OSLogReporter()]) — Array of reporters to notify.
- isEnabled (default true) — Kill switch, set false for production if needed.
- ignoredClassNames (default []) — Class names to skip, e.g. ["MyBaseVC"].

HOW DETECTION WORKS — UIKit is automatic: method swizzling on viewDidDisappear(_:) and removeFromSuperview(). It checks isMovingFromParent, isBeingDismissed, or if a parent is being dismissed. System/framework classes are filtered out automatically. After the delay, if the object is still alive, a leak is reported.

HOW DETECTION WORKS — SwiftUI is manual via the .trackLeaks(for:) modifier. It uses onDisappear with a 300ms grace period to prevent false positives from NavigationStack (where onDisappear fires on push but the view is still in the stack). If the view doesn't reappear within 300ms, the ViewModel is tracked. After the configurable delay (default 1.5s), if still alive, a leak is reported.

WHAT TO DO NOW — Based on my project, please:
1. Identify my project type (UIKit, SwiftUI, or hybrid) by looking at my code.
2. Add the SPM dependency to my project.
3. Configure LeakSentry at app launch with appropriate reporters.
4. Add leak tracking to my ViewModels (SwiftUI) — adopt LeakSentinel and add .trackLeaks(for:) to Views.
5. Test it works by creating a deliberate leak (e.g. strong self capture in a closure stored as a property) and verifying the report appears in the console.
6. Ignore known false positives by adding class names to ignoredClassNames if needed.

Start by searching my project for the entry point (AppDelegate, SceneDelegate, or @main App struct) and existing ViewModels.
```
