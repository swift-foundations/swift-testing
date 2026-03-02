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

/// Asserts that a value matches all facets of a faceted snapshot.
///
/// ## Usage
///
/// ```swift
/// @Test
/// func testDocument() {
///     let faceted = Test.Snapshot.Faceted<Document>(
///         primary: .fullHTML,
///         facets: [("text", .textContent)]
///     )
///     #expectFacetedSnapshot(document, as: faceted)
/// }
/// ```
///
/// - Parameters:
///   - value: The value to snapshot.
///   - faceted: The faceted snapshot configuration.
///   - name: Optional base name for the snapshot files.
/// - Returns: The snapshot expectation result.
@freestanding(expression)
public macro expectFacetedSnapshot<Value>(
    _ value: Value,
    as faceted: Test.Snapshot.Faceted<Value>,
    named name: Swift.String? = nil
) -> Test.Expectation = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "ExpectFacetedSnapshotMacro"
)

// MARK: - Internal Implementation Bridge

extension Testing {
    /// Helper for #expectFacetedSnapshot macro expansion.
    @discardableResult
    public static func __expectFacetedSnapshot<Value: Sendable>(
        _ value: Value,
        as faceted: Test.Snapshot.Faceted<Value>,
        named name: Swift.String? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) -> Test.Expectation {
        assertFacetedSnapshot(
            of: value,
            as: faceted,
            named: name,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }

    /// Async variant of the #expectFacetedSnapshot macro expansion helper.
    @discardableResult
    public static func __expectFacetedSnapshot<Value: Sendable>(
        _ value: Value,
        as faceted: Test.Snapshot.Faceted<Value>,
        named name: Swift.String? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column,
        function: Swift.String = #function
    ) async -> Test.Expectation {
        await assertFacetedSnapshot(
            of: value,
            as: faceted,
            named: name,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )
    }
}
