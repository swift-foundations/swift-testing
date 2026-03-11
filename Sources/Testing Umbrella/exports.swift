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
// It re-exports everything needed for a complete testing experience:
// - Test namespace (Test.ID, Test.Trait, etc.) from Test_Primitives
// - Runner infrastructure (Test.Runner, Test.Plan, etc.) from Tests
// - Core implementation (Testing.main, Testing.Discovery, etc.) from Testing Core
// - Macro testing utilities (assertMacroExpansion) from SwiftSyntax
//
// The macro declarations are also in this module (at file scope),
// which ensures @Test and Test.* coexist without collision.

// Re-export Test namespace and all test primitive types
@_exported public import Test_Primitives

// Re-export runner infrastructure
@_exported public import Tests

// Re-export snapshot assertion functions
@_exported public import Tests_Inline_Snapshot

// Re-export core implementation
@_exported public import Testing_Core

// Re-export dependency injection for @Dependency, withDependencies, etc.
@_exported public import Dependencies

// Re-export SwiftSyntax types for macro testing
// Users need: Macro, DiagnosticSpec, Trivia for assertMacroExpansion()
@_exported public import SwiftSyntax
@_exported public import SwiftSyntaxMacros
@_exported public import SwiftSyntaxMacrosGenericTestSupport
