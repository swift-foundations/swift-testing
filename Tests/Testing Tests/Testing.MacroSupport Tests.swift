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
    func testIDResolvesToTestID() {
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
    func testSourceLocationResolvesToTestSourceLocation() {
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
    func testTraitResolvesToTestTrait() {
        let trait: Testing.__TestTrait = .enabled(if: true)
        if case .enabled(true, _) = trait.kind {} else {
            #expect(Bool(false), "Expected .enabled(true) trait")
        }
    }

    @Testing.Test
    func testBodyResolvesCorrectly() {
        let body: Testing.__TestBody = .sync {}
        // Body exists and was constructed successfully
        _ = body
    }
}
