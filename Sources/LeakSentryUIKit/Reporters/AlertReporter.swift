#if canImport(UIKit)
import UIKit
import LeakSentry

/// Presents a UIAlertController when a leak is detected.
/// Only active in DEBUG builds.
public struct AlertReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        Task { @MainActor in
            guard let vc = topmostViewController() else { return }
            let alert = UIAlertController(
                title: "⚠️ Memory Leak",
                message: "\(leak.objectType)\n\(leak.objectDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            vc.present(alert, animated: true)
        }
        #endif
    }

    public func resolved(_ leak: LeakReport) {}
}

@MainActor
private func topmostViewController() -> UIViewController? {
    let root = UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController

    return topmost(from: root)
}

@MainActor
private func topmost(from vc: UIViewController?) -> UIViewController? {
    if let presented = vc?.presentedViewController {
        return topmost(from: presented)
    }
    if let nav = vc as? UINavigationController {
        return topmost(from: nav.visibleViewController)
    }
    if let tab = vc as? UITabBarController {
        return topmost(from: tab.selectedViewController)
    }
    return vc
}
#endif
