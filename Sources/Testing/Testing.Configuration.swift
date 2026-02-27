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

public import Test_Primitives
internal import Standard_Library_Extensions

extension Testing {
    /// Configuration for test execution.
    ///
    /// Configuration can be loaded from environment variables:
    /// - `SWIFT_TEST_FILTER`: Filter tests by name substring
    /// - `SWIFT_TEST_TAGS`: Comma-separated tag filter
    /// - `SWIFT_TEST_PARALLEL`: "0" = serial, N = limited(N)
    /// - `SWIFT_TEST_OUTPUT`: "json" for JSON output
    /// - `SWIFT_TEST_OUTPUT_PATH`: File path for output
    public struct Configuration: Sendable {
        /// Filter tests by name substring.
        public var filter: Swift.String?

        /// Filter tests by tags.
        public var tags: Set<Swift.String>?

        /// Concurrency mode for test execution.
        public var concurrency: Test.Runner.Concurrency

        /// Output format.
        public var outputFormat: OutputFormat

        /// File path for output (nil = stdout).
        public var outputPath: Swift.String?

        /// Creates a default configuration.
        public init() {
            self.filter = nil
            self.tags = nil
            self.concurrency = .automatic
            self.outputFormat = .console
            self.outputPath = nil
        }

        /// Loads configuration from environment variables.
        public static func fromEnvironment() -> Configuration {
            var config = Configuration()

            if let filter = unsafe Kernel.Environment.get("SWIFT_TEST_FILTER") {
                config.filter = filter
            }

            if let tagsString = unsafe Kernel.Environment.get("SWIFT_TEST_TAGS") {
                let tags = tagsString.split(separator: ",").map { tag in
                    Swift.String(Swift.String(tag).trimming(where: \.isWhitespace))
                }
                config.tags = Set(tags)
            }

            if let parallelString = unsafe Kernel.Environment.get("SWIFT_TEST_PARALLEL") {
                if parallelString == "0" {
                    config.concurrency = .serial
                } else if let n = Int(parallelString), n > 0 {
                    config.concurrency = .limited(n)
                }
            }

            if let output = unsafe Kernel.Environment.get("SWIFT_TEST_OUTPUT") {
                if output.lowercased() == "json" {
                    config.outputFormat = .json
                }
            }

            if let path = unsafe Kernel.Environment.get("SWIFT_TEST_OUTPUT_PATH") {
                config.outputPath = path
            }

            return config
        }
    }
}


