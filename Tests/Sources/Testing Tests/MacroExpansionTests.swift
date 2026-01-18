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

import Testing

// MARK: - @Test Macro Compilation Tests

/// Verify that @Suite and @Test macros compile and work together correctly.
@Suite
struct MacroCompilationTests {
    @Test
    func `suite and test macros compile`() {
        // This test verifies the macros expand correctly
        #expect(true)
    }

    @Test
    func `async test in suite`() async {
        // Verify async tests work inside suites
        #expect(true)
    }
}

/// Verify free-function @Test works at module scope.
@Test
func `free function test`() {
    #expect(1 + 1 == 2)
}

// MARK: - #expect Macro Tests

@Test
func `expect macro with false value`() {
    // This will record an expectation failure but won't throw
    let _ = #expect(Bool(false))
}

@Test
func `expect macro with true value`() {
    #expect(true)
    #expect(1 == 1)
    #expect("hello".count == 5)
}

@Test
func `expect with comment`() {
    #expect(true, "This should pass")
}

// MARK: - #require Macro Tests

@Test
func `require with non-nil optional`() throws {
    let value: Int? = 42
    let unwrapped = try #require(value)
    #expect(unwrapped == 42)
}

@Test
func `require with true condition`() throws {
    try #require(true)
    try #require(1 + 1 == 2)
}

// MARK: - #Tests Macro Tests

/// Example type to test #Tests macro on
enum ExampleType {
    #Tests
}

// Note: Tests inside extensions of generated Test.Unit/etc. don't work yet
// because Swift doesn't allow stored properties in extensions.
// For now, tests should be written inside the original type definition
// or use @Suite directly on a new type.

/// Example with @Suite for comparison
@Suite
struct GeneratedStructureTests {
    @Test
    func `tests macro generates structure`() {
        // Verify ExampleType.Test exists with expected nested types
        // This is a compile-time check - if #Tests didn't work, this wouldn't compile
        let _: ExampleType.Test.Unit.Type = ExampleType.Test.Unit.self
        let _: ExampleType.Test.Snapshot.Type = ExampleType.Test.Snapshot.self
        let _: ExampleType.Test.EdgeCase.Type = ExampleType.Test.EdgeCase.self
        let _: ExampleType.Test.Integration.Type = ExampleType.Test.Integration.self
        let _: ExampleType.Test.Performance.Type = ExampleType.Test.Performance.self
        #expect(true)
    }
}
