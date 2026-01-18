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

public import Dependencies
public import Witnesses
import Kernel

extension Testing {
    /// SwiftPM entry point for test execution.
    ///
    /// This function is called by SwiftPM's generated test runner when it detects
    /// a module named "Testing". It runs all discovered tests and exits with
    /// the appropriate status code.
    ///
    /// - Returns: Never returns; exits the process.
    public static func __swiftPMEntryPoint() async -> Never {
        let fallbackNames = Test.Manifest.getFactoryNames()
        let registry = Discovery.discoverAll(fallbackFactoryNames: fallbackNames)
        let hasFailures = await runReturningResult(registry: registry)
        POSIX.Kernel.Process.Exit.now(hasFailures ? 1 : 0)
    }

    /// Main entry point for test execution.
    ///
    /// This function is **actor-agnostic** (no `@MainActor`). Tests that need
    /// MainActor isolation should opt into it themselves.
    ///
    /// Discovery uses section-based enumeration by default (automatic discovery
    /// of `@Test` macros without a manifest). Falls back to dlsym-based discovery
    /// if section enumeration finds no tests.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// @main
    /// struct TestRunner {
    ///     static func main() async {
    ///         // Automatic discovery via section enumeration
    ///         await Testing.main()
    ///     }
    /// }
    /// ```
    ///
    /// ## Configuration
    ///
    /// Configure via environment variables:
    /// - `SWIFT_TEST_FILTER`: Filter tests by name substring
    /// - `SWIFT_TEST_TAGS`: Comma-separated tag filter
    /// - `SWIFT_TEST_PARALLEL`: "0" = serial, N = limited(N)
    /// - `SWIFT_TEST_OUTPUT`: "json" for JSON output
    /// - `SWIFT_TEST_OUTPUT_PATH`: File path for output
    public static func main() async {
        // Primary: section-based discovery (automatic)
        // Fallback: dlsym with manifest factory names
        let fallbackNames = Test.Manifest.getFactoryNames()
        let registry = Discovery.discoverAll(fallbackFactoryNames: fallbackNames)
        await run(registry: registry)
    }

    /// Main entry point with explicit factory names.
    ///
    /// Use this overload when you have a known list of test factory symbols.
    /// This bypasses section-based discovery and uses dlsym directly.
    ///
    /// - Parameter factories: List of factory symbol names to discover.
    public static func main(factories: [String]) async {
        let registry = Discovery.discover(factoryNames: factories)
        await run(registry: registry)
    }

    /// Internal runner that executes a test plan from a registry.
    private static func run(registry: consuming Test.Plan.Registry) async {
        _ = await runReturningResult(registry: registry)
    }

    /// Internal runner that executes a test plan and returns whether there were failures.
    private static func runReturningResult(registry: consuming Test.Plan.Registry) async -> Bool {
        let config = Configuration.fromEnvironment()

        // Apply filters
        // TODO: Implement filtering based on config.filter and config.tags

        // Finalize plan
        let plan = registry.finalize()

        // Create reporter based on output format
        let reporter: Test.Reporter
        switch config.outputFormat {
        case .console:
            reporter = Testing.Reporter.console
        case .json:
            reporter = Testing.Reporter.json(to: config.outputPath)
        }

        // Create and run the runner
        let runner = Test.Runner(reporter: reporter)

        // Execute tests in test mode context.
        // This ensures all dependencies resolve to testValue by default.
        let result = await Witness.Context.with(mode: .test) {
            await runner.run(plan, concurrency: config.concurrency)
        }

        return result.hasFailures
    }
}

