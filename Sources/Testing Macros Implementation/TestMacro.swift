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

/// Implementation of the @Test macro.
///
/// Expands to emit:
/// 1. An accessor closure that creates a `Testing.Registration`
/// 2. A section record that references the accessor (for automatic discovery)
public struct TestMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError.requiresFunction
        }

        let funcName = funcDecl.name.text
        // Use trimmedDescription — preserves backtick escaping for identifiers with spaces
        // (TokenSyntax interpolation into ExprSyntax drops backtick identifiers silently)
        let funcRef = funcDecl.name.trimmedDescription


        // Normalize function name for use in generated identifiers
        // (backtick names may contain spaces)
        let normalizedName = String(funcName.map { char in
            if char == " " { return "_" as Character }
            if char.isLetter || char.isNumber || char == "_" { return char }
            return "_" as Character
        })

        // Generate unique names using the macro context
        let accessorName = context.makeUniqueName("accessor_\(normalizedName)")
        let recordName = context.makeUniqueName("record_\(normalizedName)")

        // Extract traits from macro arguments
        let traits = extractTraits(from: node)

        // Determine if async/throws
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrows = funcDecl.signature.effectSpecifiers?.throwsClause != nil
        let tryKeyword = isThrows ? "try " : ""

        // Determine if inside a type declaration (Suite) or extension
        // Extract both the ref (for code generation) and the name (for display).
        // Use trimmedDescription (not TokenSyntax) to preserve backtick escaping.
        let typeInfo: (ref: String, name: String)? = context.lexicalContext.first.flatMap { syntax in
            if let structDecl = syntax.as(StructDeclSyntax.self) {
                return (structDecl.name.trimmedDescription, structDecl.name.text)
            } else if let classDecl = syntax.as(ClassDeclSyntax.self) {
                return (classDecl.name.trimmedDescription, classDecl.name.text)
            } else if let enumDecl = syntax.as(EnumDeclSyntax.self) {
                return (enumDecl.name.trimmedDescription, enumDecl.name.text)
            } else if let extDecl = syntax.as(ExtensionDeclSyntax.self) {
                let text = extDecl.extendedType.trimmedDescription
                return (text, text)
            }
            return nil
        }
        let suiteExpr = typeInfo.map { "\"\($0.name)\"" } ?? "nil"

        // When inside a type, declarations need to be static
        let staticKeyword = typeInfo != nil ? "static " : ""

        // Build the body expression using raw interpolation for both type and function names.
        // TokenSyntax interpolation into ExprSyntax silently drops backtick-escaped
        // identifiers with spaces; trimmedDescription preserves them correctly.
        let bodyExpr: ExprSyntax
        if let typeInfo = typeInfo {
            let typeRef = typeInfo.ref
            if isAsync {
                bodyExpr = "Testing.__TestBody.async { let instance = \(raw: typeRef)(); \(raw: tryKeyword)await instance.\(raw: funcRef)() }"
            } else {
                bodyExpr = "Testing.__TestBody.sync { let instance = \(raw: typeRef)(); \(raw: tryKeyword)instance.\(raw: funcRef)() }"
            }
        } else {
            if isAsync {
                bodyExpr = "Testing.__TestBody.async { \(raw: tryKeyword)await \(raw: funcRef)() }"
            } else {
                bodyExpr = "Testing.__TestBody.sync { \(raw: tryKeyword)\(raw: funcRef)() }"
            }
        }

        // 1. Generate the accessor as a nonisolated let with a closure
        // The closure type is @convention(c) compatible via __TestContentRecordAccessor
        // When inside a type, we need `static` to allow the record to reference the accessor
        let accessor: DeclSyntax = """
            @available(*, deprecated, message: "This is an implementation detail of the testing library. Do not use it directly.")
            private \(raw: staticKeyword)nonisolated let \(accessorName): Testing.__TestContentRecordAccessor = { outValue, type, _, _ in
                let fileID = #fileID
                let moduleName = Swift.String(fileID.prefix(while: { $0 != "/" }))
                let registration = Testing.Registration(
                    id: Testing.__TestID(
                        module: moduleName,
                        suite: \(raw: suiteExpr),
                        name: "\(raw: funcName)",
                        sourceLocation: Testing.__TestSourceLocation(
                            fileID: fileID,
                            filePath: #filePath,
                            line: #line,
                            column: 1
                        )
                    ),
                    modifiers: \(raw: traits),
                    body: \(bodyExpr),
                    suiteID: nil
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
            private \(raw: staticKeyword)nonisolated let \(recordName): Testing.__TestContentRecord = (
                Testing.__TestContentKind.test.rawValue,
                0,
                unsafe \(accessorName),
                0,
                0
            )
            """

        // 3. Generate legacy container enum for pre-6.3 discovery.
        // The compiler always places type metadata in __swift5_types, so
        // discovery can find this enum by scanning for types named __🟡$...
        // and casting to __TestContentRecordContainer.
        let containerName = context.makeUniqueName("__🟡$_\(normalizedName)")
        let container: DeclSyntax = """
            #if compiler(<6.3)
            @available(*, deprecated, message: "This type is an implementation detail of the testing library. Do not use it directly.")
            private enum \(containerName): Testing.__TestContentRecordContainer {
                nonisolated static let __testContentRecord: Testing.__TestContentRecord = \(recordName)
            }
            #endif
            """

        return [accessor, record, container]
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

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case requiresFunction
    case requiresStruct

    var description: String {
        switch self {
        case .requiresFunction:
            return "@Test can only be applied to functions"
        case .requiresStruct:
            return "@Suite can only be applied to structs or classes"
        }
    }
}
