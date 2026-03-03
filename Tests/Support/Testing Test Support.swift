public import Testing_Core

// MARK: - Testing.Configuration Factory

extension Testing.Configuration {
    /// Creates a configuration with sensible test defaults.
    ///
    /// ```swift
    /// let config = Testing.Configuration.stub()
    /// let config = Testing.Configuration.stub(filter: "MyTest")
    /// ```
    public static func stub(
        filter: Swift.String? = nil,
        tags: Swift.Set<Swift.String>? = nil,
        concurrency: Test_Primitives.Test.Runner.Concurrency = .serial,
        output: Output = Output()
    ) -> Self {
        var config = Self()
        config.filter = filter
        config.tags = tags
        config.concurrency = concurrency
        config.output = output
        return config
    }
}
