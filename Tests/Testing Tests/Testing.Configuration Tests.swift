import Testing
import Testing_Test_Support

extension Testing.Configuration {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
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
        if case .automatic = config.concurrency {} else {
            #expect(Bool(false), "Expected .automatic concurrency")
        }
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithConsoleOutputFormat() {
        let config = Testing.Configuration()
        if case .console = config.outputFormat {} else {
            #expect(Bool(false), "Expected .console output format")
        }
    }

    @Testing.Test
    func initCreatesDefaultConfigurationWithNilOutputPath() {
        let config = Testing.Configuration()
        #expect(config.outputPath == nil)
    }

    @Testing.Test
    func stubFactoryCreatesConfigurationWithProvidedValues() {
        let config = Testing.Configuration.stub(
            filter: "MyTest",
            concurrency: .serial,
            outputFormat: .json
        )
        #expect(config.filter == "MyTest")
        if case .serial = config.concurrency {} else {
            #expect(Bool(false), "Expected .serial concurrency")
        }
        if case .json = config.outputFormat {} else {
            #expect(Bool(false), "Expected .json output format")
        }
    }
}

// MARK: - EdgeCase

extension Testing.Configuration.Test.EdgeCase {
    @Testing.Test
    func fromEnvironmentWithNoEnvVarsReturnsDefaults() {
        let config = Testing.Configuration.fromEnvironment()
        #expect(config.outputPath == nil)
    }
}
