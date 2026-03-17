import Foundation

@MainActor
package final class LeakDetector {
    package static let shared = LeakDetector()

    private var configuration: Configuration = .default

    private init() {}

    package func configure(with configuration: Configuration) {
        self.configuration = configuration
    }

    package func addIgnoredClasses(_ classes: Set<String>) {
        configuration.ignoredClassNames.formUnion(classes)
    }

    package func track(_ object: AnyObject, description: String) {
        guard configuration.isEnabled else { return }

        let typeName = String(describing: type(of: object))
        guard !configuration.ignoredClassNames.contains(typeName) else { return }

        let report = LeakReport(
            objectType: typeName,
            objectDescription: description
        )

        let delay = configuration.detectionDelay
        let reporters = configuration.reporters
        weak let ref = object

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard ref != nil else { return }

            reporters.forEach { $0.report(report) }

            Task { @MainActor in
                while ref != nil {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                reporters.forEach { $0.resolved(report.resolving()) }
            }
        }
    }
}
