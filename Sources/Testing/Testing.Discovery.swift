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

internal import Loader
internal import Loader_Primitives
internal import Ownership_Primitives

extension Testing {
    /// Test and suite discovery via section enumeration and symbol lookup.
    ///
    /// Primary discovery uses section-based enumeration of test content records
    /// (both `@Test` and `@Suite`). Falls back to dlsym-based lookup if
    /// section discovery finds nothing.
    public struct Discovery: Sendable {

        // MARK: - Primary: Section-Based Discovery

        /// Discovers all tests and suites from binary section records.
        ///
        /// Enumerates the `__swift5_tests` section (or platform equivalent)
        /// to find test content records emitted by `@Test` and `@Suite` macro expansions.
        ///
        /// - Returns: A registry containing all discovered tests and suites.
        public static func sections() -> Test.Plan.Registry {
            var registry = Test.Plan.Registry()

            // Enumerate all test content sections
            for bounds in Loader.Section.all(.swiftTestContent) {
                unsafe parseTestContentSection(bounds.buffer, into: &registry)
            }

            // Also check fallback section (older Darwin binaries use __DATA instead of __DATA_CONST)
            #if canImport(Darwin)
            for bounds in Loader.Section.all(.swiftTestContentFallback) {
                unsafe parseTestContentSection(bounds.buffer, into: &registry)
            }
            #endif

            return registry
        }

        /// Parses test content records from a section buffer.
        ///
        /// Uses alignment-safe loading to handle potentially unaligned section data.
        ///
        /// - Parameters:
        ///   - buffer: The raw section buffer containing test content records.
        ///   - registry: The registry to add discovered tests to.
        private static func parseTestContentSection(
            _ buffer: UnsafeRawBufferPointer,
            into registry: inout Test.Plan.Registry
        ) {
            let recordStride = unsafe MemoryLayout<Test.__TestContentRecord>.stride

            // Validate section size is a multiple of record stride
            guard buffer.count % recordStride == 0 else {
                // Corrupt or unknown section format - skip silently
                return
            }

            let recordCount = buffer.count / recordStride

            for j in 0..<recordCount {
                let offset = j * recordStride

                // Use alignment-safe loading by copying to stack-allocated storage
                let record: Test.__TestContentRecord = unsafe withUnsafeTemporaryAllocation(
                    of: Test.__TestContentRecord.self,
                    capacity: 1
                ) { temp in
                    unsafe UnsafeMutableRawPointer(temp.baseAddress!).copyMemory(
                        from: buffer.baseAddress!.advanced(by: offset),
                        byteCount: recordStride
                    )
                    return unsafe temp[0]
                }

                unsafe processRecord(record, into: &registry)
            }
        }

        // MARK: - Record Processing

        /// Processes a single test content record into the registry.
        ///
        /// Calls the record's accessor to obtain a boxed registration,
        /// then dispatches based on kind:
        /// - `.test` records are unboxed as ``Test/Registration`` and added as tests.
        /// - `.suite` records are unboxed as ``Test/Suite/Registration`` and added as suites.
        /// - Other kinds (e.g., `.exitTest`) are skipped.
        ///
        /// - Parameters:
        ///   - record: The test content record tuple from a binary section or type metadata.
        ///   - registry: The registry to add discovered content to.
        private static func processRecord(
            _ record: Test.__TestContentRecord,
            into registry: inout Test.Plan.Registry
        ) {
            let kind = unsafe record.kind

            guard kind == Test.__TestContentKind.test.rawValue
               || kind == Test.__TestContentKind.suite.rawValue else {
                return
            }

            guard let accessor = unsafe record.accessor else {
                return
            }

            var registrationPtr: UnsafeRawPointer? = nil
            let success = unsafe accessor(
                &registrationPtr,
                UnsafeRawPointer(bitPattern: 1)!,
                UnsafeRawPointer?(nil),
                0
            )

            guard success, let ptr = unsafe registrationPtr else {
                return
            }

            if kind == Test.__TestContentKind.suite.rawValue {
                let reg = unsafe Ownership.Transfer.Retained<Test.Box<Test.Suite.Registration>>.Outgoing(ptr).consume().value
                registry.add(suite: reg)
            } else {
                let reg = unsafe Ownership.Transfer.Retained<Test.Box<Test.Registration>>.Outgoing(ptr).consume().value
                registry.add(id: reg.id, modifiers: reg.modifiers, body: reg.body)
            }
        }

        // MARK: - Legacy: Type Metadata-Based Discovery

        /// Discovers tests and suites from type metadata (legacy, Swift < 6.3).
        ///
        /// Scans `__swift5_types` for enum types named `__🟡$...` that conform to
        /// `__TestContentRecordContainer`. Each matching type's
        /// `__testContentRecord` property provides a test content record tuple.
        ///
        /// - Returns: A registry containing all discovered tests and suites.
        public static func typeMetadata() -> Test.Plan.Registry {
            var registry = Test.Plan.Registry()

            let types = Loader.types(named: "__🟡$")

            for type in types {
                guard let container = type as? any Test.__TestContentRecordContainer.Type else {
                    continue
                }

                unsafe processRecord(container.__testContentRecord, into: &registry)
            }

            return registry
        }

        // MARK: - Unified Discovery

        /// Discovers all tests using the best available method.
        ///
        /// Tries section-based discovery first, then falls back to
        /// type-metadata discovery if no tests are found (Swift < 6.3).
        ///
        /// - Returns: A registry containing all discovered tests and suites.
        public static func all() -> Test.Plan.Registry {
            var registry = sections()

            if registry.count == 0 {
                registry = typeMetadata()
            }

            return registry
        }
    }
}
