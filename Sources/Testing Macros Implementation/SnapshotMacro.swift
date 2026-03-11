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
/// The canonical syntax is configuration-first, value as trailing closure:
///
/// ```swift
/// #snapshot(as: .html) { value }
/// #snapshot(as: .html) { value } matches: { expected }
/// #snapshot(as: .json, named: "x") { value }
/// ```
///
/// The trailing closure provides the value. When recorded, a `matches:`
/// additional trailing closure is added with the expected value.
public struct SnapshotMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        var strategyExpr: ExprSyntax?
        var nameExpr: Swift.String?
        var recordExpr: Swift.String?
        var redactingExpr: Swift.String = "[]"

        for argument in node.arguments {
            let label = argument.label?.text
            let expr = argument.expression

            switch label {
            case "as":
                strategyExpr = expr
            case "named":
                nameExpr = expr.description
            case "record":
                recordExpr = expr.description
            case "redacting":
                redactingExpr = expr.description
            default:
                break
            }
        }

        guard let strategy = strategyExpr else {
            throw Error.missingStrategy
        }

        guard let trailingClosure = node.trailingClosure else {
            throw Error.missingValue
        }

        // Extract value expression from trailing closure.
        // Single expression: use directly. Multi-statement: wrap in IIFE.
        let valueExpr: ExprSyntax = {
            let statements = trailingClosure.statements
            if statements.count == 1,
               let single = statements.first,
               case .expr(let expr) = single.item {
                return expr
            }
            return "({ \(statements) }())"
        }()

        let hasName = nameExpr != nil
        let recordArg = recordExpr.map { "record: \($0)," } ?? ""

        // Check for `matches:` in additional trailing closures.
        let matchesClosure = node.additionalTrailingClosures.first(
            where: { $0.label.text == "matches" }
        )

        if hasName && matchesClosure != nil {
            throw Error.namedWithMatches
        }

        if hasName {
            return """
                snapshot(
                    as: \(strategy),
                    named: \(raw: nameExpr!),
                    \(raw: recordArg)
                    redacting: \(raw: redactingExpr),
                    { \(valueExpr) },
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column,
                    function: #function
                )
                """
        } else {
            let matches: Swift.String
            if let matchesClosure {
                matches = "{ \(matchesClosure.closure.statements) }"
            } else {
                matches = "nil"
            }

            return """
                snapshot(
                    as: \(strategy),
                    \(raw: recordArg)
                    redacting: \(raw: redactingExpr),
                    { \(valueExpr) },
                    matches: \(raw: matches),
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

extension SnapshotMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingValue
        case missingStrategy
        case namedWithMatches

        var description: Swift.String {
            switch self {
            case .missingValue:
                return "#snapshot requires a trailing closure producing the value to snapshot"
            case .missingStrategy:
                return "#snapshot requires a strategy (as: .lines, .text, .json, .html, etc.)"
            case .namedWithMatches:
                return "#snapshot with 'named:' uses file-backed storage. Remove the 'matches:' closure, or remove 'named:' to use inline comparison."
            }
        }
    }
}
