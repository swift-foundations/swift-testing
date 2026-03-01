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
        let typeName: String? = context.lexicalContext.first.flatMap { syntax -> String? in
            if let structDecl = syntax.as(StructDeclSyntax.self) {
                return structDecl.name.text
            } else if let classDecl = syntax.as(ClassDeclSyntax.self) {
                return classDecl.name.text
            } else if let enumDecl = syntax.as(EnumDeclSyntax.self) {
                return enumDecl.name.text
            } else if let extDecl = syntax.as(ExtensionDeclSyntax.self) {
                // For extensions, extract the extended type name
                return extDecl.extendedType.trimmedDescription
            }
            return nil
        }
        let suiteExpr = typeName.map { "\"\($0)\"" } ?? "nil"

        // When inside a type, declarations need to be static
        let staticKeyword = typeName != nil ? "static " : ""

        // Build the body wrapper - for instance methods, we need to instantiate the type
        let bodyWrapper: String
        if let typeName = typeName {
            // Instance method inside a type - create instance and call method
            if isAsync {
                bodyWrapper = ".async { let instance = \(typeName)(); \(tryKeyword)await instance.\(funcName)() }"
            } else {
                bodyWrapper = ".sync { let instance = \(typeName)(); \(tryKeyword)instance.\(funcName)() }"
            }
        } else {
            // Free function at module scope
            bodyWrapper = isAsync ? ".async { \(tryKeyword)await \(funcName)() }" : ".sync { \(tryKeyword)\(funcName)() }"
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
                    traits: \(raw: traits),
                    body: Testing.__TestBody\(raw: bodyWrapper),
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
                0x74657374,
                0,
                unsafe \(accessorName),
                0,
                0
            )
            """

        return [accessor, record]
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
