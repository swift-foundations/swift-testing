// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-testing open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-testing project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

/// Asserts that a value matches its inline snapshot, with automatic source
/// rewriting.
///
/// On first run (or in record mode), the framework captures the value and
/// rewrites the source file to insert a trailing closure containing the
/// expected snapshot. On subsequent runs, the captured value is compared
/// against the trailing closure content.
///
/// ## Usage
///
/// ```swift
/// @Test
/// func testUserProfile() {
///     let user = User(name: "Alice", email: "alice@example.com")
///
///     // First run — developer writes:
///     #expectInlineSnapshot(user.description, as: .lines)
///
///     // Framework rewrites source to:
///     #expectInlineSnapshot(user.description, as: .lines) {
///         """
///         User: Alice
///         Email: alice@example.com
///         """
///     }
/// }
/// ```
///
/// ## Recording Modes
///
/// Use environment variable `SWIFT_SNAPSHOT_RECORD` or the `.snapshot` trait:
/// - `all`: Always record (overwrite existing inline snapshots)
/// - `missing`: Record if no trailing closure present (default)
/// - `failed`: Record on failure + fail
/// - `never`: Never record (CI mode)
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - expected: Trailing closure containing the expected value (managed by rewriter).
/// - Returns: The snapshot expectation result.
@freestanding(expression)
public macro expectInlineSnapshot<Value>(
    _ value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    matches expected: (() -> Swift.String)? = nil
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "ExpectInlineSnapshotMacro"
)

// MARK: - Internal Implementation Bridge

extension Testing {
    /// Helper for #expectInlineSnapshot macro expansion.
    ///
    /// Macros expand to calls to this function, which delegates to
    /// the underlying `assertInlineSnapshot()` from swift-tests.
    @discardableResult
    public static func __expectInlineSnapshot<Value: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
        matches expected: (() -> Swift.String)? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) -> Test.Expectation {
        assertInlineSnapshot(
            of: value,
            as: strategy,
            matches: expected,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    /// Async variant of the #expectInlineSnapshot macro expansion helper.
    @discardableResult
    public static func __expectInlineSnapshot<Value: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
        matches expected: (() -> Swift.String)? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) async -> Test.Expectation {
        await assertInlineSnapshot(
            of: value,
            as: strategy,
            matches: expected,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }
}
