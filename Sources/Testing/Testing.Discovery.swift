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
    /// Test discovery via section enumeration and symbol lookup.
    ///
    /// Primary discovery uses section-based enumeration of test content records.
    /// Falls back to dlsym-based lookup if section discovery finds nothing.
    public struct Discovery: Sendable {

        // MARK: - Primary: Section-Based Discovery

        /// Discovers all tests from binary section records.
        ///
        /// Enumerates the `__swift5_tests` section (or platform equivalent)
        /// to find test content records emitted by `@Test` macro expansions.
        ///
        /// - Returns: A registry containing all discovered tests.
        public static func discoverFromSections() -> Test.Plan.Registry {
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

                // Check if this is a test record (kind == 'test')
                guard unsafe record.kind == Test.__TestContentKind.test.rawValue else {
                    continue
                }

                // Call the accessor to get the registration
                guard let accessor = unsafe record.accessor else {
                    continue
                }

                var registrationPtr: UnsafeRawPointer? = nil
                let success = unsafe accessor(
                    &registrationPtr,
                    UnsafeRawPointer(bitPattern: 1)!,
                    UnsafeRawPointer?(nil),
                    0
                )

                guard success, let ptr = unsafe registrationPtr else {
                    continue
                }

                // Unbox the registration
                let boxed = unsafe Unmanaged<Test.Box<Test.Registration>>.fromOpaque(ptr).takeRetainedValue()
                let reg = boxed.value

                registry.add(id: reg.id, modifiers: reg.modifiers, body: reg.body)
            }
        }

        // MARK: - Legacy: Type Metadata-Based Discovery

        /// Discovers tests from type metadata (legacy, Swift < 6.3).
        ///
        /// Scans `__swift5_types` for enum types named `__🟡$...` that conform to
        /// `__TestContentRecordContainer`. Each matching type's
        /// `__testContentRecord` property provides a test content record tuple.
        ///
        /// - Returns: A registry containing all discovered tests.
        public static func discoverFromTypeMetadata() -> Test.Plan.Registry {
            var registry = Test.Plan.Registry()

            let types = Loader.types(named: "__🟡$")

            for type in types {
                guard let container = type as? any Test.__TestContentRecordContainer.Type else {
                    continue
                }

                let record = unsafe container.__testContentRecord

                guard unsafe record.kind == Test.__TestContentKind.test.rawValue else {
                    continue
                }

                guard let accessor = unsafe record.accessor else {
                    continue
                }

                var registrationPtr: UnsafeRawPointer? = nil
                let success = unsafe accessor(
                    &registrationPtr,
                    UnsafeRawPointer(bitPattern: 1)!,
                    UnsafeRawPointer?(nil),
                    0
                )

                guard success, let ptr = unsafe registrationPtr else {
                    continue
                }

                let boxed = unsafe Unmanaged<Test.Box<Test.Registration>>.fromOpaque(ptr).takeRetainedValue()
                let reg = boxed.value

                registry.add(id: reg.id, modifiers: reg.modifiers, body: reg.body)
            }

            return registry
        }

        // MARK: - Fallback: Symbol-Based Discovery

        /// Factory function signature for dlsym-based discovery.
        public typealias Factory = @convention(c) () -> UnsafeRawPointer

        /// Discovers all tests from factory symbol names (fallback).
        ///
        /// Uses dlsym to look up factory functions created by older
        /// `@Test` macro expansions that use `@_cdecl`.
        ///
        /// - Parameter factoryNames: List of factory symbol names to look up.
        /// - Returns: A registry containing all discovered tests.
        public static func discover(
            factoryNames: [Swift.String]
        ) -> Test.Plan.Registry {
            var registry = Test.Plan.Registry()

            for name in factoryNames {
                guard let ptr = unsafe lookupSymbol(name: name) else {
                    continue
                }

                let factory = unsafe unsafeBitCast(ptr, to: Factory.self)
                let boxedPtr = unsafe factory()

                let boxed = unsafe Unmanaged<Test.Box<Test.Registration>>.fromOpaque(boxedPtr).takeRetainedValue()
                let reg = boxed.value

                registry.add(id: reg.id, modifiers: reg.modifiers, body: reg.body)
            }

            return registry
        }

        /// Looks up a symbol by name in all loaded images.
        ///
        /// - Parameter name: The symbol name to look up.
        /// - Returns: Pointer to the symbol, or nil if not found.
        @usableFromInline
        internal static func lookupSymbol(name: Swift.String) -> UnsafeRawPointer? {
            do {
                return try unsafe name.withCString { cName in
                    try unsafe Loader.Symbol.lookup(name: cName, in: .default)
                }
            } catch {
                return nil
            }
        }

        // MARK: - Unified Discovery

        /// Discovers all tests using the best available method.
        ///
        /// Tries section-based discovery first, then falls back to
        /// symbol-based discovery if no tests are found.
        ///
        /// - Parameter fallbackFactoryNames: Factory names to try if section discovery fails.
        /// - Returns: A registry containing all discovered tests.
        public static func discoverAll(
            fallbackFactoryNames: [Swift.String] = []
        ) -> Test.Plan.Registry {
            // Try section-based discovery first (Swift 6.3+)
            var registry = discoverFromSections()

            // Fall back to type-metadata discovery (Swift < 6.3)
            if registry.isEmpty {
                registry = discoverFromTypeMetadata()
            }

            // Final fallback: dlsym-based discovery
            if registry.isEmpty && !fallbackFactoryNames.isEmpty {
                registry = discover(factoryNames: fallbackFactoryNames)
            }

            return registry
        }
    }
}

// MARK: - Registry isEmpty Check

extension Test.Plan.Registry {
    fileprivate var isEmpty: Bool {
        count == 0
    }
}
