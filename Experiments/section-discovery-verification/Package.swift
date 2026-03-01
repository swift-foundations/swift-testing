// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "section-discovery-verification",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "section-discovery-verification",
            swiftSettings: [
                .enableUpcomingFeature("InternalImportsByDefault"),
                // NOTE: .enableExperimentalFeature("SymbolLinkageMarkers") was tested.
                // It makes hasFeature(SymbolLinkageMarkers) true, and @_section/@_used
                // are recognized, but ALL variable declarations fail with:
                // "global variable must be a compile-time constant to use @_section attribute"
                // The compile-time constant evaluator does not exist in Swift 6.2.
            ]
        )
    ]
)
