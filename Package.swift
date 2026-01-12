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
        .visionOS(.v26),
    ],
    products: [
        // Full testing library - users import this single module
        // Contains: macros + Test namespace + core implementation
        .library(name: "Testing", targets: ["Testing"]),
        // Core implementation only (no macros) - for programmatic use
        .library(name: "Testing Core", targets: ["Testing Core"]),
    ],
    dependencies: [
        // Tier 1: Primitives
        .package(url: "https://github.com/swift-primitives/swift-test-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", from: "0.0.1"),
        // Tier 2: Runner infrastructure
        .package(url: "https://github.com/swift-foundations/swift-tests.git", from: "0.0.1"),
        // Platform abstraction (file I/O, environment variables)
        .package(url: "https://github.com/swift-foundations/swift-kernel.git", from: "0.0.1"),
        // Dynamic loader (symbol lookup)
        .package(url: "https://github.com/swift-foundations/swift-loader.git", from: "0.0.1"),
        // Macro implementation
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
        // Macro testing utilities
        .package(url: "https://github.com/swift-foundations/swift-testing-extras.git", from: "0.0.1"),
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
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Loader", package: "swift-loader"),
            ],
            path: "Sources/Testing"
        ),
        // Macro implementation target (swift-syntax based)
        .macro(
            name: "Testing Macros Implementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/Testing Macros Implementation"
        ),
        // Tests for macro expansion
        .testTarget(
            name: "Testing Tests",
            dependencies: [
                "Testing",
                .product(name: "Testing Extras", package: "swift-testing-extras"),
            ],
            path: "Tests/Testing Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
