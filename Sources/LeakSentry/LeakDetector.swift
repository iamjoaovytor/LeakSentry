import Foundation
import ObjectiveC

/// Attached to tracked objects via `objc_setAssociatedObject`.
/// When the object is deallocated, the canceller's `deinit` fires and
/// cancels the monitoring task — preventing false-positive reports
/// for objects that SwiftUI's `@State` releases late.
private final class DeallocCanceller: NSObject, @unchecked Sendable {
    let task: Task<Void, Never>
    init(task: Task<Void, Never>) {
        self.task = task
        super.init()
    }
    deinit { task.cancel() }
}

private nonisolated(unsafe) var leakCheckKey: UInt8 = 0

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
        configuration = configuration.adding(ignoredClassNames: classes)
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
        let maxPolls = 30
        weak let ref = object

        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard !Task.isCancelled, ref != nil else {
                pendingChecks.remove(objectId)
                return
            }

            let report = LeakReport(
                objectType: typeName,
                objectDescription: description,
                memoryAddress: address,
                context: context
            )

            reporters.forEach { $0.report(report) }

            var polls = 0
            while ref != nil, !Task.isCancelled, polls < maxPolls {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                polls += 1
            }

            if ref == nil || Task.isCancelled {
                reporters.forEach { $0.resolved(report.resolving()) }
            }
            pendingChecks.remove(objectId)
        }

        // When the object is deallocated (no retain cycle), the canceller's
        // deinit immediately cancels the monitoring task.
        objc_setAssociatedObject(object, &leakCheckKey, DeallocCanceller(task: task), .OBJC_ASSOCIATION_RETAIN)
    }
}
