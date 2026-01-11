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

/// Implementation of the @Suite macro.
///
/// Attaches suite-level traits to all contained @Test functions.
/// Emits a suite registration factory for trait inheritance.
///
/// ## Example
///
/// ```swift
/// @Suite(.serialized)
/// struct MathTests {
///     @Test func addition() { ... }
///     @Test func subtraction() { ... }
/// }
/// ```
public struct SuiteMacro: MemberMacro, MemberAttributeMacro {
    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let typeName = extractTypeName(from: declaration)
        let moduleName = context.lexicalContext.first.map { "\($0)" } ?? "Unknown"
        let symbolName = "__swift_suite_factory$\(moduleName)$\(typeName)"
        let factoryFuncName = "__swift_suite_factory_\(typeName)"

        let traits = extractTraits(from: node)

        let factory: DeclSyntax = """
            @_cdecl("\(raw: symbolName)")
            @usableFromInline
            static func \(raw: factoryFuncName)() -> UnsafeRawPointer {
                let registration = Testing.SuiteRegistration(
                    id: "\(raw: typeName)",
                    traits: \(raw: traits),
                    sourceLocation: Test.Source.Location(
                        fileID: #fileID,
                        filePath: #filePath,
                        line: #line,
                        column: 1
                    )
                )
                let boxed = Testing.Box(registration)
                return UnsafeRawPointer(Unmanaged.passRetained(boxed).toOpaque())
            }
            """

        return [factory]
    }

    // MARK: - MemberAttributeMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Don't add attributes to non-function members
        guard member.is(FunctionDeclSyntax.self) else {
            return []
        }

        // Don't add @Test to functions that already have it
        // This is a simplified check - production would be more thorough
        return []
    }

    // MARK: - Helpers

    private static func extractTypeName(from declaration: some DeclGroupSyntax) -> String {
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return enumDecl.name.text
        }
        return "Unknown"
    }

    private static func extractTraits(from node: AttributeSyntax) -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return "[]"
        }

        let traitExprs = arguments.map { $0.expression.description }
        if traitExprs.isEmpty {
            return "[]"
        }

        return "[\(traitExprs.joined(separator: ", "))]"
    }
}
