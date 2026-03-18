// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LeakSentry",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "LeakSentry", targets: ["LeakSentry"]),
        .library(name: "LeakSentryUIKit", targets: ["LeakSentryUIKit"]),
        .library(name: "LeakSentrySwiftUI", targets: ["LeakSentrySwiftUI"]),
    ],
    targets: [
        .target(
            name: "LeakSentry"
        ),
        .target(
            name: "LeakSentryUIKit",
            dependencies: ["LeakSentry"]
        ),
        .target(
            name: "LeakSentrySwiftUI",
            dependencies: ["LeakSentry"]
        ),
        .testTarget(
            name: "LeakSentryTests",
            dependencies: ["LeakSentry"]
        ),
        .testTarget(
            name: "LeakSentrySwiftUITests",
            dependencies: ["LeakSentrySwiftUI"]
        ),
    ]
)
