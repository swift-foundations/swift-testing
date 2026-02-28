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
    func `__expect with true returns passing expectation`() {
        let expectation = Testing.__expect(true)
        #expect(expectation.isPassing)
    }

    @Testing.Test
    func `__expect with false returns failing expectation`() {
        let expectation = Testing.__expect(false)
        #expect(expectation.isFailing)
    }

    @Testing.Test
    func `__require with true does not throw`() throws {
        try Testing.__require(true)
    }

    @Testing.Test
    func `__require with non-nil optional returns unwrapped value`() throws {
        let value: Int? = 42
        let unwrapped = try Testing.__require(value)
        #expect(unwrapped == 42)
    }
}

// MARK: - EdgeCase

extension Testing.HelpersTest.EdgeCase {
    @Testing.Test
    func `__require with false throws`() {
        #expect(throws: Test_Primitives.Test.Requirement.Failed.self) {
            try Testing.__require(false)
        }
    }

    @Testing.Test
    func `__require with nil optional throws`() {
        let value: Int? = nil
        #expect(throws: Test_Primitives.Test.Requirement.Failed.self) {
            try Testing.__require(value)
        }
    }
}
