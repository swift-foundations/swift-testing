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
