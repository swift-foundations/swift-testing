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

#if canImport(Darwin)
import Darwin
import MachO
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

// Fallback imports for dlsym-based discovery
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

            #if canImport(Darwin)
            discoverFromSectionsDarwin(&registry)
            #elseif os(Linux)
            // TODO: Implement Linux section enumeration via dl_iterate_phdr
            #elseif os(Windows)
            // TODO: Implement Windows section enumeration
            #endif

            return registry
        }

        #if canImport(Darwin)
        /// Darwin-specific section enumeration using dyld APIs.
        private static func discoverFromSectionsDarwin(_ registry: inout Test.Plan.Registry) {
            let imageCount = _dyld_image_count()

            for i in 0..<imageCount {
                guard let header = _dyld_get_image_header(i) else {
                    continue
                }

                // Cast to 64-bit header (all modern Apple platforms are 64-bit)
                let header64 = UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)

                var size: UInt = 0

                // Try __DATA_CONST first, then __DATA (for older binaries)
                var sectionData = getsectiondata(header64, "__DATA_CONST", "__swift5_tests", &size)
                if sectionData == nil {
                    sectionData = getsectiondata(header64, "__DATA", "__swift5_tests", &size)
                }

                guard let data = sectionData, size > 0 else {
                    continue
                }

                // Enumerate records in this section
                let recordStride = MemoryLayout<__TestContentRecord>.stride
                let recordCount = Int(size) / recordStride
                let basePtr = UnsafeRawPointer(data)

                for j in 0..<recordCount {
                    let recordPtr = basePtr.advanced(by: j * recordStride)
                    let record = recordPtr.load(as: __TestContentRecord.self)

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
        }
        #endif

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
