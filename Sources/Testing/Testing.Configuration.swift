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

internal import Environment
public import Test_Primitives

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
        public var tags: Swift.Set<Swift.String>?

        /// Concurrency mode for test execution.
        public var concurrency: Test.Runner.Concurrency

        /// Output configuration (format and destination).
        public var output: Output

        /// Creates a default configuration.
        public init() {
            self.filter = nil
            self.tags = nil
            self.concurrency = .automatic
            self.output = Output()
        }
    }
}

extension Testing.Configuration {
    /// Current configuration loaded from environment variables.
    public static var current: Self {
        var config = Self()

        if let filter = Environment.read("SWIFT_TEST_FILTER") {
            config.filter = filter
        }

        if let tagsString = Environment.read("SWIFT_TEST_TAGS") {
            let tags = tagsString.split(separator: ",").map { tag in
                Swift.String(tag.drop(while: \.isWhitespace))
            }
            config.tags = Swift.Set(tags)
        }

        if let parallelString = Environment.read("SWIFT_TEST_PARALLEL") {
            if parallelString == "0" {
                config.concurrency = .serial
            } else if let n = Int(parallelString), n > 0 {
                config.concurrency = .limited(n)
            }
        }

        if let outputValue = Environment.read("SWIFT_TEST_OUTPUT") {
            switch outputValue.lowercased() {
            case "console":
                config.output.format = .console

            case "json":
                config.output.format = .json

            default:
                break  // keep default (.tee)
            }
        }

        if let path = Environment.read("SWIFT_TEST_OUTPUT_PATH") {
            config.output.path = path
            config.output.structuredPath = path
        }

        return config
    }
}
