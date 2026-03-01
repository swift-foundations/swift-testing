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

/// Implementation of the #expectInlineSnapshot macro.
///
/// Captures the snapshotted expression, the strategy, and the optional
/// trailing closure (containing the expected value), then expands to
/// a call to `Testing.__expectInlineSnapshot`.
///
/// ## Example
///
/// ```swift
/// #expectInlineSnapshot(user.description, as: .lines) {
///     """
///     User: Alice
///     Email: alice@example.com
///     """
/// }
/// ```
///
/// Expands to:
///
/// ```swift
/// Testing.__expectInlineSnapshot(
///     user.description,
///     as: .lines,
///     matches: {
///         """
///         User: Alice
///         Email: alice@example.com
///         """
///     },
///     fileID: #fileID,
///     filePath: #filePath,
///     line: #line,
///     column: #column,
///     function: #function
/// )
/// ```
public struct ExpectInlineSnapshotMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Parse arguments
        var valueExpr: ExprSyntax?
        var strategyExpr: ExprSyntax?

        for argument in node.arguments {
            let label = argument.label?.text
            let expr = argument.expression

            switch label {
            case nil:
                // First unlabeled argument is the value
                if valueExpr == nil {
                    valueExpr = expr
                }
            case "as":
                strategyExpr = expr
            case "matches":
                // Ignore — we handle this via trailing closure
                break
            default:
                break
            }
        }

        guard let value = valueExpr else {
            throw ExpectInlineSnapshotMacroError.missingValue
        }

        guard let strategy = strategyExpr else {
            throw ExpectInlineSnapshotMacroError.missingStrategy
        }

        // Capture the trailing closure as the `matches:` parameter
        let matchesExpr: Swift.String
        if let trailingClosure = node.trailingClosure {
            matchesExpr = "{ \(trailingClosure.statements) }"
        } else {
            matchesExpr = "nil"
        }

        return """
            Testing.__expectInlineSnapshot(
                \(value),
                as: \(strategy),
                matches: \(raw: matchesExpr),
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column,
                function: #function
            )
            """
    }
}

enum ExpectInlineSnapshotMacroError: Error, CustomStringConvertible {
    case missingValue
    case missingStrategy

    var description: Swift.String {
        switch self {
        case .missingValue:
            return "#expectInlineSnapshot requires a value to snapshot"
        case .missingStrategy:
            return "#expectInlineSnapshot requires a strategy (as: .lines, .text, etc.)"
        }
    }
}
