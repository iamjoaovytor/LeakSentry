#if canImport(UIKit)
import UIKit
import LeakSentry

/// Presents a detailed alert overlay when a leak is detected.
/// Only active in DEBUG builds.
public struct AlertReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        Task { @MainActor in
            guard let window = keyWindow() else { return }

            let overlay = LeakAlertOverlay(report: leak)
            overlay.tag = 9999
            overlay.alpha = 0
            window.addSubview(overlay)

            NSLayoutConstraint.activate([
                overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
                overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
                overlay.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ])

            UIView.animate(withDuration: 0.3) {
                overlay.alpha = 1
            }
        }
        #endif
    }

    public func resolved(_ leak: LeakReport) {
        #if DEBUG
        Task { @MainActor in
            guard let window = keyWindow(),
                  let overlay = window.viewWithTag(9999) as? LeakAlertOverlay,
                  overlay.reportId == leak.id else { return }

            overlay.markResolved()
        }
        #endif
    }
}

// MARK: - Overlay View

@MainActor
private final class LeakAlertOverlay: UIView {
    let reportId: UUID
    private let dismissButton = UIButton(type: .system)

    init(report: LeakReport) {
        self.reportId = report.id
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildUI(report: report)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func buildUI(report: LeakReport) {
        backgroundColor = UIColor.systemRed.withAlphaComponent(0.95)
        layer.cornerRadius = 14
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])

        // Header
        let header = makeLabel(
            "⚠️ Memory Leak Detected",
            font: .systemFont(ofSize: 15, weight: .bold)
        )
        stack.addArrangedSubview(header)

        // Type + Address
        let typeRow = makeLabel(
            "\(report.objectType)  \(report.memoryAddress)",
            font: .monospacedSystemFont(ofSize: 14, weight: .semibold)
        )
        stack.addArrangedSubview(typeRow)

        // Retain count
        let rcRow = makeLabel(
            "Retain count: \(report.retainCount)",
            font: .monospacedSystemFont(ofSize: 12, weight: .regular)
        )
        rcRow.alpha = 0.85
        stack.addArrangedSubview(rcRow)

        // Context rows
        for (key, value) in report.context.sorted(by: { $0.key < $1.key }) {
            let row = makeLabel(
                "\(key): \(value)",
                font: .monospacedSystemFont(ofSize: 12, weight: .regular)
            )
            row.alpha = 0.85
            stack.addArrangedSubview(row)
        }

        // Hint
        let hint = makeLabel(
            "Check for strong self in closures, non-weak delegates, or retained timers.",
            font: .systemFont(ofSize: 11, weight: .regular)
        )
        hint.alpha = 0.7
        stack.setCustomSpacing(10, after: stack.arrangedSubviews[stack.arrangedSubviews.count - 2])
        stack.addArrangedSubview(hint)

        // Dismiss
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        dismissButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        dismissButton.layer.cornerRadius = 8
        dismissButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        stack.setCustomSpacing(12, after: hint)
        stack.addArrangedSubview(dismissButton)
    }

    func markResolved() {
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5) {
                self.alpha = 0
            } completion: { _ in
                self.removeFromSuperview()
            }
        }
    }

    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    private func makeLabel(_ text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }
}

// MARK: - Helpers

@MainActor
private func keyWindow() -> UIWindow? {
    UIApplication.shared
        .connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
}
#endif
