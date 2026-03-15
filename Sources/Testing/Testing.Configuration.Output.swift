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

extension Testing.Configuration {
    /// Output configuration for test results.
    public struct Output: Sendable {
        /// The output format.
        public var format: Format

        /// File path for output (nil = stdout).
        public var path: Swift.String?

        /// The file path for structured JSONL output.
        ///
        /// Used when format is `.tee`. Defaults to `.build/test-results.jsonl`.
        /// Override via `SWIFT_TEST_OUTPUT_PATH`.
        public var structuredPath: Swift.String

        /// Creates a default output configuration.
        public init(
            format: Format = .tee,
            path: Swift.String? = nil,
            structuredPath: Swift.String = ".build/test-results.jsonl"
        ) {
            self.format = format
            self.path = path
            self.structuredPath = structuredPath
        }
    }
}
