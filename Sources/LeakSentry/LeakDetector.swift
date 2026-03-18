import Foundation

@MainActor
package final class LeakDetector {
    package static let shared = LeakDetector()

    private var configuration: Configuration = .default
    private var pendingChecks = Set<ObjectIdentifier>()

    private init() {}

    package func configure(with configuration: Configuration) {
        self.configuration = configuration
        pendingChecks.removeAll()
    }

    package func addIgnoredClasses(_ classes: Set<String>) {
        configuration.ignoredClassNames.formUnion(classes)
    }

    package func reset() {
        configuration = .default
        pendingChecks.removeAll()
    }

    package func track(_ object: AnyObject, description: String, context: [String: String] = [:]) {
        guard configuration.isEnabled else { return }

        let typeName = String(describing: type(of: object))
        guard !configuration.ignoredClassNames.contains(typeName) else { return }

        let objectId = ObjectIdentifier(object)
        guard pendingChecks.insert(objectId).inserted else { return }

        let address = String(format: "%p", Int(bitPattern: Unmanaged.passUnretained(object).toOpaque()))

        let delay = configuration.detectionDelay
        let reporters = configuration.reporters
        let maxPolls = 10
        weak let ref = object

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            let report: LeakReport
            do {
                guard let leaked = ref else {
                    pendingChecks.remove(objectId)
                    return
                }
                report = LeakReport(
                    objectType: typeName,
                    objectDescription: description,
                    memoryAddress: address,
                    retainCount: CFGetRetainCount(leaked),
                    context: context
                )
            }

            reporters.forEach { $0.report(report) }

            var polls = 0
            while ref != nil, polls < maxPolls {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                polls += 1
            }

            if ref == nil {
                reporters.forEach { $0.resolved(report.resolving()) }
            }
            pendingChecks.remove(objectId)
        }
    }
}
