// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-testing-tests",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    dependencies: [
        // Parent package
        .package(path: "../"),
        // Testing framework
        .package(path: "../../swift-testing"),
        // Test primitives (for test utilities)
        .package(path: "../../../swift-primitives/swift-test-primitives"),
    ],
    targets: [
        .testTarget(
            name: "Testing Tests",
            dependencies: [
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ],
            path: "Sources/Testing Tests"
        )
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
