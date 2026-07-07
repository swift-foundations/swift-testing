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

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#expect` macro.
///
/// ```swift
/// #expect(result == 42)
/// #expect(result == 42, "should be the answer")
/// ```
public struct ExpectMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
            // Signature forced by external protocol ExpressionMacro (untyped `throws`).
            // swiftlint:disable:next typed_throws_required
    ) throws -> ExprSyntax {
        try expandConditionMacro(node, function: "__expect")
    }
}

/// Implementation of the `#require` macro.
///
/// ```swift
/// try #require(isValid)
/// let value = try #require(optionalValue)
/// ```
public struct RequireMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
            // Signature forced by external protocol ExpressionMacro (untyped `throws`).
            // swiftlint:disable:next typed_throws_required
    ) throws -> ExprSyntax {
        try expandConditionMacro(node, function: "__require")
    }
}

// MARK: - Shared Implementation

/// Expands a condition-checking macro (`#expect` or `#require`) to a
/// `Testing.__expect(...)` or `Testing.__require(...)` call.
private func expandConditionMacro(
    _ node: some FreestandingMacroExpansionSyntax,
    function: String
) throws(ConditionMacroError) -> ExprSyntax {
    guard let condition = node.arguments.first?.expression else {
        throw ConditionMacroError.missingCondition
    }

    let comment =
        node.arguments.count > 1
        ? (node.arguments.dropFirst().first?.expression.description ?? "nil")
        : "nil"

    return """
        Testing.\(raw: function)(
            \(condition),
            \(raw: comment),
            fileID: #fileID,
            filePath: #filePath,
            line: #line,
            column: #column
        )
        """
}

private enum ConditionMacroError: Swift.Error, CustomStringConvertible {
    case missingCondition

    var description: String {
        "#expect / #require requires a condition or optional argument"
    }
}
