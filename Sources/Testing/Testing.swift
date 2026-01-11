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

/// User-facing testing library providing macros, discovery, and entry point.
///
/// swift-testing builds on:
/// - Tier 1: swift-test-primitives (pure data types)
/// - Tier 2: swift-tests (runner infrastructure)
///
/// ## Usage
///
/// ```swift
/// import Testing
///
/// @Suite
/// struct MathTests {
///     @Test
///     func addition() {
///         #expect(1 + 1 == 2)
///     }
/// }
///
/// @main
/// struct TestRunner {
///     static func main() async {
///         await Testing.main()
///     }
/// }
/// ```
public enum Testing: Sendable {}
