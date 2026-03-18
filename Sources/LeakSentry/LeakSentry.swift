import Foundation

public enum LeakSentry {
    @MainActor
    public static func start(configuration: Configuration = .default) {
        LeakDetector.shared.configure(with: configuration)
    }
}

public struct Configuration: Sendable {
    public let detectionDelay: TimeInterval
    public let reporters: [any LeakReporter]
    public let isEnabled: Bool
    public let ignoredClassNames: Set<String>

    public static let `default` = Configuration()

    public init(
        detectionDelay: TimeInterval = 1.5,
        reporters: [any LeakReporter] = [OSLogReporter()],
        isEnabled: Bool = true,
        ignoredClassNames: Set<String> = []
    ) {
        self.detectionDelay = detectionDelay
        self.reporters = reporters
        self.isEnabled = isEnabled
        self.ignoredClassNames = ignoredClassNames
    }

    public func adding(ignoredClassNames classes: Set<String>) -> Configuration {
        Configuration(
            detectionDelay: detectionDelay,
            reporters: reporters,
            isEnabled: isEnabled,
            ignoredClassNames: ignoredClassNames.union(classes)
        )
    }
}
