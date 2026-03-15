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
        /// Console + structured JSONL (default).
        case tee
        /// Human-readable console output only.
        case console
        /// Legacy JSON output.
        case json
    }
}
