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

/// Evaluates an expectation and records the result.
///
/// Unlike `#require`, `#expect` does not throw on failure—it records
/// the failure and continues execution.
///
/// ## Usage
///
/// ```swift
/// #expect(result == 42)
/// #expect(array.isEmpty, "Array should be empty")
/// ```
///
/// ## Expression Capture
///
/// The macro captures the source code of the expression for diagnostic output:
///
/// ```
/// Expectation failed: result == 42
/// - result: 41
/// - expected: 42
/// ```
@discardableResult
@freestanding(expression)
public macro expect(
    _ condition: Bool,
    _ comment: Test.Text? = nil
) -> Test.Expectation =
    #externalMacro(
        module: "Testing_Macros_Implementation",
        type: "ExpectMacro"
    )
