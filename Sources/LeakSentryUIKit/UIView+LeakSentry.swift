#if canImport(UIKit)
import UIKit
import LeakSentry

extension UIView {
    static func leaksentry_swizzleView() {
        swizzleInstanceMethod(
            UIView.self,
            original: #selector(didMoveToWindow),
            swizzled: #selector(leaksentry_didMoveToWindow)
        )
    }

    @objc private func leaksentry_didMoveToWindow() {
        leaksentry_didMoveToWindow()

        guard window == nil, superview == nil else { return }

        let typeName = String(describing: type(of: self))
        guard !defaultIgnoredViewClasses.contains(typeName),
              !typeName.hasPrefix("_") else { return }

        Task { @MainActor in
            LeakDetector.shared.track(self, description: typeName)
        }
    }
}
#endif
