# swift-testing

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Macro-based test authoring and execution for Swift: `@Test`, `@Suite`, `#expect`, and `#require`, with runtime discovery, a configurable parallel runner, and typed throws end-to-end.

The macro surface mirrors the familiar `@Test` / `#expect` idiom, so test code reads the way Swift tests already read — while running on this package's own discovery and runner infrastructure, and adding `#Tests` suite scaffolding, scoped dependency overrides, and effect spies.

---

## Key Features

- **Macro test authoring** — `@Test`, `@Suite`, `#expect`, `#require` with traits (`.tag(_:)`, `.timeLimit(_:)`, `.enabled(if:)`, `.serialized`)
- **Expression capture** — `#expect(result == 42)` records the source expression and captured values in failure diagnostics
- **Parametric tests** — `@Test(arguments:)` runs once per element, or over the Cartesian product of two collections
- **Runtime discovery** — section-based enumeration of `@Test` functions with a dynamic-loader fallback; no manifest to maintain
- **Suite scaffolding** — `#Tests` generates a standardized `Test` enum with `Unit`, `EdgeCase`, `Integration`, `Performance`, and `Snapshot` categories, including snapshot recording-mode configuration
- **Scoped dependency overrides** — `Test.withDependencies { ... }` resolves unset dependencies to their test values within the operation, preserving typed throws and actor isolation
- **Effect spies** — the `Testing Effects` product records effect invocations (`spy.callCount`, `spy.firstInvocation`) for testing effect handlers

---

## Quick Start

```swift
import Testing

@Suite(.serialized)
struct ParserTests {
    @Test
    func parsesInteger() throws {
        let value = try #require(Int("42"))   // unwraps, or stops the test
        #expect(value == 42)                  // records failure, continues
    }

    @Test(arguments: ["", " ", "abc"])
    func rejectsNonNumeric(input: String) {
        #expect(Int(input) == nil)
    }
}
```

On failure, `#expect` reports the captured expression and values:

```
Expectation failed: value == 42
- value: 41
- expected: 42
```

Tests run through the package's own entry point:

```swift
@main
struct TestRunner {
    static func main() async throws {
        try await Testing.main()
    }
}
```

### Dependency overrides

Override dependencies for a single test scope; unset dependencies resolve to their `testValue`:

```swift
import Testing

@Test
func featureUsesAPI() async throws {
    try await Test.withDependencies {
        $0[APIClient.self] = .mock
    } operation: {
        let result = try await loadData()
        #expect(!result.isEmpty)
    }
}
```

---

## Installation

Add swift-testing to your `Package.swift` (pre-tag — pin to `main`):

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-testing.git", branch: "main")
]
```

Add the product to your test target:

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "Testing", package: "swift-testing")
    ]
)
```

### Requirements

- Swift 6.3.1+ toolchain
- macOS 26+, iOS 26+, tvOS 26+, watchOS 26+, visionOS 26+

---

## Products

| Product | When to import |
|---------|----------------|
| `Testing` | Test targets — full surface: macros plus everything below |
| `Testing Core` | Programmatic use of discovery, configuration, and the runner without the macros |
| `Testing Effects` | Testing effect handlers — adds `Test.spy(for:returning:)` and effect assertion helpers |
| `Testing Test Support` | Shared helpers for this package's own test infrastructure |

The `Testing` umbrella re-exports the core implementation together with the SwiftSyntax types needed for `assertMacroExpansion` when testing your own macros.

---

## Configuration

The runner reads its configuration from environment variables (`Testing.Configuration.current`):

| Variable | Effect |
|----------|--------|
| `SWIFT_TEST_FILTER` | Filter tests by name substring |
| `SWIFT_TEST_TAGS` | Comma-separated tag filter |
| `SWIFT_TEST_PARALLEL` | `0` = serial; `N` = at most N concurrent tests |
| `SWIFT_TEST_OUTPUT` | `json` for JSON output |
| `SWIFT_TEST_OUTPUT_PATH` | Write output to a file instead of the console |

A run that contains failures throws `Testing.Run.Error.failed(_:)` carrying the runner result; the SwiftPM entry point converts this to a nonzero exit status.

---

## Stability

swift-testing is pre-1.0 and under active development. Public macro names and the `Testing` entry-point surface are stable within the current line; discovery and runner internals are not part of the source-stability commitment. Macro expansion tests are currently disabled pending test-content-record bridging.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at the first public release.*
<!-- END: discussion -->

---

## License

Apache 2.0. See [LICENSE](LICENSE.md) for details.
