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

import SwiftCompilerPlugin
import SwiftSyntaxMacros

// Macro implementation types use compound names per [PATTERN-015]:
// Swift macros must use compound names at file scope (language limitation).
// The #externalMacro(type:) string references these names directly.

@main
struct TestingMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestMacro.self,
        SuiteMacro.self,
        TestsMacro.self,
        ExpectMacro.self,
        RequireMacro.self,
        SnapshotMacro.self,
    ]
}
