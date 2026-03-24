//
//  Testing.Run.Error.swift
//  swift-testing
//
//  Error thrown when a test run contains failures.
//

import Tests_Performance

extension Testing.Run {
    /// Error thrown when one or more tests in a run fail.
    public enum Error: Swift.Error, Sendable {
        /// The test run completed with failures.
        case failed(Test.Runner.Result)
    }
}
