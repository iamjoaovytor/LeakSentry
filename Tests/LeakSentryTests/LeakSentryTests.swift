import Testing
import Foundation
@testable import LeakSentry

// MARK: - Spy

final class SpyReporter: LeakReporter, @unchecked Sendable {
    var reports: [LeakReport] = []
    var resolutions: [LeakReport] = []

    func report(_ leak: LeakReport) { reports.append(leak) }
    func resolved(_ leak: LeakReport) { resolutions.append(leak) }
}

// MARK: - Fake objects

private class FakeObject {}
private class IgnoredObject {}

// MARK: - Tests

@Suite(.serialized)
@MainActor
struct LeakDetectorTests {

    // MARK: Helpers

    func makeConfig(delay: TimeInterval = 0.1, spy: SpyReporter, ignored: Set<String> = [], enabled: Bool = true) -> Configuration {
        Configuration(detectionDelay: delay, reporters: [spy], isEnabled: enabled, ignoredClassNames: ignored)
    }

    // MARK: True negative — object deallocates before delay

    @Test func noReportWhenObjectDeallocates() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy))

        do {
            let obj = FakeObject()
            LeakDetector.shared.track(obj, description: "FakeObject")
        } // obj deallocates here

        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s > 0.1s delay
        #expect(spy.reports.isEmpty)
    }

    // MARK: True positive — object retained → report fires

    @Test func reportWhenObjectIsRetained() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy))

        var retained: FakeObject? = FakeObject()
        LeakDetector.shared.track(retained!, description: "FakeObject")

        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(spy.reports.count == 1)
        #expect(spy.reports.first?.objectType == "FakeObject")

        retained = nil
    }

    // MARK: Ignore list — filtered class → no report

    @Test func noReportForIgnoredClass() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy, ignored: ["IgnoredObject"]))

        var retained: IgnoredObject? = IgnoredObject()
        LeakDetector.shared.track(retained!, description: "IgnoredObject")

        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(spy.reports.isEmpty)

        retained = nil
    }

    // MARK: isEnabled = false → no tracking

    @Test func noReportWhenDisabled() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy, enabled: false))

        var retained: FakeObject? = FakeObject()
        LeakDetector.shared.track(retained!, description: "FakeObject")

        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(spy.reports.isEmpty)

        retained = nil
    }

    // MARK: Custom delay is respected

    @Test func customDelayIsRespected() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(delay: 0.4, spy: spy))

        var retained: FakeObject? = FakeObject()
        LeakDetector.shared.track(retained!, description: "FakeObject")

        // Before delay: no report yet
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s < 0.4s
        #expect(spy.reports.isEmpty)

        // After delay: report fires
        try await Task.sleep(nanoseconds: 400_000_000) // total 0.55s > 0.4s
        #expect(spy.reports.count == 1)

        retained = nil
    }

    // MARK: Resolution — leaked object eventually deallocates

    @Test func resolutionFiredWhenLeakedObjectDeallocates() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy))

        var retained: FakeObject? = FakeObject()
        LeakDetector.shared.track(retained!, description: "FakeObject")

        // Wait for leak detection
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(spy.reports.count == 1)

        // Release → resolution should fire
        retained = nil
        try await Task.sleep(nanoseconds: 700_000_000)
        #expect(spy.resolutions.count == 1)
        #expect(spy.resolutions.first?.isResolved == true)
    }

    // MARK: Report fields are correct

    @Test func reportContainsCorrectMetadata() async throws {
        let spy = SpyReporter()
        LeakDetector.shared.configure(with: makeConfig(spy: spy))

        let before = Date()
        var retained: FakeObject? = FakeObject()
        LeakDetector.shared.track(retained!, description: "test-description")

        try await Task.sleep(nanoseconds: 300_000_000)
        let report = try #require(spy.reports.first)
        #expect(report.objectType == "FakeObject")
        #expect(report.objectDescription == "test-description")
        #expect(report.detectedAt >= before)
        #expect(report.isResolved == false)

        retained = nil
    }
}
