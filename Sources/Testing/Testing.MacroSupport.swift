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

// This file provides unambiguous type references for macro expansions.
// When user code creates a local `Test` type (e.g., via #Tests), it shadows
// the global Test namespace. These typealiases provide stable references.
//
// WORKAROUND: Compound typealias names (__TestID, SuiteRegistration, etc.) [API-NAME-001]
// WHY: Macro-generated code references these by fully-qualified name (Testing.__TestID, etc.).
//   Renaming requires updating all macro codegen sites and verifying ABI stability.
// WHEN TO REMOVE: When macro codegen can use nested type references (Testing.Suite.Registration).
// TRACKING: naming-implementation-audit-swift-tests-swift-testing.md N46, N48

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

    /// Unambiguous reference to Test.__TestContentRecord for macro expansions.
    public typealias __TestContentRecord = Test.__TestContentRecord

    /// Unambiguous reference to Test.__TestContentRecordAccessor for macro expansions.
    public typealias __TestContentRecordAccessor = Test.__TestContentRecordAccessor

    /// Unambiguous reference to Test.__TestContentKind for macro expansions.
    public typealias __TestContentKind = Test.__TestContentKind

    /// Unambiguous reference to Test.Registration for macro expansions.
    public typealias Registration = Test.Registration

    /// Unambiguous reference to Test.Suite.Registration for macro expansions.
    public typealias SuiteRegistration = Test.Suite.Registration

    /// Unambiguous reference to Test.Trait.Collection.Modifier for macro expansions.
    public typealias __TestTraitCollectionModifier = Test.Trait.Collection.Modifier

    /// Unambiguous reference to Test.__TestContentRecordContainer for macro expansions.
    public typealias __TestContentRecordContainer = Test.__TestContentRecordContainer

    /// Box type for passing registrations through C-convention accessors.
    /// Delegates to Test.Box (= Ownership.Shared) so macro-generated code
    /// and section-based discovery use the same concrete type.
    public typealias Box<T: Sendable> = Test.Box<T>
}
