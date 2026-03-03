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

/// Asserts that a value matches its snapshot.
///
/// Dispatches to inline or file-backed comparison based on parameters:
///
/// | `named:` | Trailing closure | Behavior |
/// |----------|-----------------|----------|
/// | absent   | absent          | Inline record (capture and rewrite source) |
/// | absent   | present         | Inline compare (compare against closure) |
/// | present  | absent          | File-backed (compare against named file) |
/// | present  | present         | **Compile error** |
///
/// ## Inline Snapshot
///
/// ```swift
/// // First run — records and rewrites source:
/// #snapshot(error.description, as: .lines)
///
/// // After recording, source becomes:
/// #snapshot(error.description, as: .lines) {
///     """
///     Something went wrong
///     """
/// }
/// ```
///
/// ## File-Backed Snapshot
///
/// ```swift
/// #snapshot(user, as: .json, named: "user-profile")
/// ```
///
/// ## Recording Mode Override
///
/// ```swift
/// #snapshot(output, as: .lines, record: .all)
/// ```
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: File-backed storage name. Mutually exclusive with trailing closure.
///   - record: Recording mode override (`.all`, `.missing`, `.failed`, `.never`).
///   - redactions: Redaction rules applied before comparison.
///   - expected: Trailing closure with expected inline value.
/// - Returns: The snapshot expectation result.
@freestanding(expression)
public macro snapshot<Value, Format>(
    _ value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
    matches expected: (() -> Swift.String)? = nil
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "SnapshotMacro"
)

// MARK: - Internal Implementation Bridge

extension Testing {

    // MARK: Inline

    /// Bridge for `#snapshot` inline expansion (sync).
    @discardableResult
    public static func __snapshotInline<Value: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
        record recording: Test.Snapshot.Recording? = nil,
        redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
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
            record: recording,
            redacting: redactions,
            matches: expected,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    /// Bridge for `#snapshot` inline expansion (async).
    @discardableResult
    public static func __snapshotInline<Value: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
        record recording: Test.Snapshot.Recording? = nil,
        redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
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
            record: recording,
            redacting: redactions,
            matches: expected,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    // MARK: File-backed

    /// Bridge for `#snapshot` file-backed expansion (sync).
    @discardableResult
    public static func __snapshotFile<Value: Sendable, Format: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Format>,
        named name: Swift.String,
        record recording: Test.Snapshot.Recording? = nil,
        redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
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
            record: recording,
            redacting: redactions,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    /// Bridge for `#snapshot` file-backed expansion (async).
    @discardableResult
    public static func __snapshotFile<Value: Sendable, Format: Sendable>(
        _ value: Value,
        as strategy: Test.Snapshot.Strategy<Value, Format>,
        named name: Swift.String,
        record recording: Test.Snapshot.Recording? = nil,
        redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
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
            record: recording,
            redacting: redactions,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }
}
