import Testing
import Testing_Test_Support

extension Testing.Discovery {
    @Suite
    struct Test {
        @Suite struct Integration {}
    }
}

// MARK: - Integration

extension Testing.Discovery.Test.Integration {
    @Testing.Test
    func `discoverFromSections returns a registry`() {
        let registry = Testing.Discovery.discoverFromSections()
        // Registry was constructed — section enumeration completed without crash
        _ = registry
    }

    @Testing.Test
    func `discoverAll returns a registry`() {
        let registry = Testing.Discovery.discoverAll()
        _ = registry
    }
}
