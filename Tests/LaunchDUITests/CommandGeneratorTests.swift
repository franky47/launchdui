import Testing
import Darwin
@testable import LaunchdUI

@Suite("CommandGenerator")
struct CommandGeneratorTests {

    @Test("Generates user agent commands without sudo")
    func userAgentCommands() {
        let cmds = CommandGenerator.commands(for: "com.example.agent", source: .userAgent)
        let uid = getuid()
        #expect(cmds.start == "launchctl kickstart gui/\(uid)/com.example.agent")
        #expect(cmds.stop == "launchctl bootout gui/\(uid)/com.example.agent")
        #expect(cmds.enable == "launchctl enable gui/\(uid)/com.example.agent")
        #expect(cmds.disable == "launchctl disable gui/\(uid)/com.example.agent")
    }

    @Test("Generates system daemon commands with sudo")
    func systemDaemonCommands() {
        let cmds = CommandGenerator.commands(for: "com.example.daemon", source: .systemDaemon)
        #expect(cmds.start == "sudo launchctl kickstart system/com.example.daemon")
        #expect(cmds.stop == "sudo launchctl bootout system/com.example.daemon")
        #expect(cmds.enable == "sudo launchctl enable system/com.example.daemon")
        #expect(cmds.disable == "sudo launchctl disable system/com.example.daemon")
    }

    @Test("System agent commands do not require sudo")
    func systemAgentNoSudo() {
        let cmds = CommandGenerator.commands(for: "com.example.agent", source: .systemAgent)
        #expect(!cmds.start.hasPrefix("sudo"))
    }

    @Test("Apple daemon commands require sudo")
    func appleDaemonSudo() {
        let cmds = CommandGenerator.commands(for: "com.apple.daemon", source: .appleDaemon)
        #expect(cmds.start.hasPrefix("sudo"))
    }
}
