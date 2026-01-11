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

import Testing_Extras
import Testing

// TODO: Add macro expansion tests using assertMacroExpansion
// Example:
//
// func testTestMacroExpansion() {
//     assertMacroExpansion(
//         """
//         @Test
//         func addition() {
//             #expect(1 + 1 == 2)
//         }
//         """,
//         expandedSource: """
//         func addition() {
//             #expect(1 + 1 == 2)
//         }
//
//         @_cdecl("__swift_test_factory$Test$addition")
//         @usableFromInline
//         func __swift_test_factory_addition() -> UnsafeRawPointer {
//             ...
//         }
//         """,
//         macros: ["Test": TestMacro.self]
//     )
// }
