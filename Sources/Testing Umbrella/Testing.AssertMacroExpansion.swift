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

public import SwiftSyntax
import SwiftSyntaxMacroExpansion
public import SwiftSyntaxMacros
public import SwiftSyntaxMacrosGenericTestSupport
public import Test_Primitives
/// Asserts that a macro expands to the expected source code.
///
/// This function bridges `SwiftSyntaxMacrosGenericTestSupport` to Swift Testing
/// by collecting expansion failures and throwing `Test.Requirement.Failed`
/// on the first mismatch.
///
/// ## Example
///
/// ```swift
/// @Test
/// func testMacroExpansion() throws {
///     try assertMacroExpansion(
///         """
///         #myMacro
///         """,
///         expandedSource: """
///         // expanded code
///         """,
///         macros: ["myMacro": MyMacro.self]
///     )
/// }
/// ```
///
/// - Parameters:
///   - originalSource: The source code containing macro invocations.
///   - expectedExpandedSource: The expected expansion result.
///   - diagnostics: Expected diagnostics from the expansion.
///   - macros: Dictionary mapping macro names to their implementations.
///   - testModuleName: Name of the test module (for diagnostics).
///   - testFileName: Name of the test file (for diagnostics).
///   - indentationWidth: Indentation width for formatting.
///   - fileID: Source location info.
///   - filePath: Source location info.
///   - line: Source location info.
///   - column: Source location info.
public import Tests

public func assertMacroExpansion(
    _ originalSource: Swift.String,
    expandedSource expectedExpandedSource: Swift.String,
    diagnostics: [DiagnosticSpec] = [],
    // Threads directly into SwiftSyntaxMacroExpansion.MacroSpec.init(type:
    // Macro.Type) — the external API's own parameter shape.
    // swiftlint:disable:next no_any_protocol_existential
    macros: [Swift.String: any Macro.Type],
    testModuleName: Swift.String = "TestModule",
    testFileName: Swift.String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) throws(Test.Requirement.Failed) {
    var failures: [(message: Swift.String, location: Source.Location)] = []

    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macros.mapValues { MacroSpec(type: $0) },
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: { spec in
            failures.append(
                (
                    message: spec.message,
                    location: Source.Location(
                        fileID: spec.location.fileID,
                        filePath: spec.location.filePath,
                        line: Int(spec.location.line),
                        column: Int(spec.location.column)
                    )
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    if let first = failures.first {
        throw Test.Requirement.Failed(
            message: Test.Text(first.message),
            sourceLocation: first.location
        )
    }
}
