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

        guard hadSuperview, window == nil else { return }

        let typeName = String(describing: type(of: self))
        guard !defaultIgnoredViewClasses.contains(typeName),
              !typeName.hasPrefix("_"),
              !typeName.hasPrefix("UI"),
              !Self.isSystemFrameworkView(self) else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            LeakDetector.shared.track(self, description: typeName)
        }
    }

    private static func isSystemFrameworkView(_ view: UIView) -> Bool {
        let bundle = Bundle(for: type(of: view))
        // Only track views from the app bundle, not system/framework views
        return bundle != Bundle.main
    }
}
#endif
