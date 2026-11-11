// swift-tools-version: 6.4

import CompilerPluginSupport
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

        .library(name: "Observer Foundation Integration", targets: ["Observer Foundation Integration"]),
        .library(name: "Observer Test Support", targets: ["Observer Test Support"]),
    ],
    traits: [
        .trait(name: "Tracking", description: "Observer.Tracking, withObservationTracking and the @Observable macro")
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "604.0.0"..<"605.0.0"),
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
                .target(name: "Observer Macros", condition: .when(traits: ["Tracking"])),
            ],
            path: "Sources/Observer"
        ),
        .macro(
            name: "Observer Macros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/Observer Macros"
        ),

        .target(
            name: "Observer Foundation Integration",
            dependencies: [
                .target(name: "Observer")
            ],
            path: "Sources/Observer Foundation Integration"
        ),
        .target(
            name: "Observer Test Support",
            dependencies: [
                .target(name: "Observer")
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Observer Tests",
            dependencies: [
                .target(name: "Observer"),
                .product(name: "Tagged", package: "swift-tagged"),
                .target(name: "Observer Test Support"),
            ],
            path: "Tests/Observer Tests"
        ),
        .testTarget(
            name: "Observer Tracking Tests",
            dependencies: [
                .target(name: "Observer")
            ],
            path: "Tests/Observer Tracking Tests"
        ),
        .testTarget(
            name: "Observer Macros Tests",
            dependencies: [
                .target(name: "Observer Macros"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ],
            path: "Tests/Observer Macros Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
