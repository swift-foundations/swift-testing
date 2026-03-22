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

public import Dependencies
public import Test_Primitives

extension Test {
    /// Execute test code with dependency overrides.
    ///
    /// Use this method to override dependencies for a specific test scope:
    ///
    /// ```swift
    /// @Test
    /// func featureUsesAPI() async throws {
    ///     await Test.withDependencies {
    ///         $0[APIClient.self] = .mock
    ///     } operation: {
    ///         let result = try await loadData()
    ///         #expect(!result.isEmpty)
    ///     }
    /// }
    /// ```
    ///
    /// The mode is automatically set to `.test`, so unset dependencies
    /// resolve to their `testValue`.
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the dependency values for the scope.
    ///   - operation: The operation to execute with the modified values.
    /// - Returns: The result of the operation.
    /// - Throws: The typed error from the operation.
    @inlinable
    public static func withDependencies<T, E: Swift.Error>(
        _ modify: @escaping (inout Dependency.Values) -> Void,
        operation: () throws(E) -> T
    ) throws(E) -> T {
        try Dependencies.withDependencies(mode: .test, modify, operation: operation)
    }

    /// Execute async test code with dependency overrides.
    ///
    /// This overload preserves actor isolation, allowing the operation to run
    /// in the caller's isolation context.
    ///
    /// ```swift
    /// @Test
    /// func asyncFeatureUsesAPI() async throws {
    ///     try await Test.withDependencies {
    ///         $0[APIClient.self] = .mock
    ///     } operation: {
    ///         let result = try await loadData()
    ///         #expect(!result.isEmpty)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - modify: A closure that modifies the dependency values for the scope.
    ///   - operation: The async operation to execute with the modified values.
    /// - Returns: The result of the operation.
    /// - Throws: The typed error from the operation.
    @inlinable
    nonisolated(nonsending)
    public static func withDependencies<T, E: Swift.Error>(
        _ modify: @escaping (inout Dependency.Values) -> Void,
        operation: nonisolated(nonsending) () async throws(E) -> T
    ) async throws(E) -> T {
        try await Dependencies.withDependencies(mode: .test, modify, operation: operation)
    }
}
