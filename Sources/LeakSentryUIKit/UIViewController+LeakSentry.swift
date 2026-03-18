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
        guard !typeName.hasPrefix("_") else { return }

        var context: [String: String] = [:]
        if let parent = parent {
            context["Parent"] = String(describing: type(of: parent))
        }
        if let nav = navigationController {
            let stack = nav.viewControllers.map { String(describing: type(of: $0)) }
            context["Nav stack"] = stack.joined(separator: " → ")
        }
        if isBeingDismissed {
            context["Trigger"] = "dismissed"
        } else if isMovingFromParent {
            context["Trigger"] = "removed from parent"
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            LeakDetector.shared.track(self, description: typeName, context: context)
        }
    }
}
#endif
