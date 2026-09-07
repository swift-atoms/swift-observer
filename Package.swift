// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-observation",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Observation", targets: ["Observation"]),
        .library(name: "Observation Standard Library Integration", targets: ["Observation Standard Library Integration"]),
        .library(name: "Observation Foundation Library Integration", targets: ["Observation Foundation Library Integration"]),
        .library(name: "Observation Test Support", targets: ["Observation Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ownership.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Observation",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Ownership", package: "swift-ownership"),
            ],
            path: "Sources/Observation"
        ),
        .target(
            name: "Observation Standard Library Integration",
            dependencies: [
                .target(name: "Observation"),
            ],
            path: "Sources/Observation Standard Library Integration"
        ),
        .target(
            name: "Observation Foundation Library Integration",
            dependencies: [
                .target(name: "Observation"),
                .target(name: "Observation Standard Library Integration"),
            ],
            path: "Sources/Observation Foundation Library Integration"
        ),
        .target(
            name: "Observation Test Support",
            dependencies: [
                .target(name: "Observation"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Observation Tests",
            dependencies: [
                .target(name: "Observation"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "Observation Test Support"),
                .target(name: "Observation Standard Library Integration"),
                .target(name: "Observation Foundation Library Integration"),
            ],
            path: "Tests/Observation Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
