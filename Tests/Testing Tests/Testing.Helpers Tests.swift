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
        let expectation = Testing.__expect(false)
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
        do {
            try Testing.__require(false)
            #expect(Bool(false), "Expected __require(false) to throw")
        } catch is Test_Primitives.Test.Requirement.Failed {
            // Expected
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Testing.Test
    func requireWithNilOptionalThrows() {
        let value: Int? = nil
        do {
            try Testing.__require(value)
            #expect(Bool(false), "Expected __require(nil) to throw")
        } catch is Test_Primitives.Test.Requirement.Failed {
            // Expected
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
