import Foundation

/// Where a launchd service definition was found on disk.
enum ServiceSource: String, Sendable, CaseIterable, Identifiable {
    case userAgent
    case systemAgent
    case systemDaemon
    case appleAgent
    case appleDaemon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .userAgent: "User Agents"
        case .systemAgent: "System Agents"
        case .systemDaemon: "System Daemons"
        case .appleAgent: "Apple Agents"
        case .appleDaemon: "Apple Daemons"
        }
    }

    var directory: String {
        switch self {
        case .userAgent: "\(NSHomeDirectory())/Library/LaunchAgents"
        case .systemAgent: "/Library/LaunchAgents"
        case .systemDaemon: "/Library/LaunchDaemons"
        case .appleAgent: "/System/Library/LaunchAgents"
        case .appleDaemon: "/System/Library/LaunchDaemons"
        }
    }

    /// Whether this source requires sudo for launchctl commands.
    var requiresSudo: Bool {
        switch self {
        case .userAgent, .systemAgent, .appleAgent: false
        case .systemDaemon, .appleDaemon: true
        }
    }

    /// The launchctl domain target for this source.
    var domainTarget: String {
        switch self {
        case .userAgent, .systemAgent, .appleAgent:
            "gui/\(getuid())"
        case .systemDaemon, .appleDaemon:
            "system"
        }
    }
}
