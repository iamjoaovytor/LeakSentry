public protocol LeakReporter: Sendable {
    func report(_ leak: LeakReport)
    func resolved(_ leak: LeakReport)
}
