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

// MARK: - Testing Core Exports
//
// This is the core implementation module (Testing_Core).
// Users should import the "Testing" umbrella module instead.
//
// Note: Test_Primitives is NOT @_exported here.
// The umbrella module handles that to ensure macro/type coexistence.

// Dependency injection for Test.withDependencies and @Dependency
@_exported public import Dependencies
// Note: Kernel is an implementation detail of Testing Core, used directly
// by Testing.Main.swift — not re-exported here to avoid leaking
// String_Primitives.String (via the Kernel → Kernel_Primitives →
// String_Primitives @_exported chain), which shadows Swift.String in
// SwiftPM's auto-generated test runner.
// Re-export Tier 2 (runner infrastructure) for convenience
// Includes: Test.Runner, Test.Plan, Test.Exclusion.Controller
@_exported public import Tests
// Re-export inline snapshot module for snapshot() free function
@_exported public import Tests_Inline_Snapshot
// Time primitives for Benchmark/Duration types
@_exported public import Time_Primitives
