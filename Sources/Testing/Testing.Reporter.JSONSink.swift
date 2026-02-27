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

import Test_Primitives
import Kernel

/**
 Pending: Replace with swift-json when available.

 Current implementation is intentionally minimal and does not fully
 implement string escaping semantics.
 */

extension Testing.Reporter {
    /// A test reporter sink that outputs JSON.
    ///
    /// Produces JSON without Foundation by manually constructing UTF-8 bytes.
    final class JSONSink: Test.Reporter.SinkImplementation, @unchecked Sendable {
        let outputPath: Swift.String?
        var events: [Test.Event] = []

        init(outputPath: Swift.String?) {
            self.outputPath = outputPath
        }

        func send(_ event: Test.Event) async {
            events.append(event)
        }

        func finish() async {
            let json = buildJSON()
            let bytes = Array(json.utf8)

            if let path = outputPath {
                writeToFile(path: path, bytes: bytes)
            } else {
                writeToStdout(bytes: bytes)
            }
        }

        private func buildJSON() -> Swift.String {
            var json = "{\n"
            json += "  \"events\": [\n"

            for (index, event) in events.enumerated() {
                json += "    "
                json += eventToJSON(event)
                if index < events.count - 1 {
                    json += ","
                }
                json += "\n"
            }

            json += "  ]\n"
            json += "}\n"

            return json
        }

        private func eventToJSON(_ event: Test.Event) -> Swift.String {
            // Simplified JSON encoding - production would need proper escaping
            var json = "{"
            json += "\"kind\": \"\(event.kind)\""

            if let duration = event.elapsed {
                let nanoseconds = duration.components.attoseconds / 1_000_000_000
                json += ", \"elapsed_ns\": \(nanoseconds)"
            }

            json += "}"
            return json
        }

        private func writeToFile(path: Swift.String, bytes: [UInt8]) {
            do {
                let descriptor = try Kernel.Path.scope(path) { pathView in
                    try unsafe ISO_9945.Kernel.File.Open.open(
                        path: pathView,
                        mode: .write,
                        options: [.create, .truncate],
                        permissions: .standard
                    )
                }
                defer { try? Kernel.Close.close(descriptor) }

                // Write all bytes
                var remaining = bytes[...]
                while !remaining.isEmpty {
                    let written = try remaining.withUnsafeBytes { buffer in
                        try Kernel.IO.Write.write(descriptor, from: buffer)
                    }
                    remaining = remaining.dropFirst(written)
                }
            } catch {
                // Failed to write - silent failure
            }
        }

        private func writeToStdout(bytes: [UInt8]) {
            // Use Swift's print for stdout — avoids needing raw descriptor construction
            print(Swift.String(decoding: bytes, as: UTF8.self), terminator: "")
        }
    }
}
