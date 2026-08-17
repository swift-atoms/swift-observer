// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-observation-primitives",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27"),
        .visionOS("27")
    ],
    products: [
        .library(
            name: "Observation Primitives",
            targets: ["Observation Primitives"]
        ),
        .library(
            name: "Observation Primitives Test Support",
            targets: ["Observation Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ownership-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Observation Primitives",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Ownership Immutable Primitives", package: "swift-ownership-primitives"),
            ]
        ),
        .target(
            name: "Observation Primitives Test Support",
            dependencies: [
                "Observation Primitives",
                .product(name: "Tagged Primitives Test Support", package: "swift-tagged-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Observation Primitives Tests",
            dependencies: [
                "Observation Primitives",
                "Observation Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
