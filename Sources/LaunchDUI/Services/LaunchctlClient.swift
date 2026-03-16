import Foundation

/// Read-only interface to launchctl.
/// Never executes mutating commands (kickstart, bootout, bootstrap, enable, disable).
struct LaunchctlClient: Sendable {

    private static let launchctlPath = "/bin/launchctl"

    /// Run `launchctl list` and parse the output.
    static func listServices() async throws -> [LaunchctlListParser.Entry] {
        let output = try await ShellExecutor.run(launchctlPath, arguments: ["list"])
        return LaunchctlListParser.parse(output)
    }

    /// Run `launchctl print-disabled gui/<uid>` and return the set of disabled labels.
    static func disabledServices() async throws -> Set<String> {
        let uid = getuid()
        let output = try await ShellExecutor.run(launchctlPath, arguments: ["print-disabled", "gui/\(uid)"])
        return LaunchctlDisabledParser.parse(output)
    }

    /// Run `launchctl print gui/<uid>/<label>` for detailed info on a single service.
    static func printService(label: String, domainTarget: String) async throws -> [String: String] {
        let target = "\(domainTarget)/\(label)"
        let output = try await ShellExecutor.run(launchctlPath, arguments: ["print", target])
        return LaunchctlPrintParser.parse(output)
    }
}
