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

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the @Test macro.
///
/// Expands to emit:
/// 1. An accessor function that creates a `Testing.Registration`
/// 2. A section record that references the accessor (for automatic discovery)
///
/// ## Example
///
/// ```swift
/// @Test func testAddition() {
///     #expect(1 + 1 == 2)
/// }
/// ```
///
/// Expands to:
///
/// ```swift
/// func testAddition() {
///     #expect(1 + 1 == 2)
/// }
///
/// @_cdecl("__swift_test_accessor$ModuleName$testAddition")
/// func __swift_test_accessor_testAddition(
///     _ outValue: UnsafeMutableRawPointer,
///     _ type: UnsafeRawPointer,
///     _ hint: UnsafeRawPointer?,
///     _ reserved: UInt
/// ) -> CBool {
///     // ... creates and writes registration
/// }
///
/// @_section("__DATA_CONST,__swift5_tests")
/// @_used
/// private nonisolated let __swift_test_record_testAddition: Testing.__TestContentRecord = (
///     0x74657374,
///     0,
///     unsafe __swift_test_accessor_testAddition,
///     0,
///     0
/// )
/// ```
public struct TestMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError.requiresFunction
        }

        let funcName = funcDecl.name.text
        let moduleName = context.lexicalContext.first.map { "\($0)" } ?? "Unknown"

        // Symbol names
        let accessorSymbol = "__swift_test_accessor$\(moduleName)$\(funcName)"
        let accessorFuncName = "__swift_test_accessor_\(funcName)"
        let recordName = "__swift_test_record_\(funcName)"

        // Extract traits from macro arguments
        let traits = extractTraits(from: node)

        // Determine if async
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil

        // Build the body wrapper
        let bodyWrapper = isAsync ? ".async { await \(funcName)() }" : ".sync { \(funcName)() }"

        // 1. Generate the accessor function
        let accessor: DeclSyntax = """
            @_cdecl("\(raw: accessorSymbol)")
            func \(raw: accessorFuncName)(
                _ outValue: UnsafeMutableRawPointer,
                _ type: UnsafeRawPointer,
                _ hint: UnsafeRawPointer?,
                _ reserved: UInt
            ) -> CBool {
                let registration = Testing.Registration(
                    id: Test.ID(
                        module: "\(raw: moduleName)",
                        suite: nil,
                        name: "\(raw: funcName)",
                        sourceLocation: Test.Source.Location(
                            fileID: #fileID,
                            filePath: #filePath,
                            line: #line,
                            column: 1
                        )
                    ),
                    traits: \(raw: traits),
                    body: Test.Body\(raw: bodyWrapper),
                    suiteID: nil
                )
                let boxed = Testing.Box(registration)
                let ptr = Unmanaged.passRetained(boxed).toOpaque()
                outValue.storeBytes(of: ptr, as: UnsafeRawPointer?.self)
                return true
            }
            """

        // 2. Generate the section record
        // Use platform-specific section names via #if
        let record: DeclSyntax = """
            #if hasFeature(SymbolLinkageMarkers)
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
            @_section("__DATA_CONST,__swift5_tests")
            #elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
            @_section("swift5_tests")
            #elseif os(Windows)
            @_section(".sw5test$B")
            #endif
            @_used
            #endif
            @available(*, deprecated, message: "This is an implementation detail of the testing library. Do not use it directly.")
            private nonisolated let \(raw: recordName): Testing.__TestContentRecord = (
                0x74657374,
                0,
                unsafe \(raw: accessorFuncName),
                0,
                0
            )
            """

        return [accessor, record]
    }

    private static func extractTraits(from node: AttributeSyntax) -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return "[]"
        }

        let traitExprs = arguments.map { $0.expression.description }
        if traitExprs.isEmpty {
            return "[]"
        }

        return "[\(traitExprs.joined(separator: ", "))]"
    }
}

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case requiresFunction
    case requiresStruct

    var description: String {
        switch self {
        case .requiresFunction:
            return "@Test can only be applied to functions"
        case .requiresStruct:
            return "@Suite can only be applied to structs or classes"
        }
    }
}
