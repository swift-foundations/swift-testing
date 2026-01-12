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

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the #expectSnapshot macro.
///
/// Captures the snapshotted expression and evaluates it against a reference.
///
/// ## Example
///
/// ```swift
/// #expectSnapshot(user.description, as: .lines)
/// ```
///
/// Expands to:
///
/// ```swift
/// Testing.__expectSnapshot(
///     user.description,
///     as: .lines,
///     named: nil,
///     fileID: #fileID,
///     filePath: #filePath,
///     line: #line,
///     column: #column,
///     function: #function
/// )
/// ```
public struct ExpectSnapshotMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Parse arguments
        var valueExpr: ExprSyntax?
        var strategyExpr: ExprSyntax?
        var nameExpr: String = "nil"

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
            case "named":
                nameExpr = expr.description
            default:
                break
            }
        }

        guard let value = valueExpr else {
            throw ExpectSnapshotMacroError.missingValue
        }

        guard let strategy = strategyExpr else {
            throw ExpectSnapshotMacroError.missingStrategy
        }

        return """
            Testing.__expectSnapshot(
                \(value),
                as: \(strategy),
                named: \(raw: nameExpr),
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column,
                function: #function
            )
            """
    }
}

enum ExpectSnapshotMacroError: Error, CustomStringConvertible {
    case missingValue
    case missingStrategy

    var description: String {
        switch self {
        case .missingValue:
            return "#expectSnapshot requires a value to snapshot"
        case .missingStrategy:
            return "#expectSnapshot requires a strategy (as: .lines, .text, .json, etc.)"
        }
    }
}
