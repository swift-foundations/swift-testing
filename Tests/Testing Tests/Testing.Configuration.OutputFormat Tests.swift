import Testing
import Testing_Test_Support

extension Testing.Configuration.OutputFormat {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Testing.Configuration.OutputFormat.Test.Unit {
    @Testing.Test
    func `console and json cases are distinct`() {
        let console = Testing.Configuration.OutputFormat.console
        let json = Testing.Configuration.OutputFormat.json

        var config = Testing.Configuration()
        config.outputFormat = console
        if case .json = config.outputFormat {
            Issue.record("Console should not match json")
        }

        config.outputFormat = json
        if case .console = config.outputFormat {
            Issue.record("JSON should not match console")
        }
    }
}
