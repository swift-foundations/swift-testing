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

@main
struct TestingMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestMacro.self,
        SuiteMacro.self,
        ExpectMacro.self,
        RequireMacro.self,
    ]
}
