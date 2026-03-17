public struct AssertionReporter: LeakReporter {
    public init() {}

    public func report(_ leak: LeakReport) {
        #if DEBUG
        assertionFailure("LeakSentry: \(leak.objectType) leaked — \(leak.objectDescription)")
        #endif
    }

    public func resolved(_ leak: LeakReport) {}
}
