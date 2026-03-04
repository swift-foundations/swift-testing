// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-testing",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        // Full testing library - users import this single module
        // Contains: macros + Test namespace + core implementation
        .library(name: "Testing", targets: ["Testing"]),
        // Core implementation only (no macros) - for programmatic use
        .library(name: "Testing Core", targets: ["Testing Core"]),
        // Effects integration for testing effect handlers
        .library(name: "Testing Effects", targets: ["Testing Effects"]),
        .library(
            name: "Testing Test Support",
            targets: ["Testing Test Support"]
        )
    ],
    dependencies: [
        // Tier 1: Primitives
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        .package(path: "../../swift-primitives/swift-test-primitives"),
        // Tier 2: Runner infrastructure
        .package(path: "../swift-tests"),
        // Platform abstraction (file I/O, environment variables)
        .package(path: "../swift-kernel"),
        // Environment variable reading
        .package(path: "../swift-environment"),
        // Dynamic loader (symbol lookup)
        .package(path: "../swift-loader"),
        // Dependency injection
        .package(path: "../swift-dependencies", traits: ["Clocks"]),
        // Effects system (for optional Testing Effects target)
        .package(path: "../swift-effects"),
        // Witness system (mode context for test/live execution)
        .package(path: "../swift-witnesses"),
        // Macro implementation
        .package(url: "https://github.com/swiftlang/swift-syntax", "602.0.0"..<"603.0.0")
    ],
    targets: [
        // UMBRELLA TARGET - what users import as "Testing"
        // Contains: macro declarations + @_exported re-exports
        // This ensures @Test macro and Test.* types coexist
        .target(
            name: "Testing",
            dependencies: [
                "Testing Core",
                "Testing Macros Implementation",
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "Tests Inline Snapshot", package: "swift-tests"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax")
            ],
            path: "Sources/Testing Umbrella"
        ),
        // Core implementation - discovery, configuration, reporters
        // Users don't import this directly
        .target(
            name: "Testing Core",
            dependencies: [
                .product(name: "Tests", package: "swift-tests"),
                .product(name: "Tests Reporter", package: "swift-tests"),
                .product(name: "Tests Inline Snapshot", package: "swift-tests"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "Loader", package: "swift-loader"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Witnesses", package: "swift-witnesses"),
            ],
            path: "Sources/Testing"
        ),
        // Macro implementation target (swift-syntax based)
        .macro(
            name: "Testing Macros Implementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/Testing Macros Implementation"
        ),
        // Tests for macro expansion
        // Effects integration for testing effect handlers
        .target(
            name: "Testing Effects",
            dependencies: [
                "Testing Core",
                .product(name: "Effects", package: "swift-effects"),
                .product(name: "Effects Testing", package: "swift-effects")
            ],
            path: "Sources/Testing Effects"
        ),
        .target(
            name: "Testing Test Support",
            dependencies: [
                "Testing Core",
                .product(
                    name: "Tests Test Support",
                    package: "swift-tests"
                ),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Testing Tests",
            dependencies: [
                "Testing",
                "Testing Test Support",
            ]
        ),
        // Macro expansion tests require __TestContentRecord type from Apple's
        // swift-testing. Disabled until we bridge the test content infrastructure.
        // .testTarget(
        //     name: "Macro Expansion Tests",
        //     dependencies: [
        //         "Testing",
        //         "Testing Test Support",
        //         "Testing Macros Implementation",
        //         .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        //         .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
        //     ],
        //     path: "Tests/Macro Expansion Tests"
        // ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro, .test].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
