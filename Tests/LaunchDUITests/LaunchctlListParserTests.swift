import Testing
@testable import LaunchdUI

@Suite("LaunchctlListParser")
struct LaunchctlListParserTests {

    static let sampleOutput = """
    PID\tStatus\tLabel
    501\t0\tcom.apple.Spotlight
    -\t0\tcom.apple.metadata.mds
    1234\t0\tcom.example.running
    -\t78\tcom.example.error
    -\t-9\tcom.example.killed
    -\t0\tcom.example.idle
    """

    @Test("Parses running service with PID")
    func parsesRunningService() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        let spotlight = entries.first { $0.label == "com.apple.Spotlight" }
        #expect(spotlight != nil)
        #expect(spotlight?.pid == 501)
        #expect(spotlight?.lastExitStatus == 0)
    }

    @Test("Parses service without PID")
    func parsesNoPid() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        let mds = entries.first { $0.label == "com.apple.metadata.mds" }
        #expect(mds != nil)
        #expect(mds?.pid == nil)
        #expect(mds?.lastExitStatus == 0)
    }

    @Test("Parses non-zero exit status")
    func parsesErrorExitStatus() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        let errorService = entries.first { $0.label == "com.example.error" }
        #expect(errorService != nil)
        #expect(errorService?.lastExitStatus == 78)
    }

    @Test("Parses negative exit status (signal)")
    func parsesSignalExitStatus() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        let killed = entries.first { $0.label == "com.example.killed" }
        #expect(killed != nil)
        #expect(killed?.lastExitStatus == -9)
    }

    @Test("Skips header line")
    func skipsHeader() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        let header = entries.first { $0.label == "Label" }
        #expect(header == nil)
    }

    @Test("Correct total count")
    func correctCount() {
        let entries = LaunchctlListParser.parse(Self.sampleOutput)
        #expect(entries.count == 6)
    }

    @Test("Handles empty input")
    func handlesEmpty() {
        let entries = LaunchctlListParser.parse("")
        #expect(entries.isEmpty)
    }

    @Test("Handles lines with extra whitespace")
    func handlesWhitespace() {
        let output = " 100 \t 0 \t com.test.service \n"
        let entries = LaunchctlListParser.parse(output)
        #expect(entries.count == 1)
        #expect(entries.first?.pid == 100)
        #expect(entries.first?.label == "com.test.service")
    }
}
