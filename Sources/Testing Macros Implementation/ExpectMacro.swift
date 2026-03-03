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

/// Implementation of the #expect macro.
///
/// Captures the expression source code and evaluates the condition.
///
/// ## Example
///
/// ```swift
/// #expect(result == 42)
/// ```
///
/// Expands to:
///
/// ```swift
/// Testing.__expect(
///     result == 42,
///     nil,
///     fileID: #fileID,
///     filePath: #filePath,
///     line: #line,
///     column: #column
/// )
/// ```
public struct ExpectMacro: ExpressionMacro {
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

        return """
            Testing.__expect(
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

extension ExpectMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingCondition

        var description: String {
            switch self {
            case .missingCondition:
                return "#expect requires a condition argument"
            }
        }
    }
}
