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
        let viewBundle = Bundle(for: type(of: view))
        guard viewBundle != Bundle.main else { return false }
        // Statically linked SPM packages resolve to Bundle.main (handled above).
        // For dynamic frameworks, exclude Apple system paths but include
        // third-party frameworks embedded inside the app bundle.
        let path = viewBundle.bundlePath
        return path.hasPrefix("/System/") || path.hasPrefix("/usr/")
    }
}
#endif
