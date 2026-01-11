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
    /// A test registration record created by @Test macro expansion.
    ///
    /// Each @Test macro expands to a factory function that creates and returns
    /// a boxed `Registration`. Discovery collects these at runtime via `dlsym`.
    public struct Registration: Sendable {
        /// The test identifier.
        public let id: Test.ID

        /// Test traits (tags, timeLimit, enabled, serialized).
        public let traits: [Test.Trait]

        /// The test body to execute.
        public let body: Test.Body

        /// Optional suite ID if this test belongs to a suite.
        public let suiteID: String?

        /// Creates a test registration.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - traits: Test traits.
        ///   - body: The test body.
        ///   - suiteID: Optional suite identifier.
        public init(
            id: Test.ID,
            traits: [Test.Trait],
            body: Test.Body,
            suiteID: String? = nil
        ) {
            self.id = id
            self.traits = traits
            self.body = body
            self.suiteID = suiteID
        }
    }
}

// MARK: - Box for Unmanaged Transfer

extension Testing {
    /// Box type for transferring Registration via UnsafeRawPointer.
    ///
    /// Used by @_cdecl factory functions to return registrations through
    /// C-compatible function signatures.
    public final class Box<T>: @unchecked Sendable {
        public let value: T

        public init(_ value: T) {
            self.value = value
        }
    }
}
