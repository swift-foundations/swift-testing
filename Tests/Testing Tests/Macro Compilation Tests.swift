import Testing
import Testing_Test_Support

@Suite
struct `Macro Compilation Tests` {
    @Suite struct Integration {}
}

// MARK: - Integration

extension MacroCompilationTests.Integration {
    @Testing.Test
    func testOnFreeFunctionCompiles() {
        // This test itself uses @Test — if it compiles, the macro works
    }

    @Testing.Test
    func testAsyncFunctionCompiles() async {
        // Async @Test compiles successfully
    }

    @Testing.Test
    func expectWithBoolCompiles() {
        #expect(true)
    }

    @Testing.Test
    func expectWithCommentCompiles() {
        #expect(true, "always true")
    }

    @Testing.Test
    func requireWithBoolCompiles() throws {
        try #require(true)
    }

    @Testing.Test
    func requireWithOptionalUnwrappingCompiles() throws {
        let value: Int? = 42
        let unwrapped = try #require(value)
        #expect(unwrapped == 42)
    }
}
