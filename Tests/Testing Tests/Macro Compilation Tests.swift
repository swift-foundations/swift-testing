import Testing
import Testing_Test_Support

@Suite
struct MacroCompilationTests {
    @Suite struct Integration {}
}

// MARK: - Integration

extension MacroCompilationTests.Integration {
    @Testing.Test
    func `@Test on free function compiles`() {
        // This test itself uses @Test — if it compiles, the macro works
    }

    @Testing.Test
    func `@Test async function compiles`() async {
        // Async @Test compiles successfully
    }

    @Testing.Test
    func `#expect with bool compiles`() {
        #expect(true)
    }

    @Testing.Test
    func `#expect with comment compiles`() {
        #expect(true, "always true")
    }

    @Testing.Test
    func `#require with bool compiles`() throws {
        try #require(true)
    }

    @Testing.Test
    func `#require with optional unwrapping compiles`() throws {
        let value: Int? = 42
        let unwrapped = try #require(value)
        #expect(unwrapped == 42)
    }
}
