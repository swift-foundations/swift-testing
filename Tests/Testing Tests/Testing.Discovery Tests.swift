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
    func sectionsReturnsARegistry() {
        let registry = Testing.Discovery.sections()
        // Registry was constructed — section enumeration completed without crash
        _ = registry
    }

    @Testing.Test
    func allReturnsARegistry() {
        let registry = Testing.Discovery.all()
        _ = registry
    }
}
