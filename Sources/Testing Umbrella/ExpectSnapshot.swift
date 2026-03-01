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

/// Asserts that a value matches its snapshot, capturing the expression.
///
/// Unlike the function-based `expectSnapshot(of:as:)`, this macro captures
/// the source expression for better diagnostics.
///
/// ## Usage
///
/// ```swift
/// @Test
/// func testUserProfile() {
///     let profile = UserProfile(name: "Alice", bio: "Developer")
///     #expectSnapshot(profile.description, as: .lines)
/// }
/// ```
///
/// ## Named Snapshots
///
/// ```swift
/// #expectSnapshot(output, as: .lines, named: "initialState")
/// #expectSnapshot(output, as: .lines, named: "afterUpdate")
/// ```
///
/// ## Recording Modes
///
/// Use the `.snapshot` trait to control recording at test level:
///
/// ```swift
/// @Test(.snapshot(.record))
/// func testNewFeature() {
///     #expectSnapshot(newOutput, as: .lines)
/// }
/// ```
///
/// Or set the `SWIFT_SNAPSHOT_RECORD` environment variable:
/// - `all`: Always record (overwrite)
/// - `missing`: Record if reference missing (default)
/// - `failed`: Record on failure + fail
/// - `never`: Never record (CI mode)
///
/// ## Expression Capture
///
/// The macro captures the source expression for diagnostics:
///
/// ```
/// Snapshot does not match reference
/// Expression: user.description
/// Reference: __Snapshots__/UserTests/testUser.1.txt
/// ```
@freestanding(expression)
public macro expectSnapshot<Value, Format>(
    _ value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "ExpectSnapshotMacro"
)

// MARK: - Internal Implementation Bridge

extension Testing {
    /// Helper for #expectSnapshot macro expansion.
    ///
    /// Macros expand to calls to this function, which delegates to
    /// the underlying `assertSnapshot()` from swift-tests.
    @discardableResult
    public static func __expectSnapshot<Value: Sendable, Format: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Format>,
        named name: Swift.String? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) -> Test.Expectation {
        assertSnapshot(
            capturing: value,
            as: strategy,
            named: name,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    /// Async variant of the #expectSnapshot macro expansion helper.
    @discardableResult
    public static func __expectSnapshot<Value: Sendable, Format: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Format>,
        named name: Swift.String? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) async -> Test.Expectation {
        await assertSnapshot(
            capturing: value,
            as: strategy,
            named: name,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }
}
