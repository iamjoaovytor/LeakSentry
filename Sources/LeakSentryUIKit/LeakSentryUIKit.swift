#if canImport(UIKit)
import UIKit
import LeakSentry

extension LeakSentry {
    /// Call this instead of `start()` when using UIKit.
    /// Sets up automatic UIViewController and UIView leak detection via swizzling.
    @MainActor
    public static func startUIKit(configuration: Configuration = .default) {
        start(configuration: configuration)
        LeakDetector.shared.addIgnoredClasses(defaultIgnoredViewControllerClasses)
        LeakDetector.shared.addIgnoredClasses(defaultIgnoredViewClasses)
        UIViewController.leaksentry_swizzleViewController()
        UIView.leaksentry_swizzleView()
    }
}
#endif
