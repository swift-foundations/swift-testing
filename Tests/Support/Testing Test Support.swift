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
        outputFormat: OutputFormat = .console,
        outputPath: Swift.String? = nil
    ) -> Self {
        var config = Self()
        config.filter = filter
        config.tags = tags
        config.concurrency = concurrency
        config.outputFormat = outputFormat
        config.outputPath = outputPath
        return config
    }
}
