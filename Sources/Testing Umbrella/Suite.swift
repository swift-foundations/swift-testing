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

/// Marks a type as a test suite.
///
/// The `@Suite` macro provides trait inheritance to all contained tests.
/// Suite traits are merged with test traits according to inheritance rules:
/// - `tags`: union (suite + test)
/// - `enabled`: AND (disable wins)
/// - `serialized`: suite applies to all tests
/// - `timeLimit`: min(strictest)
///
/// ## Usage
///
/// ```swift
/// @Suite(.serialized)
/// struct MathTests {
///     @Test
///     func addition() {
///         #expect(1 + 1 == 2)
///     }
///
///     @Test(.tag("slow"))
///     func complexCalculation() async {
///         // Inherits .serialized from suite
///         // Has both .serialized and .tag("slow")
///     }
/// }
/// ```
@attached(member, names: prefixed(__swift_suite_factory_))
public macro Suite(_ traits: Test.Trait.Collection.Modifier...) = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "SuiteMacro"
)
