import Testing
@testable import LaunchDUI

@Suite("LaunchctlPrintParser")
struct LaunchctlPrintParserTests {

    static let sampleOutput = """
    com.example.service = {
        active count = 1
        path = /Library/LaunchDaemons/com.example.service.plist
        state = running
        program = /usr/bin/example
        pid = 1234
        last exit code = 0
        spawn type = daemon
        runs = 42
        timeout = 30
        domain = com.apple.xpc.launchd.domain.system
        type = LaunchDaemon
        working directory = /var/root
        some random key = ignored
    }
    """

    @Test("Parses state")
    func parsesState() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["state"] == "running")
    }

    @Test("Parses program")
    func parsesProgram() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["program"] == "/usr/bin/example")
    }

    @Test("Parses pid")
    func parsesPid() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["pid"] == "1234")
    }

    @Test("Parses path")
    func parsesPath() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["path"] == "/Library/LaunchDaemons/com.example.service.plist")
    }

    @Test("Parses last exit code")
    func parsesExitCode() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["last exit code"] == "0")
    }

    @Test("Ignores unknown keys")
    func ignoresUnknown() {
        let info = LaunchctlPrintParser.parse(Self.sampleOutput)
        #expect(info["active count"] == nil)
        #expect(info["some random key"] == nil)
    }

    @Test("Handles empty input")
    func handlesEmpty() {
        let info = LaunchctlPrintParser.parse("")
        #expect(info.isEmpty)
    }
}
