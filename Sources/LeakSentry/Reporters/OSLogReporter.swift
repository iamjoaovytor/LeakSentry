import OSLog

public struct OSLogReporter: LeakReporter {
    private static let logger = Logger(subsystem: "com.leaksentry", category: "LeakDetector")

    public init() {}

    public func report(_ leak: LeakReport) {
        Self.logger.warning("⚠️ Leak: \(leak.objectType) at \(leak.memoryAddress)")
    }

    public func resolved(_ leak: LeakReport) {
        Self.logger.info("✅ Resolved: \(leak.objectType) [\(leak.memoryAddress)]")
    }
}
