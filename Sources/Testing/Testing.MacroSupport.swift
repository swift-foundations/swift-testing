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

//
// This file provides unambiguous type references for macro expansions.
// When user code creates a local `Test` type (e.g., via #Tests), it shadows
// the global Test namespace. These typealiases provide stable references.
//

public import Test_Primitives
public import Tests

extension Testing {
    /// Unambiguous reference to Test.ID for macro expansions.
    public typealias __TestID = Test_Primitives.Test.ID

    /// Unambiguous reference to Source.Location for macro expansions.
    public typealias __TestSourceLocation = Source.Location

    /// Unambiguous reference to Test.Trait for macro expansions.
    public typealias __TestTrait = Test_Primitives.Test.Trait

    /// Unambiguous reference to Test.Body for macro expansions.
    /// Note: Test.Body is defined in the Tests module as an extension on Test.
    public typealias __TestBody = Test.Body
}
