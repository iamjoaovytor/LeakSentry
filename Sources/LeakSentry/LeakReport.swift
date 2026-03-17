import Foundation

public struct LeakReport: Sendable {
    public let id: UUID
    public let objectType: String
    public let objectDescription: String
    public let detectedAt: Date
    public let isResolved: Bool

    init(
        id: UUID = UUID(),
        objectType: String,
        objectDescription: String,
        detectedAt: Date = Date(),
        isResolved: Bool = false
    ) {
        self.id = id
        self.objectType = objectType
        self.objectDescription = objectDescription
        self.detectedAt = detectedAt
        self.isResolved = isResolved
    }

    func resolving() -> LeakReport {
        LeakReport(
            id: id,
            objectType: objectType,
            objectDescription: objectDescription,
            detectedAt: detectedAt,
            isResolved: true
        )
    }
}
