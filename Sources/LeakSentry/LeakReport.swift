import Foundation

public struct LeakReport: Sendable {
    public let id: UUID
    public let objectType: String
    public let objectDescription: String
    public let memoryAddress: String
    public let retainCount: Int
    public let context: [String: String]
    public let detectedAt: Date
    public let isResolved: Bool

    init(
        id: UUID = UUID(),
        objectType: String,
        objectDescription: String,
        memoryAddress: String,
        retainCount: Int,
        context: [String: String] = [:],
        detectedAt: Date = Date(),
        isResolved: Bool = false
    ) {
        self.id = id
        self.objectType = objectType
        self.objectDescription = objectDescription
        self.memoryAddress = memoryAddress
        self.retainCount = retainCount
        self.context = context
        self.detectedAt = detectedAt
        self.isResolved = isResolved
    }

    func resolving() -> LeakReport {
        LeakReport(
            id: id,
            objectType: objectType,
            objectDescription: objectDescription,
            memoryAddress: memoryAddress,
            retainCount: retainCount,
            context: context,
            detectedAt: detectedAt,
            isResolved: true
        )
    }
}
