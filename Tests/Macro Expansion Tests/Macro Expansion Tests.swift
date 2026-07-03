import Testing
import Testing_Macros_Implementation
import Testing_Test_Support

@Suite
struct MacroExpansionTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension MacroExpansionTests.Unit {
    @Testing.Test
    func `expect macro expands to __expect call`() throws {
        try assertMacroExpansion(
            """
            #expect(x == 1)
            """,
            expandedSource: """
                Testing.__expect(
                    x == 1,
                    nil,
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column
                )
                """,
            macros: ["expect": ExpectMacro.self]
        )
    }

    @Testing.Test
    func `expect with comment expands correctly`() throws {
        try assertMacroExpansion(
            """
            #expect(x == 1, "values should match")
            """,
            expandedSource: """
                Testing.__expect(
                    x == 1,
                    "values should match",
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column
                )
                """,
            macros: ["expect": ExpectMacro.self]
        )
    }

    @Testing.Test
    func `require macro expands to try __require call`() throws {
        try assertMacroExpansion(
            """
            #require(isValid)
            """,
            expandedSource: """
                try Testing.__require(
                    isValid,
                    nil,
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column
                )
                """,
            macros: ["require": RequireMacro.self]
        )
    }

    @Testing.Test
    func `require with comment expands correctly`() throws {
        try assertMacroExpansion(
            """
            #require(isValid, "must be valid")
            """,
            expandedSource: """
                try Testing.__require(
                    isValid,
                    "must be valid",
                    fileID: #fileID,
                    filePath: #filePath,
                    line: #line,
                    column: #column
                )
                """,
            macros: ["require": RequireMacro.self]
        )
    }

    @Testing.Test
    func `Tests macro expands to enum with 5 suites`() throws {
        try assertMacroExpansion(
            """
            extension MyType {
                #Tests
            }
            """,
            expandedSource: """
                extension MyType {
                    @Suite enum Test {
                        @Suite(.exclusive(group: "MyType")) struct Unit {}
                        @Suite(.exclusive(group: "MyType")) struct EdgeCase {}
                        @Suite(.exclusive(group: "MyType")) struct Integration {}
                        @Suite(.exclusive, .serialized) struct Performance {}
                        @Suite(.serialized) struct Snapshot {}
                    }
                }
                """,
            macros: ["Tests": TestsMacro.self]
        )
    }
}
