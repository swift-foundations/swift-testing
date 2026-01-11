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

/// Evaluates a requirement and throws on failure.
///
/// Unlike `#expect`, `#require` throws when the condition is false,
/// stopping test execution.
///
/// ## Usage (Bool)
///
/// ```swift
/// try #require(isValid)
/// // Continues only if isValid is true
/// ```
///
/// ## Usage (Optional Unwrapping)
///
/// ```swift
/// let value = try #require(optionalValue)
/// // value is now unwrapped and non-optional
/// ```
@freestanding(expression)
public macro require(
    _ condition: Bool,
    _ comment: Test.Text? = nil
) = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "RequireMacro"
)

/// Unwraps an optional or throws on nil.
@freestanding(expression)
public macro require<T>(
    _ optional: T?,
    _ comment: Test.Text? = nil
) -> T = #externalMacro(
    module: "Testing_Macros_Implementation",
    type: "RequireMacro"
)
