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

// MARK: - Test Content Record Types

extension Testing {
    /// The accessor function signature for test content records.
    ///
    /// This signature matches the official swift-testing accessor signature.
    /// The accessor is called during discovery to load test metadata.
    ///
    /// - Parameters:
    ///   - outValue: Pointer to write the test value into.
    ///   - type: The type metadata for the expected type.
    ///   - hint: Optional hint for accessor behavior.
    ///   - reserved: Reserved for future use.
    /// - Returns: `true` if the accessor successfully wrote a value.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public typealias __TestContentRecordAccessor = @convention(c) (
        _ outValue: UnsafeMutableRawPointer,
        _ type: UnsafeRawPointer,
        _ hint: UnsafeRawPointer?,
        _ reserved: UInt
    ) -> CBool

    /// A test content record stored in the binary's test section.
    ///
    /// Records are placed in platform-specific sections:
    /// - macOS/iOS: `__DATA_CONST,__swift5_tests`
    /// - Linux: `swift5_tests`
    /// - Windows: `.sw5test$B`
    ///
    /// The macro generates these records, and discovery enumerates them
    /// at runtime to find all tests.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public typealias __TestContentRecord = (
        /// Record kind: 0x74657374 ('test') for tests, 0x65786974 ('exit') for exit tests.
        kind: UInt32,
        /// Reserved for future use.
        reserved1: UInt32,
        /// Accessor function that loads the test metadata.
        accessor: __TestContentRecordAccessor?,
        /// Context flags (e.g., for suites, parameterized tests).
        context: UInt,
        /// Reserved for future use.
        reserved2: UInt
    )

    /// Test content kind values.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public enum __TestContentKind: UInt32 {
        /// A test or suite declaration.
        case test = 0x74657374  // 'test' in ASCII

        /// An exit test.
        case exitTest = 0x65786974  // 'exit' in ASCII
    }
}

// MARK: - Section Names

extension Testing {
    /// Platform-specific section names for test content.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public enum __TestSectionName {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        public static let name = "__DATA_CONST,__swift5_tests"
        #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
        public static let name = "swift5_tests"
        #elseif os(Windows)
        public static let name = ".sw5test$B"
        #else
        public static let name = "swift5_tests"
        #endif
    }
}

