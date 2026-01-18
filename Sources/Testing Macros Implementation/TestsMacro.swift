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
/// - `Test.Unit` - Unit tests
/// - `Test.EdgeCase` - Edge case tests
/// - `Test.Integration` - Integration tests
/// - `Test.Performance` - Performance tests (serialized)
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
                @Suite struct Unit {}
                @Suite struct EdgeCase {}
                @Suite struct Integration {}
                @Suite(.serialized) struct Performance {}
                @Suite(\(raw: snapshotTraits)) struct Snapshot {}
            }
            """
        ]
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
