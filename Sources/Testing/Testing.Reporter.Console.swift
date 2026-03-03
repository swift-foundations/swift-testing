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

public import Test_Primitives
import Time_Primitives
internal import Console

extension Testing.Reporter {
    /// Creates a console reporter.
    ///
    /// The console reporter formats events for terminal output with
    /// human-readable messages. It's the default reporter for local
    /// development.
    ///
    /// - Returns: A reporter that outputs to the console.
    public static var console: Test.Reporter {
        Test.Reporter {
            Test.Reporter.Sink(ConsoleSink())
        }
    }
}

// MARK: - ConsoleSink

extension Testing.Reporter {
    /// Console sink implementation.
    private final class ConsoleSink: Test.Reporter.SinkImplementation, @unchecked Sendable {
        private let capability: Console.Capability
        private var passedCount = 0
        private var failedCount = 0
        private var skippedCount = 0
        private var issueCount = 0

        init() {
            self.capability = Console.Capability.detect(stream: .stdout)
        }

        func send(_ event: Test.Event) async {
            switch event.kind {
            case .runStarted:
                print("Test run started")

            case .testStarted:
                if let id = event.id {
                    print("  ▶ \(id.fullyQualifiedName)")
                }

            case .testEnded(let result):
                if let id = event.id {
                    let symbol: Swift.String
                    let style: Console.Style
                    switch result {
                    case .passed:
                        symbol = "✓"
                        style = .success
                        passedCount += 1
                    case .failed:
                        symbol = "✗"
                        style = .error
                        failedCount += 1
                    case .skipped:
                        symbol = "○"
                        style = .dim
                        skippedCount += 1
                    }

                    var message = "  \(style.apply(to: symbol, capability: capability)) \(id.name)"
                    if let elapsed = event.elapsed {
                        message += dimmed(" (\(elapsed.formatted(.duration)))")
                    }
                    print(message)
                }

            case .testSkipped(let reason):
                skippedCount += 1
                if let id = event.id {
                    var message = "  \(dimmed("○")) \(id.name)\(dimmed(" (skipped)"))"
                    if let reason {
                        message += dimmed(": \(reason.plainText)")
                    }
                    print(message)
                }

            case .issueRecorded(let issue):
                issueCount += 1
                let marker = Console.Style.warning.apply(to: "⚠", capability: capability)
                print("    \(marker) \(issue.kind)")
                if let context = issue.context {
                    printIndented(render(context), indent: "      ")
                }

            case .expectationChecked(let expectation):
                if expectation.isFailing {
                    let marker = Console.Style.error.apply(to: "✗", capability: capability)
                    print("    \(marker) \(expectation.expression.sourceCode)")

                    // Source location
                    let loc = expectation.expression.sourceLocation
                    print("      \(dimmed("at \(loc.fileID):\(loc.line):\(loc.column)"))")

                    if let failure = expectation.failure {
                        // Failure message
                        printIndented(render(failure.message), indent: "      ")

                        // Expected vs actual
                        if let expected = failure.expected, let actual = failure.actual {
                            let expectedLabel = Console.Style.success.apply(
                                to: "expected", capability: capability
                            )
                            let actualLabel = Console.Style.error.apply(
                                to: "actual", capability: capability
                            )
                            print("      \(expectedLabel): \(expected.stringValue)")
                            print("      \(actualLabel):   \(actual.stringValue)")
                        }

                        // Structured diff
                        if let difference = failure.difference {
                            print("")
                            printIndented(render(difference), indent: "      ")
                        }

                        // User comment
                        if let comment = failure.comment {
                            print("      \(dimmed("—")) \(render(comment))")
                        }
                    }
                }

            case .runEnded:
                print("")
                print("Test run complete:")
                let passed = Console.Style.success.apply(
                    to: "  Passed:  \(passedCount)", capability: capability
                )
                print(passed)
                if failedCount > 0 {
                    let failed = Console.Style.error.apply(
                        to: "  Failed:  \(failedCount)", capability: capability
                    )
                    print(failed)
                }
                if skippedCount > 0 {
                    print(dimmed("  Skipped: \(skippedCount)"))
                }
                if issueCount > 0 {
                    let issues = Console.Style.warning.apply(
                        to: "  Issues:  \(issueCount)", capability: capability
                    )
                    print(issues)
                }

            case .planCreated:
                break

            case .caseStarted, .caseEnded:
                break

            case .custom:
                break
            }
        }

        func finish() async {
            // Flush is automatic with print()
        }

        // MARK: - Rendering Helpers

        private func render(_ text: Test.Text) -> Swift.String {
            text.segments.map { segment in
                consoleStyle(for: segment.style)
                    .apply(to: segment.content, capability: capability)
            }.joined()
        }

        private func dimmed(_ text: Swift.String) -> Swift.String {
            Console.Style.dim.apply(to: text, capability: capability)
        }

        private func printIndented(_ text: Swift.String, indent: Swift.String) {
            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                print("\(indent)\(line)")
            }
        }

        private func consoleStyle(
            for style: Test.Text.Segment.Style
        ) -> Console.Style {
            switch style {
            case .plain:        .plain
            case .identifier:   Console.Style(foreground: .palette(.cyan))
            case .value:        Console.Style(foreground: .palette(.yellow))
            case .keyword:      Console.Style(foreground: .palette(.magenta))
            case .punctuation:  .plain
            case .emphasis:     .bold
            case .secondary:    .dim
            case .success:      .success
            case .failure:      .error
            case .warning:      .warning
            case .diffAdded:    Console.Style(foreground: .palette(.green))
            case .diffRemoved:  Console.Style(foreground: .palette(.red))
            case .diffContext:  .dim
            }
        }
    }
}
