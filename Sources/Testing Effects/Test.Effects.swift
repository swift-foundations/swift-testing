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

public import Effects
public import Effects_Testing
public import Test_Primitives

extension Test {
    /// Create a spy for recording effect invocations.
    ///
    /// Use this method to create a spy handler that records all invocations
    /// while returning a constant value:
    ///
    /// ```swift
    /// @Test
    /// func featurePerformsEffect() async throws {
    ///     let spy = Test.spy(for: MyEffect.self, returning: expectedValue)
    ///
    ///     // ... run code that performs effects with the spy handler ...
    ///
    ///     #expect(spy.callCount == 1)
    ///     #expect(spy.firstInvocation?.effect.property == expected)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - effect: The effect type to create a spy for.
    ///   - value: The value to return for all effect invocations.
    /// - Returns: A spy that records invocations and returns the given value.
    @inlinable
    public static func spy<E: __EffectProtocol>(
        for effect: E.Type,
        returning value: E.Value
    ) -> Effect.Test.Spy<E> where E.Failure == Never {
        Effect.Test.Spy(returning: value)
    }

    /// Create a spy for recording void effect invocations.
    ///
    /// Use this method to create a spy for effects that return Void:
    ///
    /// ```swift
    /// @Test
    /// func featurePerformsVoidEffect() async throws {
    ///     let spy = Test.spy(for: MyVoidEffect.self)
    ///
    ///     // ... run code that performs effects with the spy handler ...
    ///
    ///     #expect(spy.callCount == 1)
    /// }
    /// ```
    ///
    /// - Parameter effect: The effect type to create a spy for.
    /// - Returns: A spy that records invocations.
    @inlinable
    public static func spy<E: __EffectProtocol>(
        for effect: E.Type
    ) -> Effect.Test.Spy<E> where E.Value == Void, E.Failure == Never {
        Effect.Test.Spy()
    }

    /// Create a spy for recording effect invocations that returns a failure.
    ///
    /// Use this method to create a spy handler that records invocations
    /// while always failing:
    ///
    /// ```swift
    /// @Test
    /// func featureHandlesError() async throws {
    ///     let spy = Test.spy(for: MyEffect.self, throwing: MyError.failure)
    ///
    ///     // ... run code that performs effects with the spy handler ...
    ///
    ///     #expect(spy.callCount == 1)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - effect: The effect type to create a spy for.
    ///   - error: The error to throw for all effect invocations.
    /// - Returns: A spy that records invocations and throws the given error.
    @inlinable
    public static func spy<E: __EffectProtocol>(
        for effect: E.Type,
        throwing error: E.Failure
    ) -> Effect.Test.Spy<E> {
        Effect.Test.Spy(throwing: error)
    }

    /// Create a test handler that returns a constant value.
    ///
    /// Use this for simple mocking without recording:
    ///
    /// ```swift
    /// let handler = Test.handler(for: MyEffect.self, returning: .success)
    /// ```
    ///
    /// - Parameters:
    ///   - effect: The effect type to create a handler for.
    ///   - value: The value to return for all effect invocations.
    /// - Returns: A handler that returns the given value.
    @inlinable
    public static func handler<E: __EffectProtocol>(
        for effect: E.Type,
        returning value: E.Value
    ) -> Effect.Test.Handler<E> where E.Failure == Never {
        Effect.Test.Handler(returning: value)
    }

    /// Create a test handler for void effects.
    ///
    /// - Parameter effect: The effect type to create a handler for.
    /// - Returns: A handler that succeeds with no value.
    @inlinable
    public static func handler<E: __EffectProtocol>(
        for effect: E.Type
    ) -> Effect.Test.Handler<E> where E.Value == Void, E.Failure == Never {
        Effect.Test.Handler()
    }

    /// Create a test handler that always fails.
    ///
    /// - Parameters:
    ///   - effect: The effect type to create a handler for.
    ///   - error: The error to throw for all effect invocations.
    /// - Returns: A handler that throws the given error.
    @inlinable
    public static func handler<E: __EffectProtocol>(
        for effect: E.Type,
        throwing error: E.Failure
    ) -> Effect.Test.Handler<E> {
        Effect.Test.Handler(throwing: error)
    }
}
