import Testing
import Testing_Test_Support
import Test_Primitives

extension Testing {
    @Suite
    struct MacroSupportTest {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Testing.MacroSupportTest.Unit {
    @Testing.Test
    func `__TestID resolves to Test.ID`() {
        let id = Testing.__TestID(
            module: "TestModule",
            name: "testFunc",
            sourceLocation: .init(
                fileID: "test/file.swift",
                filePath: "/test/file.swift",
                line: 1,
                column: 1
            )
        )
        #expect(id.name == "testFunc")
        #expect(id.module == "TestModule")
    }

    @Testing.Test
    func `__TestSourceLocation resolves to Test.Source.Location`() {
        let location = Testing.__TestSourceLocation(
            fileID: "module/file.swift",
            filePath: "/path/to/file.swift",
            line: 42,
            column: 10
        )
        #expect(location.line == 42)
        #expect(location.column == 10)
    }

    @Testing.Test
    func `__TestTrait resolves to Test.Trait`() {
        let trait: Testing.__TestTrait = .enabled(true)
        if case .enabled(true, _) = trait.kind {} else {
            Issue.record("Expected .enabled(true) trait")
        }
    }

    @Testing.Test
    func `__TestBody resolves correctly`() {
        let body: Testing.__TestBody = .sync {}
        // Body exists and was constructed successfully
        _ = body
    }
}
