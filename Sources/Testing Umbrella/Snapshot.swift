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

import Tests_Inline_Snapshot

/// Asserts that a value matches its snapshot.
///
/// Configuration goes first, value as trailing closure, expected as
/// `matches:` additional trailing closure.
///
/// ## Inline Snapshot
///
/// ```swift
/// // First run — records and rewrites source:
/// #snapshot(as: .html) {
///     VStack { div { "Hello" } }
/// }
///
/// // After recording, source becomes:
/// #snapshot(as: .html) {
///     VStack { div { "Hello" } }
/// } matches: {
///     """
///     <div>...</div>
///     """
/// }
/// ```
///
/// ## File-Backed Snapshot
///
/// ```swift
/// #snapshot(as: .json, named: "user-profile") {
///     user
/// }
/// ```
///
/// ## Recording Mode Override
///
/// ```swift
/// #snapshot(as: .lines, record: .all) {
///     output
/// }
/// ```
///
/// - Parameters:
///   - strategy: How to convert and compare the value.
///   - name: File-backed storage name. Mutually exclusive with `matches:`.
///   - record: Recording mode override (`.all`, `.missing`, `.failed`, `.never`).
///   - redactions: Redaction rules applied before comparison.
/// - Returns: The snapshot expectation result.
///
@freestanding(expression)
public macro snapshot<Value, Format>(
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
    _ value: () -> Value
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "SnapshotMacro"
)

@freestanding(expression)
public macro snapshot<Value>(
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    _ value: () -> Value,
    matches expected: () -> Swift.String
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "SnapshotMacro"
)

// MARK: - Internal Implementation Bridge

extension Testing {

    // MARK: Inline

    /// Bridge for `#snapshot` inline expansion (sync).
    @discardableResult
    public static func __snapshotInline<Value>(
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
    public static func __snapshotInline<Value>(
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
    public static func __snapshotFile<Value, Format: Sendable>(
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
    public static func __snapshotFile<Value, Format: Sendable>(
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
