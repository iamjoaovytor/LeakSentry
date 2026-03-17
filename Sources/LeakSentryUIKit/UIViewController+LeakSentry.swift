#if canImport(UIKit)
import UIKit
import LeakSentry

extension UIViewController {
    static func leaksentry_swizzleViewController() {
        swizzleInstanceMethod(
            UIViewController.self,
            original: #selector(viewDidDisappear(_:)),
            swizzled: #selector(leaksentry_viewDidDisappear(_:))
        )
    }

    @objc private func leaksentry_viewDidDisappear(_ animated: Bool) {
        leaksentry_viewDidDisappear(animated)

        guard isMovingFromParent || isBeingDismissed else { return }

        let typeName = String(describing: type(of: self))
        guard !defaultIgnoredViewControllerClasses.contains(typeName),
              !typeName.hasPrefix("_") else { return }

        Task { @MainActor in
            LeakDetector.shared.track(self, description: typeName)
        }
    }
}
#endif
