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

/// Implementation of the `#snapshot` macro.
///
/// Dispatches to inline or file-backed bridge based on syntax:
///
/// - `named:` present + trailing closure → compile error
/// - `named:` present → `Testing.__snapshotFile(...)`
/// - Otherwise → `Testing.__snapshotInline(...)`, forwarding trailing closure as `matches:`
public struct SnapshotMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        var valueExpr: ExprSyntax?
        var strategyExpr: ExprSyntax?
        var nameExpr: Swift.String?
        var recordExpr: Swift.String?
        var redactingExpr: Swift.String = "[]"

        for argument in node.arguments {
            let label = argument.label?.text
            let expr = argument.expression

            switch label {
            case nil:
                if valueExpr == nil {
                    valueExpr = expr
                }
            case "as":
                strategyExpr = expr
            case "named":
                nameExpr = expr.description
            case "record":
                recordExpr = expr.description
            case "redacting":
                redactingExpr = expr.description
            case "matches":
                break
            default:
                break
            }
        }

        guard let value = valueExpr else {
            throw SnapshotMacroError.missingValue
        }

        guard let strategy = strategyExpr else {
            throw SnapshotMacroError.missingStrategy
        }

        let hasTrailingClosure = node.trailingClosure != nil
        let hasName = nameExpr != nil

        if hasName && hasTrailingClosure {
            throw SnapshotMacroError.namedWithTrailingClosure
        }

        let recordArg = recordExpr.map { "record: \($0)," } ?? ""

        if hasName {
            return """
                Testing.__snapshotFile(
                    \(value),
                    as: \(strategy),
                    named: \(raw: nameExpr!),
                    \(raw: recordArg)
                    redacting: \(raw: redactingExpr),
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column,
                    function: #function
                )
                """
        } else {
            let matchesExpr: Swift.String
            if let trailingClosure = node.trailingClosure {
                matchesExpr = "{ \(trailingClosure.statements) }"
            } else {
                matchesExpr = "nil"
            }

            return """
                Testing.__snapshotInline(
                    \(value),
                    as: \(strategy),
                    \(raw: recordArg)
                    redacting: \(raw: redactingExpr),
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
}

enum SnapshotMacroError: Error, CustomStringConvertible {
    case missingValue
    case missingStrategy
    case namedWithTrailingClosure

    var description: Swift.String {
        switch self {
        case .missingValue:
            return "#snapshot requires a value to snapshot"
        case .missingStrategy:
            return "#snapshot requires a strategy (as: .lines, .text, .json, etc.)"
        case .namedWithTrailingClosure:
            return "#snapshot with 'named:' uses file-backed storage. Remove the trailing closure, or remove 'named:' to use inline comparison."
        }
    }
}
