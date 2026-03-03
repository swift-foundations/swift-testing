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
        public var format: OutputFormat

        /// File path for output (nil = stdout).
        public var path: Swift.String?

        /// Creates a default output configuration.
        public init(format: OutputFormat = .console, path: Swift.String? = nil) {
            self.format = format
            self.path = path
        }
    }
}
