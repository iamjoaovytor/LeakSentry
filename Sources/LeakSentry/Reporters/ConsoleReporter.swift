public struct ConsoleReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        var lines = [
            "┌─────────────────────────────────────────",
            "│ ⚠️  LeakSentry — Leak Detected",
            "├─────────────────────────────────────────",
            "│ Type:        \(leak.objectType)",
            "│ Address:     \(leak.memoryAddress)",
            "│ Retain count: \(leak.retainCount)",
            "│ Detected at: \(leak.detectedAt)",
        ]
        for (key, value) in leak.context.sorted(by: { $0.key < $1.key }) {
            lines.append("│ \(key): \(value)")
        }
        lines.append("└─────────────────────────────────────────")
        print(lines.joined(separator: "\n"))
        #endif
    }

    public func resolved(_ leak: LeakReport) {
        #if DEBUG
        print("✅ LeakSentry — Resolved: \(leak.objectType) [\(leak.memoryAddress)]")
        #endif
    }
}
