public struct ConsoleReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        var rows = [
            ("Type", leak.objectType),
            ("Address", leak.memoryAddress),
            ("Detected", "\(leak.detectedAt)"),
        ]
        for (key, value) in leak.context.sorted(by: { $0.key < $1.key }) {
            rows.append((key, value))
        }

        let maxKey = rows.map(\.0.count).max() ?? 0

        var lines = [
            "┌──────────────────────────────────────────────",
            "│  LeakSentry — Leak Detected",
            "├──────────────────────────────────────────────",
        ]
        for (key, value) in rows {
            let padded = key.padding(toLength: maxKey, withPad: " ", startingAt: 0)
            lines.append("│  \(padded)  \(value)")
        }
        lines.append("└──────────────────────────────────────────────")
        print(lines.joined(separator: "\n"))
        #endif
    }

    public func resolved(_ leak: LeakReport) {
        #if DEBUG
        print("✅ LeakSentry — Resolved: \(leak.objectType) [\(leak.memoryAddress)]")
        #endif
    }
}
