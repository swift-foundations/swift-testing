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

