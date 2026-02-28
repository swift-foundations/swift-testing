import Testing
import Testing_Test_Support

extension Testing.Reporter {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Testing.Reporter.Test.Unit {
    @Testing.Test
    func `console factory creates a reporter`() {
        let reporter = Testing.Reporter.console
        // Reporter exists — verify it can create a sink
        let _ = reporter.makeSink()
    }

    @Testing.Test
    func `json factory with nil path creates a reporter`() {
        let reporter = Testing.Reporter.json(to: nil)
        let _ = reporter.makeSink()
    }
}
