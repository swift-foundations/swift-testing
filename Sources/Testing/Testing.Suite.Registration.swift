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

extension Testing {
    /// A suite registration record created by @Suite macro expansion.
    ///
    /// Suites provide trait inheritance to their contained tests.
    /// Discovery reads suites first, then applies trait inheritance to tests.
    public struct SuiteRegistration: Sendable {
        /// Unique identifier for this suite.
        public let id: Test.ID

        /// Suite traits (tags, timeLimit, enabled, serialized).
        public let traits: [Test.Trait]

        /// Creates a suite registration.
        ///
        /// - Parameters:
        ///   - id: Suite identifier.
        ///   - traits: Suite-level traits.
        public init(
            id: Test.ID,
            traits: [Test.Trait]
        ) {
            self.id = id
            self.traits = traits
        }
    }
}
