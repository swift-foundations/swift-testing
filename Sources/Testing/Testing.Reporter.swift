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
import Tests_Reporter

extension Testing {
    /// Reporter factory methods.
    ///
    /// These delegate to the canonical implementations in swift-tests'
    /// Tests Reporter module.
    public enum Reporter {
        /// Creates a console reporter with ANSI terminal styling.
        public static var console: Test.Reporter {
            .console
        }

        /// Creates a JSON reporter.
        ///
        /// - Parameter path: File path for output, or nil for stdout.
        /// - Returns: A reporter that outputs JSON.
        public static func json(to path: Swift.String?) -> Test.Reporter {
            .json(to: path)
        }
    }
}
