import Testing
import Testing_Test_Support

extension Testing.Configuration {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Testing.Configuration.Test.Unit {
    @Testing.Test
    func initCreatesDefaultConfigurationWithNilFilter() {
        let config = Testing.Configuration()
        #expect(config.filter == nil)
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithNilTags() {
        let config = Testing.Configuration()
        #expect(config.tags == nil)
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithAutomaticConcurrency() {
        let config = Testing.Configuration()
        if case .automatic = config.concurrency {
        } else {
            #expect(false, "Expected .automatic concurrency")
        }
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithTeeOutputFormat() {
        // Default is .tee (console + structured JSONL) since e1e5cff.
        let config = Testing.Configuration()
        if case .tee = config.output.format {
        } else {
            #expect(false, "Expected .tee output format")
        }
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithNilOutputPath() {
        let config = Testing.Configuration()
        #expect(config.output.path == nil)
    }

    @Testing.Test
    func stubFactoryCreatesConfigurationWithProvidedValues() {
        let config = Testing.Configuration.stub(
            filter: "MyTest",
            concurrency: .serial,
            output: .init(format: .json)
        )
        #expect(config.filter == "MyTest")
        if case .serial = config.concurrency {
        } else {
            #expect(false, "Expected .serial concurrency")
        }
        if case .json = config.output.format {
        } else {
            #expect(false, "Expected .json output format")
        }
    }
}

// MARK: - EdgeCase

extension Testing.Configuration.Test.EdgeCase {
    @Testing.Test
    func currentWithNoEnvVarsReturnsDefaults() {
        let config = Testing.Configuration.current
        #expect(config.output.path == nil)
    }
}
