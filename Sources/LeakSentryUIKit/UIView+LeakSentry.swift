#if canImport(UIKit)
import UIKit
import LeakSentry

extension UIView {
    static func leaksentry_swizzleView() {
        swizzleInstanceMethod(
            UIView.self,
            original: #selector(removeFromSuperview),
            swizzled: #selector(leaksentry_removeFromSuperview)
        )
    }

    @objc private func leaksentry_removeFromSuperview() {
        let hadSuperview = superview != nil
        leaksentry_removeFromSuperview() // calls original

        // Only track views explicitly removed from a parent,
        // not internal layout passes
        guard hadSuperview, window == nil else { return }

        let typeName = String(describing: type(of: self))
        guard !defaultIgnoredViewClasses.contains(typeName),
              !typeName.hasPrefix("_"),
              !typeName.hasPrefix("UI") else { return }

        Task { @MainActor in
            LeakDetector.shared.track(self, description: typeName)
        }
    }
}
#endif
