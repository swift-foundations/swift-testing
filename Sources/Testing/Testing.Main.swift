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

import Synchronization

extension Testing {
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
        let fallbackNames = Manifest.getFactoryNames()
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
        let config = Configuration.fromEnvironment()

        // Apply filters
        // TODO: Implement filtering based on config.filter and config.tags

        // Finalize plan
        let plan = registry.finalize()

        // Create reporter based on output format
        let reporter: Test.Reporter
        switch config.outputFormat {
        case .console:
            reporter = Test.Reporter.console
        case .json:
            reporter = Reporter.json(to: config.outputPath)
        }

        // Create and run the runner
        let runner = Test.Runner(reporter: reporter)
        let result = await runner.run(plan, concurrency: config.concurrency)

        if result.hasFailures {
            // Exit with non-zero status on failure
            // TODO: Use proper exit mechanism
        }
    }
}

// MARK: - Manifest

extension Testing {
    /// Manifest of test factory symbol names.
    ///
    /// In the full implementation, this would be generated at compile time
    /// by collecting all @Test macro expansions.
    public enum Manifest {
        /// Thread-safe storage for factory names.
        private static let _factoryNames = Mutex<[String]>([])

        /// Gets the current list of factory names.
        public static func getFactoryNames() -> [String] {
            _factoryNames.withLock { $0 }
        }

        /// Registers a factory name at runtime.
        ///
        /// This is a fallback for when compile-time collection is not available.
        public static func register(_ name: String) {
            _factoryNames.withLock { names in
                names.append(name)
            }
        }

        /// Registers multiple factory names at runtime.
        public static func register(_ names: [String]) {
            _factoryNames.withLock { existing in
                existing.append(contentsOf: names)
            }
        }
    }
}
