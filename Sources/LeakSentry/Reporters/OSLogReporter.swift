import OSLog

public struct OSLogReporter: LeakReporter {
    private static let logger = Logger(subsystem: "com.leaksentry", category: "LeakDetector")

    public init() {}

    public func report(_ leak: LeakReport) {
        Self.logger.warning("⚠️ Leak detected: \(leak.objectType) — \(leak.objectDescription)")
    }

    public func resolved(_ leak: LeakReport) {
        Self.logger.info("✅ Leak resolved: \(leak.objectType) — \(leak.objectDescription)")
    }
}
