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
    func `init creates default configuration with nil filter`() {
        let config = Testing.Configuration()
        #expect(config.filter == nil)
    }

    @Testing.Test
    func `init creates default configuration with nil tags`() {
        let config = Testing.Configuration()
        #expect(config.tags == nil)
    }

    @Testing.Test
    func `init creates default configuration with automatic concurrency`() {
        let config = Testing.Configuration()
        if case .automatic = config.concurrency {} else {
            Issue.record("Expected .automatic concurrency")
        }
    }

    @Testing.Test
    func `init creates default configuration with console output format`() {
        let config = Testing.Configuration()
        if case .console = config.outputFormat {} else {
            Issue.record("Expected .console output format")
        }
    }

    @Testing.Test
    func `init creates default configuration with nil output path`() {
        let config = Testing.Configuration()
        #expect(config.outputPath == nil)
    }

    @Testing.Test
    func `stub factory creates configuration with provided values`() {
        let config = Testing.Configuration.stub(
            filter: "MyTest",
            concurrency: .serial,
            outputFormat: .json
        )
        #expect(config.filter == "MyTest")
        if case .serial = config.concurrency {} else {
            Issue.record("Expected .serial concurrency")
        }
        if case .json = config.outputFormat {} else {
            Issue.record("Expected .json output format")
        }
    }
}

// MARK: - EdgeCase

extension Testing.Configuration.Test.EdgeCase {
    @Testing.Test
    func `fromEnvironment with no env vars returns defaults`() {
        let config = Testing.Configuration.fromEnvironment()
        #expect(config.outputPath == nil)
    }
}
