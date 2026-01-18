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
        .library(name: "Testing Effects", targets: ["Testing Effects"])
    ],
    dependencies: [
        // Tier 1: Primitives
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        // Tier 2: Runner infrastructure
        .package(path: "../swift-tests"),
        // Platform abstraction (file I/O, environment variables)
        .package(path: "../swift-kernel"),
        // Dynamic loader (symbol lookup)
        .package(path: "../swift-loader"),
        // Dependency injection
        .package(path: "../swift-dependencies"),
        // Effects system (for optional Testing Effects target)
        .package(path: "../swift-effects"),
        // Witness system (mode context for test/live execution)
        .package(path: "../swift-witnesses"),
        // Macro implementation
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0")
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
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Loader", package: "swift-loader"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Witnesses", package: "swift-witnesses")
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
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
