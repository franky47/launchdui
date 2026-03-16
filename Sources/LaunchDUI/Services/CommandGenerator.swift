import Foundation

/// Generates copyable `launchctl` command strings.
/// **Never executes commands** — purely builds strings for the user to copy.
struct CommandGenerator: Sendable {

    struct Commands: Sendable, Equatable {
        let start: String
        let stop: String
        let enable: String
        let disable: String
        let remove: String
    }

    /// Generate all available commands for a service.
    static func commands(for label: String, source: ServiceSource, plistPath: String) -> Commands {
        let domain = source.domainTarget
        let serviceTarget = "\(domain)/\(label)"
        let prefix = source.requiresSudo ? "sudo " : ""

        return Commands(
            start: "\(prefix)launchctl kickstart \(serviceTarget)",
            stop: "\(prefix)launchctl bootout \(serviceTarget)",
            enable: "\(prefix)launchctl enable \(serviceTarget)",
            disable: "\(prefix)launchctl disable \(serviceTarget)",
            remove: "\(prefix)rm \(plistPath)"
        )
    }
}
