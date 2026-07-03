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

import XCTest
import Testing
import Testing_Test_Support
import Test_Primitives

// MARK: - XCTest Bridge
//
// SwiftPM's test runner on macOS uses the `xctest` utility which cannot invoke
// our Testing framework's entry point. This bridge makes @Test-based tests
// discoverable through XCTest infrastructure.
//
// Each suite is instantiated and its methods called directly. Test assertions
// use our #expect / #require macros internally; failures are mapped to XCTest
// via XCTAssert at the suite level.
//
// WORKAROUND: __swift5_tests section records use a different layout than
// Apple's swift-testing (absolute vs relative pointers). Section-based
// discovery crashes when the Swift runtime parses our records during image
// loading. This bridge bypasses section discovery entirely.
// WHEN TO REMOVE: When our record format aligns with Apple's, or we use
// a distinct section name with SymbolLinkageMarkers support.

// MARK: - Helpers Tests

final class HelpersTests: XCTestCase {
    func testExpectWithTrueReturnsPassingExpectation() {
        Testing.HelpersTest.Unit().expectWithTrueReturnsPassingExpectation()
    }

    func testExpectWithFalseReturnsFailingExpectation() {
        Testing.HelpersTest.Unit().expectWithFalseReturnsFailingExpectation()
    }

    func testRequireWithTrueDoesNotThrow() throws {
        try Testing.HelpersTest.Unit().requireWithTrueDoesNotThrow()
    }

    func testRequireWithNonNilOptionalReturnsUnwrappedValue() throws {
        try Testing.HelpersTest.Unit().requireWithNonNilOptionalReturnsUnwrappedValue()
    }

    func testRequireWithFalseThrows() {
        Testing.HelpersTest.EdgeCase().requireWithFalseThrows()
    }

    func testRequireWithNilOptionalThrows() {
        Testing.HelpersTest.EdgeCase().requireWithNilOptionalThrows()
    }
}

// MARK: - MacroSupport Tests

final class MacroSupportTests: XCTestCase {
    func testTestIDResolvesToTestID() {
        Testing.MacroSupportTest.Unit().testIDResolvesToTestID()
    }

    func testTestSourceLocationResolvesToTestSourceLocation() {
        Testing.MacroSupportTest.Unit().testSourceLocationResolvesToTestSourceLocation()
    }

    func testTestTraitResolvesToTestTrait() {
        Testing.MacroSupportTest.Unit().testTraitResolvesToTestTrait()
    }

    func testTestBodyResolvesCorrectly() {
        Testing.MacroSupportTest.Unit().testBodyResolvesCorrectly()
    }
}

// MARK: - Configuration Tests

final class ConfigurationTests: XCTestCase {
    func testInitCreatesDefaultConfigurationWithNilFilter() {
        Testing.Configuration.Test.Unit().initCreatesDefaultConfigurationWithNilFilter()
    }

    func testInitCreatesDefaultConfigurationWithNilTags() {
        Testing.Configuration.Test.Unit().initCreatesDefaultConfigurationWithNilTags()
    }

    func testInitCreatesDefaultConfigurationWithAutomaticConcurrency() {
        Testing.Configuration.Test.Unit().initCreatesDefaultConfigurationWithAutomaticConcurrency()
    }

    func testInitCreatesDefaultConfigurationWithTeeOutputFormat() {
        Testing.Configuration.Test.Unit().initCreatesDefaultConfigurationWithTeeOutputFormat()
    }

    func testInitCreatesDefaultConfigurationWithNilOutputPath() {
        Testing.Configuration.Test.Unit().initCreatesDefaultConfigurationWithNilOutputPath()
    }

    func testStubFactoryCreatesConfigurationWithProvidedValues() {
        Testing.Configuration.Test.Unit().stubFactoryCreatesConfigurationWithProvidedValues()
    }

    func testCurrentWithNoEnvVarsReturnsDefaults() {
        Testing.Configuration.Test.EdgeCase().currentWithNoEnvVarsReturnsDefaults()
    }
}

// MARK: - Configuration.Output.Format Tests

final class ConfigurationOutputFormatTests: XCTestCase {
    func testConsoleAndJsonCasesAreDistinct() {
        Testing.Configuration.Output.Format.Test.Unit().consoleAndJsonCasesAreDistinct()
    }
}

// MARK: - Discovery Tests

final class DiscoveryTests: XCTestCase {
    func testSectionsReturnsARegistry() {
        Testing.Discovery.Test.Integration().sectionsReturnsARegistry()
    }

    func testAllReturnsARegistry() {
        Testing.Discovery.Test.Integration().allReturnsARegistry()
    }
}

// MARK: - Macro Compilation Tests

final class MacroCompilationXCTests: XCTestCase {
    func testOnFreeFunctionCompiles() {
        MacroCompilationTests.Integration().testOnFreeFunctionCompiles()
    }

    func testAsyncFunctionCompiles() async {
        await MacroCompilationTests.Integration().testAsyncFunctionCompiles()
    }

    func testExpectWithBoolCompiles() {
        MacroCompilationTests.Integration().expectWithBoolCompiles()
    }

    func testExpectWithCommentCompiles() {
        MacroCompilationTests.Integration().expectWithCommentCompiles()
    }

    func testRequireWithBoolCompiles() throws {
        try MacroCompilationTests.Integration().requireWithBoolCompiles()
    }

    func testRequireWithOptionalUnwrappingCompiles() throws {
        try MacroCompilationTests.Integration().requireWithOptionalUnwrappingCompiles()
    }
}
