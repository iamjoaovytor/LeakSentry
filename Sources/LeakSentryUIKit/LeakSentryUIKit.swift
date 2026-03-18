#if canImport(UIKit)
import UIKit
import LeakSentry

extension LeakSentry {
    @MainActor private static var isUIKitStarted = false

    /// Call this instead of `start()` when using UIKit.
    /// Sets up automatic UIViewController and UIView leak detection via swizzling.
    ///
    /// Safe to call multiple times — subsequent calls are no-ops.
    @MainActor
    public static func startUIKit(configuration: Configuration = .default) {
        guard !isUIKitStarted else { return }
        isUIKitStarted = true

        start(configuration: configuration)
        LeakDetector.shared.addIgnoredClasses(defaultIgnoredViewControllerClasses)
        LeakDetector.shared.addIgnoredClasses(defaultIgnoredViewClasses)
        UIViewController.leaksentry_swizzleViewController()
        UIView.leaksentry_swizzleView()
    }
}
#endif
