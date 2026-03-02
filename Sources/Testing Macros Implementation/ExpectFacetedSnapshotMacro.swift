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

/// Implementation of the #expectFacetedSnapshot macro.
///
/// Expands to a call to `Testing.__expectFacetedSnapshot(...)`.
public struct ExpectFacetedSnapshotMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        var valueExpr: ExprSyntax?
        var facetedExpr: ExprSyntax?
        var nameExpr: String = "nil"

        for argument in node.arguments {
            let label = argument.label?.text
            let expr = argument.expression

            switch label {
            case nil:
                if valueExpr == nil {
                    valueExpr = expr
                }
            case "as":
                facetedExpr = expr
            case "named":
                nameExpr = expr.description
            default:
                break
            }
        }

        guard let value = valueExpr else {
            throw ExpectFacetedSnapshotMacroError.missingValue
        }

        guard let faceted = facetedExpr else {
            throw ExpectFacetedSnapshotMacroError.missingFaceted
        }

        return """
            Testing.__expectFacetedSnapshot(
                \(value),
                as: \(faceted),
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

enum ExpectFacetedSnapshotMacroError: Error, CustomStringConvertible {
    case missingValue
    case missingFaceted

    var description: String {
        switch self {
        case .missingValue:
            return "#expectFacetedSnapshot requires a value to snapshot"
        case .missingFaceted:
            return "#expectFacetedSnapshot requires a faceted configuration (as: ...)"
        }
    }
}
