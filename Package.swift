// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-observer",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Observer", targets: ["Observer"]),
        .library(name: "Observer Standard Library Integration", targets: ["Observer Standard Library Integration"]),
        .library(name: "Observer Foundation Library Integration", targets: ["Observer Foundation Library Integration"]),
        .library(name: "Observer Test Support", targets: ["Observer Test Support"]),
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
            name: "Observer",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Ownership", package: "swift-ownership"),
            ],
            path: "Sources/Observer"
        ),
        .target(
            name: "Observer Standard Library Integration",
            dependencies: [
                .target(name: "Observer"),
            ],
            path: "Sources/Observer Standard Library Integration"
        ),
        .target(
            name: "Observer Foundation Library Integration",
            dependencies: [
                .target(name: "Observer"),
                .target(name: "Observer Standard Library Integration"),
            ],
            path: "Sources/Observer Foundation Library Integration"
        ),
        .target(
            name: "Observer Test Support",
            dependencies: [
                .target(name: "Observer"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Observer Tests",
            dependencies: [
                .target(name: "Observer"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "Observer Test Support"),
                .target(name: "Observer Standard Library Integration"),
                .target(name: "Observer Foundation Library Integration"),
            ],
            path: "Tests/Observer Tests"
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
