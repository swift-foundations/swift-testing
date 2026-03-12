import Testing
import Testing_Test_Support

extension Testing.Configuration.Output.Format {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Testing.Configuration.Output.Format.Test.Unit {
    @Testing.Test
    func consoleAndJsonCasesAreDistinct() {
        let console = Testing.Configuration.Output.Format.console
        let json = Testing.Configuration.Output.Format.json

        var config = Testing.Configuration()
        config.output.format = console
        if case .json = config.output.format {
            #expect(false, "Console should not match json")
        }

        config.output.format = json
        if case .console = config.output.format {
            #expect(false, "JSON should not match console")
        }
    }
}
