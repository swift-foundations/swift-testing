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

/// Implementation of the #Tests macro.
///
/// Generates a standardized test structure with suite categories:
/// - `Test.Unit` - Unit tests (exclusive within type)
/// - `Test.EdgeCase` - Edge case tests (exclusive within type)
/// - `Test.Integration` - Integration tests (exclusive within type)
/// - `Test.Performance` - Performance tests (globally exclusive, serialized)
/// - `Test.Snapshot` - Snapshot tests (serialized)
///
/// ## Usage
///
/// ```swift
/// extension MyType {
///     #Tests
/// }
///
/// // Write tests as:
/// extension MyType.Test.Unit {
///     @Test func myTest() { ... }
/// }
/// ```
///
/// ## Mutual Exclusion
///
/// Unit, EdgeCase, and Integration suites for a type are mutually exclusive
/// with each other (one runs at a time). Performance suites are globally
/// exclusive (only one Performance suite runs across all types).
///
/// ## Snapshot Configuration
///
/// ```swift
/// extension MyType {
///     #Tests(snapshots: .init(recording: .all))
/// }
/// ```
public struct TestsMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract snapshot configuration if provided
        let snapshotConfig = extractSnapshotConfiguration(from: node)

        // Build group identifier from lexical context (enclosing type names)
        // Unit/EdgeCase/Integration are exclusive per-type, Performance is globally exclusive
        let typeGroup = buildGroupIdentifier(from: context)

        // Build the snapshot suite traits
        let snapshotTraits: String
        if let config = snapshotConfig {
            snapshotTraits = ".serialized, .snapshots(configuration: \(config))"
        } else {
            // Use default (TaskLocal configuration)
            snapshotTraits = ".serialized"
        }

        return [
            """
            @Suite enum Test {
                @Suite(.exclusive(group: \(literal: typeGroup))) struct Unit {}
                @Suite(.exclusive(group: \(literal: typeGroup))) struct EdgeCase {}
                @Suite(.exclusive(group: \(literal: typeGroup))) struct Integration {}
                @Suite(.exclusive, .serialized) struct Performance {}
                @Suite(\(raw: snapshotTraits)) struct Snapshot {}
            }
            """
        ]
    }

    /// Builds a group identifier from the lexical context.
    ///
    /// For `extension MyModule.MyType { #Tests }`, returns "MyModule.MyType".
    /// Falls back to a unique identifier if context cannot be determined.
    private static func buildGroupIdentifier(from context: some MacroExpansionContext) -> String {
        var components: [String] = []

        for lexicalContext in context.lexicalContext {
            if let name = lexicalContext.asProtocol((any DeclGroupSyntax).self)?.declGroupName {
                components.append(name)
            }
        }

        if components.isEmpty {
            // Fallback: use a unique name to avoid collisions
            let unique = context.makeUniqueName("Tests")
            return unique.text
        }

        // Reverse because lexicalContext is innermost-first
        return components.reversed().joined(separator: ".")
    }

    /// Extracts snapshot configuration from macro arguments.
    ///
    /// Supports: `#Tests(snapshots: .init(recording: .all))`
    private static func extractSnapshotConfiguration(
        from node: some FreestandingMacroExpansionSyntax
    ) -> String? {
        let arguments = node.arguments

        for argument in arguments {
            if argument.label?.text == "snapshots" {
                let desc = argument.expression.description
                // Trim whitespace without Foundation
                let trimmed = String(desc.drop(while: { $0.isWhitespace }).reversed().drop(while: { $0.isWhitespace }).reversed())
                return trimmed
            }
        }

        return nil
    }
}

extension DeclGroupSyntax {
    /// Extracts the name from a declaration group (struct, class, enum, extension, etc.)
    fileprivate var declGroupName: String? {
        switch self {
        case let decl as StructDeclSyntax:
            return decl.name.text
        case let decl as ClassDeclSyntax:
            return decl.name.text
        case let decl as EnumDeclSyntax:
            return decl.name.text
        case let decl as ActorDeclSyntax:
            return decl.name.text
        case let decl as ExtensionDeclSyntax:
            return decl.extendedType.trimmedDescription
        default:
            return nil
        }
    }
}
