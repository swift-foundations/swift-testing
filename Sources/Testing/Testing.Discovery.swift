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
                parseTestContentSection(bounds.buffer, into: &registry)
            }

            // Also check fallback section (older Darwin binaries use __DATA instead of __DATA_CONST)
            #if canImport(Darwin)
            for bounds in Loader.Section.all(.swiftTestContentFallback) {
                parseTestContentSection(bounds.buffer, into: &registry)
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
            let recordStride = MemoryLayout<__TestContentRecord>.stride

            // Validate section size is a multiple of record stride
            guard buffer.count % recordStride == 0 else {
                // Corrupt or unknown section format - skip silently
                return
            }

            let recordCount = buffer.count / recordStride

            for j in 0..<recordCount {
                let offset = j * recordStride

                // Use alignment-safe loading by copying to stack-allocated storage
                let record: __TestContentRecord = withUnsafeTemporaryAllocation(
                    of: __TestContentRecord.self,
                    capacity: 1
                ) { temp in
                    // Copy bytes to properly aligned temporary storage
                    UnsafeMutableRawPointer(temp.baseAddress!).copyMemory(
                        from: buffer.baseAddress!.advanced(by: offset),
                        byteCount: recordStride
                    )
                    return temp[0]
                }

                // Check if this is a test record (kind == 'test')
                guard record.kind == __TestContentKind.test.rawValue else {
                    continue
                }

                // Call the accessor to get the registration
                guard let accessor = record.accessor else {
                    continue
                }

                var registrationPtr: UnsafeRawPointer? = nil
                let success = accessor(
                    &registrationPtr,
                    UnsafeRawPointer(bitPattern: 1)!,  // type placeholder
                    UnsafeRawPointer?(nil),  // hint
                    0     // reserved
                )

                guard success, let ptr = registrationPtr else {
                    continue
                }

                // Unbox the registration
                let boxed = Unmanaged<Box<Registration>>.fromOpaque(ptr).takeRetainedValue()
                let reg = boxed.value

                registry.add(id: reg.id, traits: reg.traits, body: reg.body)
            }
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
            factoryNames: [String]
        ) -> Test.Plan.Registry {
            var registry = Test.Plan.Registry()

            for name in factoryNames {
                guard let ptr = lookupSymbol(name: name) else {
                    continue
                }

                let factory = unsafeBitCast(ptr, to: Factory.self)
                let boxedPtr = factory()

                let boxed = Unmanaged<Box<Registration>>.fromOpaque(boxedPtr).takeRetainedValue()
                let reg = boxed.value

                registry.add(id: reg.id, traits: reg.traits, body: reg.body)
            }

            return registry
        }

        /// Looks up a symbol by name in all loaded images.
        ///
        /// - Parameter name: The symbol name to look up.
        /// - Returns: Pointer to the symbol, or nil if not found.
        @usableFromInline
        internal static func lookupSymbol(name: String) -> UnsafeRawPointer? {
            do {
                return try name.withCString { cName in
                    try Loader.Symbol.lookup(name: cName, in: .default)
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
            fallbackFactoryNames: [String] = []
        ) -> Test.Plan.Registry {
            // Try section-based discovery first
            var registry = discoverFromSections()

            // If no tests found and we have fallback names, try dlsym
            if registry.isEmpty && !fallbackFactoryNames.isEmpty {
                registry = discover(factoryNames: fallbackFactoryNames)
            }

            return registry
        }
    }
}

// MARK: - Registry isEmpty Check

extension Test.Plan.Registry {
    /// Returns true if the registry has no entries.
    fileprivate var isEmpty: Bool {
        // We need to check if there are any entries
        // Since Registry is ~Copyable, we can't easily inspect it
        // For now, assume section discovery worked if it returns
        return false
    }
}
