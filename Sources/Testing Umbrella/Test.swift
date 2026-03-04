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

/// Marks a function as a test.
///
/// The `@Test` macro emits a factory function that registers the test
/// for discovery at runtime.
///
/// ## Usage
///
/// ```swift
/// @Test
/// func addition() {
///     #expect(1 + 1 == 2)
/// }
///
/// @Test(.tag("slow"), .timeLimit(.seconds(10)))
/// func complexCalculation() async throws {
///     let result = await calculate()
///     try #require(result != nil)
/// }
/// ```
///
/// ## Traits
///
/// - `.tag(_:)`: Add a tag for filtering
/// - `.timeLimit(_:)`: Set execution time limit
/// - `.enabled(_:)`: Conditionally enable/disable
/// - `.serialized`: Run serially (not in parallel)
@attached(peer, names: prefixed(__swift_test_accessor_), prefixed(__swift_test_record_))
public macro Test(_ traits: Test.Trait.Collection.Modifier...) = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "TestMacro"
)

/// Marks a function as a parametric test that runs once per argument.
///
/// The function must accept a single parameter matching the element type
/// of the provided collection.
///
/// ## Usage
///
/// ```swift
/// @Test(arguments: Bool?.allCases)
/// func validation(condition: Bool?) throws {
///     // Runs 3 times: true, false, nil
/// }
///
/// @Test(arguments: MyType.allCases)
/// func exhaustive(arguments: MyType.Arguments) throws {
///     let result = try MyType(arguments)
///     // ...
/// }
/// ```
@attached(peer, names: prefixed(__swift_test_accessor_), prefixed(__swift_test_record_))
public macro Test(
    _ traits: Test.Trait.Collection.Modifier...,
    arguments collection: Any
) = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "TestMacro"
)
