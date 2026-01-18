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
public import Time_Primitives

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
        private var passedCount = 0
        private var failedCount = 0
        private var skippedCount = 0
        private var issueCount = 0

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
                    let symbol: String
                    switch result {
                    case .passed:
                        symbol = "✓"
                        passedCount += 1
                    case .failed:
                        symbol = "✗"
                        failedCount += 1
                    case .skipped:
                        symbol = "○"
                        skippedCount += 1
                    }

                    var message = "  \(symbol) \(id.name)"
                    if let elapsed = event.elapsed {
                        message += " (\(elapsed.formatted(.duration)))"
                    }
                    print(message)
                }

            case .testSkipped(let reason):
                skippedCount += 1
                if let id = event.id {
                    var message = "  ○ \(id.name) (skipped)"
                    if let reason {
                        message += ": \(reason.plainText)"
                    }
                    print(message)
                }

            case .issueRecorded(let issue):
                issueCount += 1
                print("    ⚠ \(issue.kind)")
                if let context = issue.context {
                    print("      \(context.plainText)")
                }

            case .expectationChecked(let expectation):
                if expectation.isFailing {
                    print("    ✗ \(expectation.expression.sourceCode)")
                    if let failure = expectation.failure {
                        print("      \(failure.message.plainText)")
                    }
                }

            case .runEnded:
                print("")
                print("Test run complete:")
                print("  Passed:  \(passedCount)")
                if failedCount > 0 {
                    print("  Failed:  \(failedCount)")
                }
                if skippedCount > 0 {
                    print("  Skipped: \(skippedCount)")
                }
                if issueCount > 0 {
                    print("  Issues:  \(issueCount)")
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
    }
}
