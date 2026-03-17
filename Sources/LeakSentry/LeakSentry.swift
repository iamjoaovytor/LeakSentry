import Foundation

public enum LeakSentry {
    @MainActor
    public static func start(configuration: Configuration = .default) {
        LeakDetector.shared.configure(with: configuration)
    }
}

public struct Configuration: Sendable {
    public var detectionDelay: TimeInterval
    public var reporters: [any LeakReporter]
    public var isEnabled: Bool
    public var ignoredClassNames: Set<String>

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
}
