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
        public let id: String

        /// Suite traits (tags, timeLimit, enabled, serialized).
        public let traits: [Test.Trait]

        /// Source location where the suite is declared.
        public let sourceLocation: Test.Source.Location

        /// Creates a suite registration.
        ///
        /// - Parameters:
        ///   - id: Suite identifier (typically the type name).
        ///   - traits: Suite-level traits.
        ///   - sourceLocation: Source location of the suite declaration.
        public init(
            id: String,
            traits: [Test.Trait],
            sourceLocation: Test.Source.Location
        ) {
            self.id = id
            self.traits = traits
            self.sourceLocation = sourceLocation
        }
    }
}
