import Testing
@testable import LaunchDUI

@Suite("LaunchctlDisabledParser")
struct LaunchctlDisabledParserTests {

    static let sampleOutput = """
    disabled services = {
        "com.apple.Safari" => enabled
        "com.example.disabled" => disabled
        "com.example.also.disabled" => disabled
        "com.example.enabled" => enabled
    }
    """

    @Test("Identifies disabled services")
    func identifiesDisabled() {
        let disabled = LaunchctlDisabledParser.parse(Self.sampleOutput)
        #expect(disabled.contains("com.example.disabled"))
        #expect(disabled.contains("com.example.also.disabled"))
    }

    @Test("Does not include enabled services")
    func excludesEnabled() {
        let disabled = LaunchctlDisabledParser.parse(Self.sampleOutput)
        #expect(!disabled.contains("com.apple.Safari"))
        #expect(!disabled.contains("com.example.enabled"))
    }

    @Test("Correct count")
    func correctCount() {
        let disabled = LaunchctlDisabledParser.parse(Self.sampleOutput)
        #expect(disabled.count == 2)
    }

    @Test("Handles empty input")
    func handlesEmpty() {
        let disabled = LaunchctlDisabledParser.parse("")
        #expect(disabled.isEmpty)
    }

    @Test("Handles empty braces")
    func handlesEmptyBlock() {
        let output = "disabled services = {\n}\n"
        let disabled = LaunchctlDisabledParser.parse(output)
        #expect(disabled.isEmpty)
    }
}
