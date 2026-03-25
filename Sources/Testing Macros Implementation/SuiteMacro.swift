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
public struct SuiteMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let typeName = typeName(from: declaration)

        let accessorName = context.makeUniqueName("suite_accessor")
        let recordName = context.makeUniqueName("suite_record")

        let traits = Testing_Macros_Implementation.extractTraits(from: node, stopAtArguments: false)

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
                    modifiers: \(raw: traits)
                )
                let boxed = Testing.Box(registration)
                let ptr = unsafe Unmanaged.passRetained(boxed).toOpaque()
                unsafe outValue.storeBytes(of: ptr, as: UnsafeRawPointer?.self)
                return true
            }
            """

        let record = sectionRecord(
            kind: "suite",
            accessorName: accessorName,
            recordName: recordName,
            isStatic: true
        )

        // 3. Generate legacy container enum for type-metadata discovery.
        // SymbolLinkageMarkers is not yet available in production toolchains.
        let containerName = context.makeUniqueName("__🟡$_suite")
        let container: DeclSyntax = """
            @available(*, deprecated, message: "This type is an implementation detail of the testing library. Do not use it directly.")
            private enum \(containerName): Testing.__TestContentRecordContainer {
                nonisolated static let __testContentRecord: Testing.__TestContentRecord = unsafe \(recordName)
            }
            """

        return [accessor, record, container]
    }

    // MARK: - Helpers

    private static func typeName(from declaration: some DeclGroupSyntax) -> String {
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return enumDecl.name.text
        }
        return "Unknown"
    }
}
