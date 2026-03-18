import Testing
@testable import LeakSentrySwiftUI

// MARK: - Test fixtures

private class PlainObject {
    var name = "test"
    var count = 0
}

private class ObjectWithClosure {
    var onComplete: (() -> Void)?
    var name = "test"
}

private class ObjectWithOptionalClosure {
    var handler: ((Int) -> String)?
}

private class ObjectWithMultipleClosures {
    var onSuccess: (() -> Void)?
    var onFailure: ((Error) -> Void)?
}

private class ObjectWithObservationPrefix {
    // Simulates @Observable infrastructure fields that should be skipped
    var _$observationRegistrar = "registrar"
    var _$computed = { 42 }
}

// MARK: - Tests

@Suite
struct RetainCycleRiskTests {

    @Test func plainObjectHasNoRisk() {
        let obj = PlainObject()
        #expect(!hasRetainCycleRisk(obj))
    }

    @Test func objectWithClosureHasRisk() {
        let obj = ObjectWithClosure()
        obj.onComplete = { print("done") }
        #expect(hasRetainCycleRisk(obj))
    }

    @Test func objectWithNilClosureStillHasRisk() {
        let obj = ObjectWithClosure()
        // Even when nil, Mirror reflects the property *type* (Optional<() -> ()>),
        // which contains "->". This is correct — the property can hold a closure.
        #expect(hasRetainCycleRisk(obj))
    }

    @Test func objectWithOptionalClosureSetHasRisk() {
        let obj = ObjectWithOptionalClosure()
        obj.handler = { n in String(n) }
        #expect(hasRetainCycleRisk(obj))
    }

    @Test func objectWithMultipleClosuresDetected() {
        let obj = ObjectWithMultipleClosures()
        obj.onSuccess = {}
        #expect(hasRetainCycleRisk(obj))
    }

    @Test func observationPrefixFieldsAreSkipped() {
        let obj = ObjectWithObservationPrefix()
        // _$computed is a closure, but has _$ prefix so should be skipped
        #expect(!hasRetainCycleRisk(obj))
    }
}
