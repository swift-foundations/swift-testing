// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-testing open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-testing project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Automatic XCTest Bridge
//
// This bridge makes @Test-annotated functions discoverable by `swift test`.
//
// SwiftPM's test runner uses XCTest for discovery. By embedding an XCTestCase
// subclass in the Testing library, any test target that `import Testing` gets
// automatic discovery — zero ceremony for consumers.
//
// Flow:
//   1. Consumer writes @Test functions (normal swift-testing code)
//   2. `swift test` discovers __TestingRunner via XCTest class enumeration
//   3. testAll() calls Testing.run()
//   4. run() does section-based discovery of @Test functions
//   5. Tests execute with full trait support (snapshots, performance, etc.)
//
// If no @Test functions exist, run() finds 0 tests and passes silently.
//
// WORKAROUND: Compound class name __TestingRunner [API-NAME-001]
// WHY: XCTest discovers test cases by class name. The __ prefix prevents collisions
//   with user types, and the name must be at file scope (XCTestCase subclass).
// WHEN TO REMOVE: When SwiftPM test runner supports non-XCTest discovery natively.
// TRACKING: naming-implementation-audit-swift-tests-swift-testing.md N49

#if canImport(XCTest)
public import XCTest

public final class __TestingRunner: XCTestCase {
    /// Discovers and runs all @Test-annotated functions via section-based discovery.
    public func testAll() async {
        do {
            try await Testing.run()
        } catch {
            XCTFail("swift-testing reported test failures: \(error)")
        }
    }
}
#endif
