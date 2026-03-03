import Testing
import Testing_Test_Support
import Testing_Macros_Implementation

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
    func `snapshot macro without named expands to __snapshotInline`() throws {
        try assertMacroExpansion(
            """
            #snapshot(output, as: .lines)
            """,
            expandedSource: """
            Testing.__snapshotInline(
                output,
                as: .lines,
                redacting: [],
                matches: nil,
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column,
                function: #function
            )
            """,
            macros: ["snapshot": SnapshotMacro.self]
        )
    }

    @Testing.Test
    func `snapshot macro with named expands to __snapshotFile`() throws {
        try assertMacroExpansion(
            """
            #snapshot(output, as: .lines, named: "baseline")
            """,
            expandedSource: """
            Testing.__snapshotFile(
                output,
                as: .lines,
                named: "baseline",
                redacting: [],
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column,
                function: #function
            )
            """,
            macros: ["snapshot": SnapshotMacro.self]
        )
    }

    @Testing.Test
    func `snapshot macro with labeled matches expands correctly`() throws {
        try assertMacroExpansion(
            """
            #snapshot(output, as: .lines, matches: { "expected" })
            """,
            expandedSource: """
            Testing.__snapshotInline(
                output,
                as: .lines,
                redacting: [],
                matches: { "expected" },
                fileID: #fileID,
                filePath: #filePath,
                line: #line,
                column: #column,
                function: #function
            )
            """,
            macros: ["snapshot": SnapshotMacro.self]
        )
    }

    @Testing.Test
    func `snapshot macro with named and labeled matches produces error`() throws {
        try assertMacroExpansion(
            """
            #snapshot(output, as: .lines, named: "x", matches: { "expected" })
            """,
            expandedSource: """
            #snapshot(output, as: .lines, named: "x", matches: { "expected" })
            """,
            diagnostics: [
                .init(
                    message: "#snapshot with 'named:' uses file-backed storage. Remove the trailing closure, or remove 'named:' to use inline comparison.",
                    line: 1,
                    column: 1
                )
            ],
            macros: ["snapshot": SnapshotMacro.self]
        )
    }

    @Testing.Test
    func `snapshot macro with named and trailing closure produces error`() throws {
        try assertMacroExpansion(
            """
            #snapshot(output, as: .lines, named: "x") { "expected" }
            """,
            expandedSource: """
            #snapshot(output, as: .lines, named: "x") { "expected" }
            """,
            diagnostics: [
                .init(
                    message: "#snapshot with 'named:' uses file-backed storage. Remove the trailing closure, or remove 'named:' to use inline comparison.",
                    line: 1,
                    column: 1
                )
            ],
            macros: ["snapshot": SnapshotMacro.self]
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
