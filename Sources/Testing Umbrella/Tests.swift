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

/// Generates a standardized test structure for a type.
///
/// The `#Tests` macro creates a `Test` enum with nested suite categories:
/// - `Test.Unit` - Unit tests
/// - `Test.EdgeCase` - Edge case tests
/// - `Test.Integration` - Integration tests
/// - `Test.Performance` - Performance tests (serialized)
/// - `Test.Snapshot` - Snapshot tests (serialized)
///
/// ## Basic Usage
///
/// ```swift
/// extension MyType {
///     #Tests
/// }
///
/// // Write tests as extensions:
/// extension MyType.Test.Unit {
///     @Test func validates_input() { ... }
/// }
///
/// extension MyType.Test.Snapshot {
///     @Test func renders_correctly() {
///         #snapshot(MyType().render(), as: .lines)
///     }
/// }
/// ```
///
/// ## Snapshot Configuration
///
/// Override snapshot recording mode for a type's tests:
///
/// ```swift
/// extension MyType {
///     #Tests(snapshots: .init(recording: .all))
/// }
/// ```
///
/// Recording modes:
/// - `.never` - Compare only, fail if missing (CI mode)
/// - `.missing` - Record new, compare existing (default)
/// - `.failed` - Record on failure, still fail
/// - `.all` - Always record/update
///
/// ## Global Configuration
///
/// Set recording mode for all tests via TaskLocal:
///
/// ```swift
/// @main
/// struct TestMain {
///     static func main() async {
///         await Test.Snapshot.withConfiguration(.init(recording: .never)) {
///             await Testing.main()
///         }
///     }
/// }
/// ```
@freestanding(declaration, names: named(Test))
public macro Tests(
    snapshots: Test.Snapshot.Configuration = .default
) = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "TestsMacro"
)
