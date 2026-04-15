# Audit: swift-testing

## Legacy — Consolidated 2026-04-08

### From: audit-tests.md (2026-03-11)

**Package**: swift-tests (Layer 3)
**Scope**: All source targets (Tests Core, Tests Snapshot, Tests Inline Snapshot, Tests Performance, Tests Reporter, Tests, Tests Apple Testing Bridge, Tests Test Support)

**19 findings** — all OPEN

| ID | Severity | Finding | Est. LOC saved |
|----|----------|---------|---------------|
| 1 | Trivial | 4 dead/empty files (moved-to-L1 stubs, empty namespace) | 26 (4 files deleted) |
| 2 | Low | Sanitization logic duplicated in 4 locations (identical path-component sanitizer) | ~60 |
| 3 | Medium | Storage pattern duplicated across 3 types (ensureDirectory, error types, formatting) | ~100 |
| 4 | Medium | 13 sync/async overload pairs with no shared implementation | ~300 |
| 5 | Medium | 3 redundant measurement entry points with duplicated warmup+measurement loops | ~60 |
| 6 | Low | 2 hand-rolled JSON serializers despite existing swift-json dependency | ~80 |
| 7 | Medium | 3 overlapping error hierarchies for performance threshold failures | ~30 |
| 8 | Low | Bridge resolution (`_resolveBridge`) evaluated on every failure path, even when collector active | — |
| 9 | Low | `Test.Plan.filter` rebuilds plans via flat entries, losing tree structure | — |
| 10 | Low | Expectation construction boilerplate repeated 5 times (~100 lines) | ~60 |
| 11 | Low | Dead counter API in snapshot storage (always called with `counter: 0`) | — |
| 12 | Low | `Plan.count` is O(n) but API suggests O(1) | — |
| 13 | Low | 8 nearly identical JSON strategy factory methods across 2 files | ~40 |
| 14 | Medium | Faceted snapshot sync/async duplication (80-line near-identical functions) | (included in #4) |
| 15 | Low | `Tests.Suite.report()` duplicates box-drawing formatting from `Tests.report(comparisons:)` | — |
| 16 | Trivial | Deprecated `RequirementFailed` typealias still present | — |
| 17 | Trivial | `Test.Benchmark.swift` is empty (covered by #1) | (included in #1) |
| 18 | Trivial | `Test.Box` is a single-line typealias — justified by [API-IMPL-005], no action | — |
| 19 | Low | `Snapshot.Counter` uses `Mutex(())` instead of idiomatic `Mutex<[String: Int]>` | — |

**Total estimated savings**: ~750 lines across actionable findings.

---

### From: audit-testing.md (2026-03-11)

**Package**: swift-testing (Layer 3)
**Scope**: Testing Core, Testing Umbrella, Testing Macros Implementation, Testing Effects, Testing Test Support, Testing Tests

**33 findings** (F-1 through F-33) — all OPEN

**HIGH priority (structural)**:

| ID | Finding | Est. LOC saved |
|----|---------|---------------|
| F-17/F-18 | Duplicated section record + legacy container emission between TestMacro and SuiteMacro | ~60 |
| F-11 | 4 redundant re-exports in umbrella (already transitive via Testing_Core) | 4 |
| F-31 | 2 redundant dependencies in umbrella Package.swift target | 2 |
| F-3 | Dead `__createRegistration` code (superseded by section-record approach) | 17 |
| F-1 | `Testing.Reporter` is pure pass-through wrapper to `Test.Reporter` | 15 |

**MEDIUM priority (code quality)**:

| ID | Finding |
|----|---------|
| F-16 | Duplicated `extractTraits` between TestMacro and SuiteMacro |
| F-23 | ExpectMacro and RequireMacro are functionally identical (differ only by function name) |
| F-5 | Dead filter/tags configuration: parsed from env vars but never applied |
| F-19 | Unused `.requiresStruct` error case in TestMacro.Error |
| F-20 | No-op `MemberAttributeMacro` conformance on SuiteMacro |
| F-15 | `assertMacroExpansion` reports only first failure, discards rest |
| F-2 | `__expect`/`__require` forwarding wrappers (could use module-qualified calls) |

**LOW priority (cleanup)**:

| ID | Finding |
|----|---------|
| F-4 | Possibly redundant `Time_Primitives` re-export |
| F-6 | Inconsistent `__` prefix on macro typealiases |
| F-7 | `isEmpty` fileprivate extension belongs upstream in swift-tests |
| F-10 | `lookupSymbol` swallows errors silently |
| F-12 | SwiftSyntax re-exports pollute Testing namespace (~1000+ types) |
| F-13 | `__TestingRunner` in umbrella causes potential multi-target duplication |
| F-28 | XCTestBridge manual mirroring of every @Test function |
| F-30 | Macro Expansion Tests target commented out in Package.swift |

**No action needed**: F-8, F-9, F-14, F-22, F-24, F-25, F-26, F-27, F-29, F-32 (depends on F-3), F-33.

---

### From: audit-test-primitives.md (2026-03-11)

**Package**: swift-test-primitives (Layer 1)
**Scope**: Test Primitives Core (31 files), Test Snapshot Primitives (16 files), Test Primitives Standard Library Integration (2 files), umbrella (1 file), test support (2 files), tests (22 files)

**15 findings** — all OPEN

| ID | Severity | Finding |
|----|----------|---------|
| F-1 | MEDIUM | Double diff computation in `.lines` diffing — diff algorithm runs twice on same input |
| F-2 | LOW | `p50` and `median` are identical delegations in `Test.Benchmark.Measurement` |
| F-3 | LOW | `Recording.description` manually reimplements `rawValue` |
| F-4 | LOW | `Test.Trait.Kind.description` silently drops comment for `.enabled(true, _)` |
| F-5 | LOW | `Test.Text.stub()` is trivial wrapper around existing init |
| F-6 | LOW | `Test.Trait` stub factories are trivial renames of production factory methods |
| F-7 | LOW | `OptionalProtocol` internal helper — consolidation candidate if pattern exists elsewhere |
| F-8 | LOW | `Measurement.Comparable` compares by median only, ignoring distribution |
| F-9 | LOW | Manual `Codable` + manual `Comparable` + no `Hashable` is fragile combination |
| F-10 | LOW | `Test.Snapshot.Inline` is empty namespace — could move to swift-tests |
| F-11 | LOW | `Complexity.evidence()` manually computes CV instead of using `Sample.Batch` |
| F-12 | LOW | `Trend.Interpretation` uses stringly-typed struct instead of enum |
| F-13 | LOW | Bool tuple extensions (2-6 arity) are manually written |
| F-14 | LOW | `Strategy` stores redundant sync+async closures |
| F-15 | LOW | `SimplyStrategy` typealias appears unused externally |

**Summary**: 1 MEDIUM (double diff — performance impact), 14 LOW. Package is well-structured with clean separation. No dead code, no Foundation imports, all files follow one-type-per-file.

---

### From: naming-implementation-audit-swift-tests-swift-testing.md (2026-03-26)

**Package**: swift-testing (Layer 3)
**Scope**: Naming + implementation audit against `/naming` and `/implementation` skills
**Violations**: 42 total (17 compound types, 13 compound methods/properties, 12 implementation)

#### Priority 1 -- Active Defects & Dead Code

| ID | File | Line | Finding |
|----|------|------|---------|
| I15 | `Testing/Testing.Reporter.Console.swift` | 87 | `reason.plainText` discards styling (BEHAVIORAL DEFECT). `reason` is `Test.Text` (styled). `ConsoleSink` already has `render(_ text: Test.Text) -> String` at line 178. Using `.plainText` strips all styling. Fix: `render(reason)`. |

#### Priority 2 -- Public Compound Type Names [API-NAME-001]

| ID | File | Line | Current | Fix |
|----|------|------|---------|-----|
| N33 | `Testing Macros Implementation/ExpectMacro.swift` | 37 | `ExpectMacro` | `Expect.Macro` |
| N34 | `Testing Macros Implementation/ExpectMacro.swift` | 67 | `ExpectMacroError` | Nest as `Error` inside renamed parent |
| N35 | `Testing Macros Implementation/RequireMacro.swift` | 30 | `RequireMacro` | `Require.Macro` |
| N36 | `Testing Macros Implementation/RequireMacro.swift` | 62 | `RequireMacroError` | Nest as `Error` inside renamed parent |
| N37 | `Testing Macros Implementation/TestMacro.swift` | 20 | `TestMacro` | `Test.Macro` |
| N38 | `Testing Macros Implementation/TestMacro.swift` | 182 | `MacroError` | Nest as `Test.Macro.Error` or `Macro.Error` |
| N39 | `Testing Macros Implementation/TestsMacro.swift` | 50 | `TestsMacro` | `Tests.Macro` |
| N40 | `Testing Macros Implementation/SuiteMacro.swift` | 29 | `SuiteMacro` | `Suite.Macro` |
| N41 | `Testing Macros Implementation/SnapshotMacro.swift` | 22 | `SnapshotMacro` | `Snapshot.Macro` |
| N42 | `Testing Macros Implementation/SnapshotMacro.swift` | 115 | `SnapshotMacroError` | Nest as `Error` inside parent |
| N43 | `Testing Macros Implementation/Plugin.swift` | 16 | `TestingMacrosPlugin` | `Testing.Macros.Plugin` or `Plugin` |
| N44 | `Testing/Testing.Reporter.JSONSink.swift` | 26 | `JSONSink` (internal) | Nest under reporter namespace |
| N45 | `Testing/Testing.Reporter.Console.swift` | 35 | `ConsoleSink` (private) | Nest under reporter namespace |
| N46 | `Testing/Testing.MacroSupport.swift` | 48 | `SuiteRegistration` | Remove or nest properly |
| N47 | `Testing/Testing.MacroSupport.swift` | 93 | `FactoryFunction` | Nest as `Factory.Function` or similar |
| N49 | `Testing Umbrella/Testing.XCTestBridge.swift` | 32 | `__TestingRunner` | Compound. Constrained by XCTest bridge ABI -- document as [PATTERN-016] conscious debt if cannot rename |

**ABI-constrained** (flag but may require [PATTERN-016] documentation rather than rename):

| ID | File | Line | Identifiers |
|----|------|------|-------------|
| N48 | `Testing/Testing.MacroSupport.swift` | 23-54 | `__TestID`, `__TestSourceLocation`, `__TestTrait`, `__TestBody`, `__TestContentRecord`, `__TestContentRecordAccessor`, `__TestContentKind`, `__TestTraitCollectionModifier`, `__TestContentRecordContainer` |

These are `public typealias` declarations referenced from macro-generated code across module boundaries. The `__` prefix marks them as ABI. Renaming requires updating all macro codegen sites.

#### Priority 4 -- Public Compound Methods/Properties [API-NAME-002]

| ID | File | Line | Current | Suggested |
|----|------|------|---------|-----------|
| N50 | `Testing/Testing.Configuration.swift` | 50 | `fromEnvironment()` | Static property `.current` or `init()` |
| N51 | `Testing/Testing.Discovery.swift` | 31 | `discoverFromSections()` | `discover(from: .sections)` or restructure |
| N52 | `Testing/Testing.Discovery.swift` | 124 | `discoverFromTypeMetadata()` | `discover(from: .typeMetadata)` |
| N53 | `Testing/Testing.Discovery.swift` | 223 | `discoverAll(fallbackFactoryNames:)` | `discover(all:)` |
| N54 | `Testing/Testing.Main.swift` | 85 | `runAll()` | `run()` (context is `Testing.Main`) |
| N55 | `Testing/Testing.Configuration.swift` | 35 | `outputFormat` | Nest as `output.format` |
| N56 | `Testing/Testing.Configuration.swift` | 38 | `outputPath` | Nest as `output.path` |

#### Priority 5 -- Private Compound Methods [API-NAME-002]

Not exempted by [IMPL-024] (which only covers `private static`). Lower priority since non-public.

| ID | File | Line | Current |
|----|------|------|---------|
| N57 | `Testing/Testing.Reporter.JSONSink.swift` | 55 | `buildJSON()` |
| N58 | `Testing/Testing.Reporter.JSONSink.swift` | 68 | `eventToJSON(_:)` |
| N59 | `Testing/Testing.Reporter.JSONSink.swift` | 82 | `writeToFile(path:bytes:)` |
| N60 | `Testing/Testing.Reporter.JSONSink.swift` | 107 | `writeToStdout(bytes:)` |
| N61 | `Testing/Testing.Reporter.Console.swift` | 180 | `consoleStyle(for:)` |
| N62 | `Testing/Testing.Reporter.Console.swift` | 189 | `printIndented(_:indent:)` |

#### Priority 6 -- Implementation Violations [IMPL-*]

**`.rawValue` at call sites [PATTERN-017]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I16 | `Testing/Testing.Discovery.swift` | 86, 136 | `record.kind == Test.__TestContentKind.test.rawValue` |
| I17 | `Testing Macros Implementation/SuiteMacro.swift` | 87 | `.rawValue` in tuple construction |
| I18 | `Testing Macros Implementation/TestMacro.swift` | 141 | `.rawValue` in tuple construction |

**`Int(...)` / raw conversions at call sites [IMPL-010] / [IMPL-002]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I19 | `Testing Umbrella/Testing.AssertMacroExpansion.swift` | 83-84 | `Int(spec.location.line)`, `Int(spec.location.column)` |
| I20 | `Testing/Testing.Discovery.swift` | 98, 147 | `UnsafeRawPointer(bitPattern: 1)!` sentinel |
| I26 | `Testing/Testing.Reporter.JSONSink.swift` | 74-75 | `attoseconds / 1_000_000_000` raw unit conversion |

**Unnecessary intermediate bindings [IMPL-EXPR-001] / [IMPL-030]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I21 | `Testing/Testing.Discovery.swift` | 109, 157, 191 | `let reg = boxed.value` -- single-use x3 |
| I22 | `Testing/Testing.Discovery.swift` | 96-100, 145-149 | `let success` -- single-use, immediately guarded x2 |
| I23 | `ExpectMacro.swift` / `RequireMacro.swift` | 47-52 / 40-45 | Two-branch `let comment` -- should be ternary |
| I24 | `Testing.Reporter.Console.swift` | 94, 102 | `let marker` -- single-use x2, inline |
| I25 | `Testing.Reporter.Console.swift` | 141-159 | `let passed`, `let failed`, `let issues` -- inline; inconsistent with `dimmed()` in same block |

#### Summary

| Category | Count |
|----------|:-----:|
| [API-NAME-001] compound types | 17 |
| [API-NAME-002] compound methods/properties | 13 |
| [IMPL-*] implementation | 12 |
| **Total** | **42** |

---

### From: swift-institute/Research/platform-compliance-audit.md (2026-03-19)

**Skill**: platform — [PLAT-ARCH-001-010], [PATTERN-001], [PATTERN-004a], [PATTERN-005]

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| L-2 | LOW | [PLAT-ARCH-008] | Testing.Discovery.swift:41 | `#if canImport(Darwin)` fallback for older Darwin binaries using `__DATA` instead of `__DATA_CONST` section. | OPEN — Remove when minimum deployment target advances |
| L-3 | LOW | [PLAT-ARCH-008] | Macro.Shared.swift:53-57 | `@_section` attribute names differ by platform (Mach-O/ELF/PE). Fix: Use `Loader.Section.Name` constants from swift-loader-primitives. | OPEN |

---

### From: swift-institute/Research/modularization-audit-foundations-batch-A.md (2026-03-20)

**Modularization compliance — MOD-001 through MOD-014**

**Targets**: Testing Core (10 -- path: `Sources/Testing`), Testing (8 -- umbrella, path: `Sources/Testing Umbrella`), Testing Macros Implementation (6 -- macro), Testing Effects (2), Testing Test Support (2)

| Rule | Verdict | Notes |
|------|---------|-------|
| MOD-001 Core | PASS | `Testing Core` (10 files) is properly named and serves as the Core. All other targets depend on it. |
| MOD-002 Ext Dep Central | PASS | Testing Core re-exports Tests, Dependencies, Time Primitives, etc. Variants add only their specific externals (Effects, SwiftSyntax). |
| MOD-003 Variant Decomp | PASS | Testing Effects is independent of the umbrella. Testing Macros Implementation is independent (compiler plugin). |
| MOD-004 Constraint Iso | N/A | No ~Copyable types. |
| MOD-005 Umbrella | **FAIL** | `Testing` umbrella (8 files) contains implementation code: `Require.swift`, `Test.swift`, `Suite.swift`, `Testing.XCTestBridge.swift`, `Tests.swift`, `Expect.swift`, `Testing.AssertMacroExpansion.swift` plus `exports.swift`. These are macro declarations and bridge code that must coexist with the Testing_Core namespace. This may be a justified exception since macro declarations must live in the module that declares `@_exported import` of the macro implementation. |
| MOD-006 Dep Min | PASS | Deps are minimal. |
| MOD-007 Graph Shape | PASS | Max depth = 2 (Testing Core -> Testing / Testing Effects / Testing Test Support). |
| MOD-008 Split Decision | PASS | All targets have reasonable file counts (2-10). |
| MOD-009 Inline Variant | N/A | No inline variants. |
| MOD-010 StdLib Integration | N/A | No stdlib extensions observed. |
| MOD-011 Test Support | PASS | `Testing Test Support` published as library product. Depends on Testing Core + Tests Test Support. Path: `Tests/Support`. |
| MOD-012 Naming | PASS | Names follow `Testing {Variant}` pattern. Core, Effects, Test Support all correct for L3. |
| MOD-013 MARK | **FAIL** | 5 effective source targets (including macro). Zero `// MARK:` comments in Package.swift. There are comments (e.g., `// UMBRELLA TARGET`, `// Core implementation`) but they are not using `// MARK: -` format. |
| MOD-014 Cross-Pkg Traits | PASS | No trait-gated integrations. |

**Detailed Findings**:

1. **F-TESTING-001** (MOD-005): The `Testing` umbrella has 7 implementation files. This is a justified exception: macro declarations (`@Test`, `@Suite`, `#expect`, `#require`) must be in the same module as their `@_exported import Testing_Macros_Implementation`. The umbrella legitimately needs these declarations to make `import Testing` provide both the macro and the Test namespace. Document this as an accepted deviation.
2. **F-TESTING-002** (MOD-013): While descriptive comments exist (e.g., `// UMBRELLA TARGET - what users import as "Testing"`), they do not use the `// MARK: -` format specified by MOD-013.
