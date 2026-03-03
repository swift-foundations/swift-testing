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

/// Implementation of the #require macro.
///
/// Like #expect but throws on failure. Also supports optional unwrapping.
///
/// ## Example (Bool)
///
/// ```swift
/// try #require(isValid)
/// ```
///
/// ## Example (Optional)
///
/// ```swift
/// let value = try #require(optionalValue)
/// ```
public struct RequireMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let firstArg = node.arguments.first?.expression else {
            throw Error.missingCondition
        }

        // Check for optional comment argument
        let comment = node.arguments.count > 1
            ? (node.arguments.dropFirst().first?.expression.description ?? "nil")
            : "nil"

        // The expansion works for both Bool and Optional types
        // The overloaded __require functions handle the difference
        return """
            Testing.__require(
                \(firstArg),
                \(raw: comment),
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column
            )
            """
    }
}

extension RequireMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingCondition

        var description: String {
            switch self {
            case .missingCondition:
                return "#require requires a condition or optional argument"
            }
        }
    }
}
