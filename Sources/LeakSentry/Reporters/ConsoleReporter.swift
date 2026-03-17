public struct ConsoleReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        print("""
        ┌─────────────────────────────────────────
        │ ⚠️  LeakSentry — Leak Detected
        ├─────────────────────────────────────────
        │ Type:        \(leak.objectType)
        │ Description: \(leak.objectDescription)
        │ Detected at: \(leak.detectedAt)
        │ ID:          \(leak.id)
        └─────────────────────────────────────────
        """)
        #endif
    }

    public func resolved(_ leak: LeakReport) {
        #if DEBUG
        print("✅ LeakSentry — Resolved: \(leak.objectType) [\(leak.id)]")
        #endif
    }
}
