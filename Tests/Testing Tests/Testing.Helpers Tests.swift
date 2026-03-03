import Testing
import Testing_Test_Support
import Test_Primitives

extension Testing {
    @Suite
    struct HelpersTest {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Testing.HelpersTest.Unit {
    @Testing.Test
    func expectWithTrueReturnsPassingExpectation() {
        let expectation = Testing.__expect(true)
        #expect(expectation.isPassing)
    }

    @Testing.Test
    func expectWithFalseReturnsFailingExpectation() {
        let collector = Test.Expectation.Collector()
        let expectation = Test.Expectation.Collector.$current.withValue(collector) {
            Testing.__expect(false)
        }
        #expect(expectation.isFailing)
    }

    @Testing.Test
    func requireWithTrueDoesNotThrow() throws {
        try Testing.__require(true)
    }

    @Testing.Test
    func requireWithNonNilOptionalReturnsUnwrappedValue() throws {
        let value: Int? = 42
        let unwrapped = try Testing.__require(value)
        #expect(unwrapped == 42)
    }
}

// MARK: - EdgeCase

extension Testing.HelpersTest.EdgeCase {
    @Testing.Test
    func requireWithFalseThrows() {
        let collector = Test.Expectation.Collector()
        do {
            try Test.Expectation.Collector.$current.withValue(collector) {
                try Testing.__require(false)
            }
            #expect(false, "Expected __require(false) to throw")
        } catch {
            // Typed throws guarantees error: Test.Requirement.Failed
            _ = error
        }
    }

    @Testing.Test
    func requireWithNilOptionalThrows() {
        let value: Int? = nil
        let collector = Test.Expectation.Collector()
        do {
            _ = try Test.Expectation.Collector.$current.withValue(collector) {
                try Testing.__require(value)
            }
            #expect(false, "Expected __require(nil) to throw")
        } catch {
            // Typed throws guarantees error: Test.Requirement.Failed
            _ = error
        }
    }
}
