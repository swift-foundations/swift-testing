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

// MARK: - Lexical Context

/// Builds the fully-qualified suite name from all levels of lexical context.
///
/// Macros only see the local syntax node. For extension-nested declarations, the
/// enclosing scopes must be walked to reconstruct the full dotted path. Without this,
/// `extension IO { @Suite struct Benchmark {} }` registers as `"Benchmark"` instead
/// of `"IO.Benchmark"`, breaking the parent–child hierarchy in the test tree.
///
/// - Parameters:
///   - context: The macro expansion context providing lexical scopes.
///   - declarationName: Optional name to append (the declared type name for `@Suite`).
///     Pass `nil` for `@Test` where the declaration is a function.
/// - Returns: The dot-separated fully-qualified name, or empty string if no scope found.
func buildQualifiedSuiteName(
    from context: some MacroExpansionContext,
    declarationName: String? = nil
) -> String {
    var components: [String] = []

    for syntax in context.lexicalContext {
        if let name = syntax.asDeclGroupName {
            components.append(name)
        }
    }

    // lexicalContext is innermost-first; reverse for outermost-first
    components.reverse()

    if let name = declarationName {
        components.append(name)
    }

    return components.joined(separator: ".")
}

extension Syntax {
    /// Extracts the type name from a declaration group syntax node.
    ///
    /// For extensions, returns the extended type's trimmed description (e.g., `"IO.Benchmark"`).
    /// For struct/class/enum/actor, returns the simple name (e.g., `"Throughput"`).
    var asDeclGroupName: String? {
        if let decl = self.as(StructDeclSyntax.self) {
            return decl.name.text
        } else if let decl = self.as(ClassDeclSyntax.self) {
            return decl.name.text
        } else if let decl = self.as(EnumDeclSyntax.self) {
            return decl.name.text
        } else if let decl = self.as(ActorDeclSyntax.self) {
            return decl.name.text
        } else if let decl = self.as(ExtensionDeclSyntax.self) {
            return decl.extendedType.trimmedDescription
        }
        return nil
    }
}

// MARK: - Shared Macro Utilities

/// Extracts trait expressions from macro attribute arguments.
///
/// - Parameter node: The attribute syntax (e.g., `@Test("name", .serialized)`)
/// - Parameter stopAtArguments: When `true`, stops collecting before the `arguments:` label.
///   Use `true` for `@Test` (which has `arguments:`), `false` for `@Suite`.
/// - Returns: A string like `["name", .serialized]` or `[]`.
func extractTraits(from node: AttributeSyntax, stopAtArguments: Bool) -> String {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
        return "[]"
    }

    var traitExprs: [String] = []
    for arg in arguments {
        if stopAtArguments, arg.label?.text == "arguments" { break }
        traitExprs.append(arg.expression.description)
    }
    if traitExprs.isEmpty { return "[]" }
    return "[\(traitExprs.joined(separator: ", "))]"
}

/// Emits a section record declaration for test content discovery.
///
/// - Parameters:
///   - kind: `.test` or `.suite`
///   - accessorName: The unique name of the accessor closure
///   - recordName: The unique name for the record constant
///   - isStatic: Whether the declaration needs `static` (inside a type)
func sectionRecord(
    kind: String,
    accessorName: TokenSyntax,
    recordName: TokenSyntax,
    isStatic: Bool
) -> DeclSyntax {
    let staticKeyword = isStatic ? "static " : ""
    return """
        #if hasFeature(SymbolLinkageMarkers)
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        @section("__DATA_CONST,__swift5_tests")
        #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
        @section("swift5_tests")
        #elseif os(Windows)
        @section(".sw5test$B")
        #endif
        @used
        #endif
        @available(*, deprecated, message: "This is an implementation detail of the testing library. Do not use it directly.")
        private \(raw: staticKeyword)nonisolated let \(recordName): Testing.__TestContentRecord = (
            Testing.__TestContentKind.\(raw: kind).rawValue,
            0,
            unsafe \(accessorName),
            0,
            0
        )
        """
}

