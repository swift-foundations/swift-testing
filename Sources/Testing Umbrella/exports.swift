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

// MARK: - Umbrella Module Exports
//
// This module is what users import as "Testing".
// Testing_Core transitively provides: Test_Primitives, Tests (which
// includes Tests_Inline_Snapshot, Tests_Snapshot, Tests_Performance),
// Dependencies, and Time_Primitives.

// Re-export core implementation (brings all testing infrastructure)
@_exported public import Testing_Core

// Re-export SwiftSyntax types for macro testing
// Users need: Macro, DiagnosticSpec, Trivia for assertMacroExpansion()
@_exported public import SwiftSyntax
@_exported public import SwiftSyntaxMacros
@_exported public import SwiftSyntaxMacrosGenericTestSupport
