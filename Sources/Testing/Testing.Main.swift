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

import Dependencies
import Tests_Inline_Snapshot
import Witnesses
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
        let hasFailures = await run(registry: Discovery.all())
        ISO_9945.Kernel.Process.Exit.now(hasFailures ? 1 : 0)
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
        await run(registry: Discovery.all())
    }

    /// Runs all discovered tests and returns whether any failed.
    ///
    /// Use this for programmatic test execution (e.g., XCTest bridges).
    /// Discovers tests from section records and executes them with console output.
    ///
    /// - Returns: `true` if any test failed, `false` if all passed.
    public static func run() async -> Bool {
        await run(registry: Discovery.all())
    }

    /// Internal runner that executes a test plan and returns whether there were failures.
    @discardableResult
    private static func run(registry: consuming Test.Plan.Registry) async -> Bool {
        let config = Configuration.current

        // Apply filters
        // TODO: Implement filtering based on config.filter and config.tags

        // Finalize plan
        let plan = registry.finalize()

        // Create reporter based on output format
        let reporter: Test.Reporter
        switch config.output.format {
        case .console:
            reporter = .console
        case .json:
            reporter = .json(to: config.output.path)
        }

        // Create and run the runner
        var runner = Test.Runner(reporter: reporter)
        runner.scopeProviders.append(.snapshot)

        // Append inline snapshot write-back action
        runner.postRunActions.append {
            let state = Test.Snapshot.Inline.state
            guard !state.isEmpty else { return }
            do {
                try Test.Snapshot.Inline.Rewriter.writeAll(from: state.drain())
            } catch {
                // Non-fatal: inline snapshot write failure should not change test results.
                // The test already reported a failure asking the user to re-run.
                print("Warning: Failed to write inline snapshots: \(error)")
            }
        }

        // Execute tests in test mode context.
        // This ensures all dependencies resolve to testValue by default.
        let result = await Witness.Context.with(mode: .test) {
            await runner.run(plan, concurrency: config.concurrency)
        }

        return result.hasFailures
    }
}
