#if canImport(UIKit)
import UIKit
import LeakSentry

/// Presents a native UIAlertController when a leak is detected.
/// Only active in DEBUG builds.
public struct AlertReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        Task { @MainActor in
            guard let vc = topmostViewController() else { return }

            var details = """
            \(leak.objectType)
            \(leak.memoryAddress)  rc: \(leak.retainCount)
            """

            for (key, value) in leak.context.sorted(by: { $0.key < $1.key }) {
                details += "\n\(key): \(value)"
            }

            let alert = UIAlertController(
                title: "Memory Leak Detected",
                message: details,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                UIPasteboard.general.string = details
            })
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))

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
