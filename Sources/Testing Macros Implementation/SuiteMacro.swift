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

        // Generate unique names using the macro context
        let accessorName = context.makeUniqueName("suite_accessor")
        let recordName = context.makeUniqueName("suite_record")

        let traits = extractTraits(from: node)

        // 1. Generate the accessor as a static nonisolated let with a closure
        let accessor: DeclSyntax = """
            @available(*, deprecated, message: "This is an implementation detail of the testing library. Do not use it directly.")
            private nonisolated static let \(accessorName): Testing.__TestContentRecordAccessor = { outValue, type, _, _ in
                let fileID = #fileID
                let moduleName = Swift.String(fileID.prefix(while: { $0 != "/" }))
                let registration = Testing.SuiteRegistration(
                    id: Testing.__TestID(
                        module: moduleName,
                        suite: "\(raw: typeName)",
                        name: "",
                        sourceLocation: Testing.__TestSourceLocation(
                            fileID: fileID,
                            filePath: #filePath,
                            line: #line,
                            column: 1
                        )
                    ),
                    traits: \(raw: traits)
                )
                let boxed = Testing.Box(registration)
                let ptr = Unmanaged.passRetained(boxed).toOpaque()
                outValue.storeBytes(of: ptr, as: UnsafeRawPointer?.self)
                return true
            }
            """

        // 2. Generate the section record
        let record: DeclSyntax = """
            #if hasFeature(SymbolLinkageMarkers)
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            @_section("__DATA_CONST,__swift5_tests")
            #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
            @_section("swift5_tests")
            #elseif os(Windows)
            @_section(".sw5test$B")
            #endif
            @_used
            #endif
            @available(*, deprecated, message: "This is an implementation detail of the testing library. Do not use it directly.")
            private nonisolated static let \(recordName): Testing.__TestContentRecord = (
                0x74657374,
                0,
                unsafe \(accessorName),
                0,
                0
            )
            """

        return [accessor, record]
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
