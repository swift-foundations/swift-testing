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
public import Ownership_Primitives

// MARK: - Helpers for Macro Expansion

extension Testing {
    /// Helper for #expect macro expansion.
    ///
    /// Macros expand to calls to this function, which delegates to
    /// the underlying `expect()` from swift-tests.
    @inlinable
    @discardableResult
    public static func __expect(
        _ condition: Bool,
        _ comment: Test.Text? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) -> Test.Expectation {
        expect(
            condition,
            comment,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Helper for #require macro expansion (Bool version).
    ///
    /// Macros expand to calls to this function, which delegates to
    /// the underlying `require()` from swift-tests.
    @inlinable
    public static func __require(
        _ condition: Bool,
        _ comment: Test.Text? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) throws(Test.Requirement.Failed) {
        try require(
            condition,
            comment,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Helper for #require macro expansion (Optional version).
    ///
    /// Macros expand to calls to this function, which delegates to
    /// the underlying `require()` from swift-tests.
    @inlinable
    public static func __require<T>(
        _ optional: T?,
        _ comment: Test.Text? = nil,
        fileID: Swift.String = #fileID,
        filePath: Swift.String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) throws(Test.Requirement.Failed) -> T {
        try require(
            optional,
            comment,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - Factory Registration Helper

extension Testing {
    /// C-compatible function type for factory functions.
    public typealias FactoryFunction = @convention(c) () -> UnsafeRawPointer

    /// Creates a boxed registration and returns it as an unsafe pointer.
    ///
    /// Used by @Test macro expansion to create factory functions.
    ///
    /// - Parameters:
    ///   - id: Test identifier.
    ///   - modifiers: Modifiers for the trait collection.
    ///   - body: Test body.
    ///   - suiteID: Optional suite identifier.
    /// - Returns: Retained pointer to boxed registration.
    @inlinable
    public static func __createRegistration(
        id: Test.ID,
        modifiers: [Test.Trait.Collection.Modifier],
        body: Test.Body,
        suiteID: Swift.String? = nil
    ) -> UnsafeRawPointer {
        let registration = Test.Registration(
            id: id,
            modifiers: modifiers,
            body: body,
            suiteID: suiteID
        )
        let boxed = Test.Box(registration)
        return unsafe UnsafeRawPointer(Unmanaged.passRetained(boxed).toOpaque())
    }
}
