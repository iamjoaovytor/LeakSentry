import LeakSentry

extension LeakSentry {
    /// Convenience for SwiftUI apps. Equivalent to `start()`.
    ///
    /// For UIKit + SwiftUI hybrid apps, prefer `startUIKit()` which also
    /// enables automatic UIViewController/UIView tracking via swizzling.
    @MainActor
    public static func startSwiftUI(configuration: Configuration = .default) {
        start(configuration: configuration)
    }
}
