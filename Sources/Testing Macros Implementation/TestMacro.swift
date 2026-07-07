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
            // Signature forced by external protocol PeerMacro (untyped `throws`).
            // swiftlint:disable:next typed_throws_required
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw Error.requiresFunction
        }

        let funcName = funcDecl.name.text
        // Use trimmedDescription — preserves backtick escaping for identifiers with spaces
        // (TokenSyntax interpolation into ExprSyntax drops backtick identifiers silently)
        let funcRef = funcDecl.name.trimmedDescription

        // Normalize function name for use in generated identifiers
        // (backtick names may contain spaces)
        let normalizedName = String(
            funcName.map { char in
                if char == " " { return "_" as Character }
                if char.isLetter || char.isNumber || char == "_" { return char }
                return "_" as Character
            }
        )

        // Generate unique names using the macro context
        let accessorName = context.makeUniqueName("accessor_\(normalizedName)")
        let recordName = context.makeUniqueName("record_\(normalizedName)")

        // Extract traits and argument collections from macro arguments.
        // For @Test("name", arguments: c1, c2), traits = ["name"], argCollections = [c1, c2].
        let traits = Testing_Macros_Implementation.extractTraits(from: node, stopAtArguments: true)
        let argCollections = extractArgumentCollections(from: node)

        // Determine if async/throws
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrows = funcDecl.signature.effectSpecifiers?.throwsClause != nil
        let tryKeyword = isThrows ? "try " : ""

        // Determine the enclosing type for code generation and tree placement.
        //
        // typeRef: innermost type name for instantiation (e.g., "Throughput")
        // suiteName: fully-qualified name from all lexical contexts for tree placement
        //            (e.g., "IO.Benchmark.Throughput")
        //
        // These differ when a @Test is inside a struct declared in an extension:
        //   extension IO.Benchmark { struct Throughput { @Test func foo() {} } }
        //   typeRef = "Throughput", suiteName = "IO.Benchmark.Throughput"
        let typeRef: String? = context.lexicalContext.first.flatMap { syntax in
            if let structDecl = syntax.as(StructDeclSyntax.self) {
                return structDecl.name.trimmedDescription
            } else if let classDecl = syntax.as(ClassDeclSyntax.self) {
                return classDecl.name.trimmedDescription
            } else if let enumDecl = syntax.as(EnumDeclSyntax.self) {
                return enumDecl.name.trimmedDescription
            } else if let extDecl = syntax.as(ExtensionDeclSyntax.self) {
                return extDecl.extendedType.trimmedDescription
            }
            return nil
        }

        let suiteName = buildQualifiedSuiteName(from: context)
        let suiteExpr = suiteName.isEmpty ? "nil" : "\"\(suiteName)\""

        // When inside a type, declarations need to be static
        let staticKeyword = typeRef != nil ? "static " : ""

        // Build the body expression using raw interpolation for both type and function names.
        // TokenSyntax interpolation into ExprSyntax silently drops backtick-escaped
        // identifiers with spaces; trimmedDescription preserves them correctly.
        let bodyExpr: ExprSyntax
        let funcParams = Array(funcDecl.signature.parameterClause.parameters)

        // Parametric test: @Test(arguments: collection) or @Test(arguments: c1, c2)
        // Single collection: generates a for-loop calling the function once per element.
        // Multiple collections: generates nested for-loops (Cartesian product).
        if !argCollections.isEmpty, !funcParams.isEmpty {
            let callArgs = buildParametricCallArgs(funcParams: funcParams, argCollections: argCollections)
            let loopOpen = buildLoopOpening(argCollections: argCollections)
            let loopClose = String(repeating: " }", count: argCollections.count)
            let awaitKeyword = isAsync ? "await " : ""

            if let typeRef {
                let body = "let suite = \(typeRef)(); \(loopOpen)\(tryKeyword)\(awaitKeyword)suite.\(funcRef)(\(callArgs))\(loopClose)"
                if isAsync {
                    bodyExpr = "Testing.__TestBody.async { \(raw: body) }"
                } else {
                    bodyExpr = "Testing.__TestBody.sync { \(raw: body) }"
                }
            } else {
                let body = "\(loopOpen)\(tryKeyword)\(awaitKeyword)\(funcRef)(\(callArgs))\(loopClose)"
                if isAsync {
                    bodyExpr = "Testing.__TestBody.async { \(raw: body) }"
                } else {
                    bodyExpr = "Testing.__TestBody.sync { \(raw: body) }"
                }
            }
        } else if let typeRef {
            if isAsync {
                bodyExpr = "Testing.__TestBody.async { let suite = \(raw: typeRef)(); \(raw: tryKeyword)await suite.\(raw: funcRef)() }"
            } else {
                bodyExpr = "Testing.__TestBody.sync { let suite = \(raw: typeRef)(); \(raw: tryKeyword)suite.\(raw: funcRef)() }"
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
                let ptr = unsafe Unmanaged.passRetained(boxed).toOpaque()
                unsafe outValue.storeBytes(of: ptr, as: UnsafeRawPointer?.self)
                return true
            }
            """

        // 2. Generate the section record
        let record = sectionRecord(
            kind: "test",
            accessorName: accessorName,
            recordName: recordName,
            isStatic: typeRef != nil
        )

        // 3. Generate legacy container enum for type-metadata discovery.
        // SymbolLinkageMarkers (@section/@used) is not yet available in
        // production toolchains, so section-based discovery is inert.
        // This enum's conformance to __TestContentRecordContainer is found
        // via __swift5_types metadata scanning in Discovery.typeMetadata().
        let containerName = context.makeUniqueName("__🟡$_test_\(normalizedName)")
        let container: DeclSyntax = """
            @available(*, deprecated, message: "This type is an implementation detail of the testing library. Do not use it directly.")
            private enum \(containerName): Testing.__TestContentRecordContainer {
                nonisolated static let __testContentRecord: Testing.__TestContentRecord = unsafe \(recordName)
            }
            """

        return [accessor, record, container]
    }

    /// Extracts argument collection expressions from macro arguments.
    ///
    /// Returns all expressions starting from the `arguments:` labeled argument,
    /// including subsequent unlabeled arguments (for Cartesian product).
    ///
    /// - `@Test(arguments: c1)` → `[c1]`
    /// - `@Test("name", arguments: c1, c2)` → `[c1, c2]`
    private static func extractArgumentCollections(from node: AttributeSyntax) -> [ExprSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        var found = false
        var collections: [ExprSyntax] = []
        for arg in arguments {
            if arg.label?.text == "arguments" { found = true }
            if found { collections.append(arg.expression) }
        }
        return collections
    }

    /// Builds the for-loop opening for parametric tests.
    ///
    /// Single collection: `for __arg0 in collection {`
    /// Multiple: `for __arg0 in c1 { for __arg1 in c2 {`
    private static func buildLoopOpening(argCollections: [ExprSyntax]) -> String {
        argCollections.enumerated().map { index, expr in
            "for __arg\(index) in \(expr.trimmedDescription) {"
        }.joined(separator: " ")
    }

    /// Builds the function call arguments for parametric tests.
    ///
    /// Maps each function parameter to its corresponding `__argN` variable.
    /// Uses the parameter's external name as the label.
    ///
    /// When a single argument collection is used with multiple function parameters,
    /// tuple destructuring is applied: the collection elements are accessed as
    /// `__arg0.0`, `__arg0.1`, and so on.
    ///
    /// - `@Test(arguments: [1, 2])` with `func test(n: Int)` → `test(n: __arg0)`
    /// - `@Test(arguments: [("a", 1)])` with `func test(s: String, n: Int)` → `test(s: __arg0.0, n: __arg0.1)`
    /// - `@Test(arguments: c1, c2)` with `func test(a: Int, b: Int)` → `test(a: __arg0, b: __arg1)`
    private static func buildParametricCallArgs(
        funcParams: [FunctionParameterSyntax],
        argCollections: [ExprSyntax]
    ) -> String {
        // Tuple destructuring: single collection with multiple function parameters.
        if argCollections.count == 1, funcParams.count > 1 {
            return (0..<funcParams.count).map { index in
                let param = funcParams[index]
                let label: String
                if param.firstName.tokenKind == .wildcard {
                    label = ""
                } else {
                    label = "\(param.firstName.trimmedDescription): "
                }
                return "\(label)__arg0.\(index)"
            }.joined(separator: ", ")
        }

        // Standard: one collection per parameter (including Cartesian product).
        let count = min(funcParams.count, argCollections.count)
        return (0..<count).map { index in
            let param = funcParams[index]
            let label: String
            if param.firstName.tokenKind == .wildcard {
                label = ""
            } else {
                label = "\(param.firstName.trimmedDescription): "
            }
            return "\(label)__arg\(index)"
        }.joined(separator: ", ")
    }
}

// MARK: - Errors

extension TestMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case requiresFunction

        var description: String {
            switch self {
            case .requiresFunction:
                return "@Test can only be applied to functions"
            }
        }
    }
}
