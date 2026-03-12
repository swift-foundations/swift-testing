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

extension Testing.Configuration.Output {
    /// Output format for test results.
    public enum Format: Sendable {
        /// Human-readable console output.
        case console
        /// JSON output (no Foundation).
        case json
    }
}
