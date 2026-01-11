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

// Re-export Tier 2 (runner infrastructure) for convenience
@_exported public import Tests

// Platform abstraction for discovery and I/O
@_exported public import Kernel
