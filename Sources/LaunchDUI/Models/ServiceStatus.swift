import SwiftUI

/// Runtime status of a launchd service.
enum ServiceStatus: Sendable, Equatable {
    /// PID present, actively executing.
    case running(pid: Int)
    /// Loaded, idle, will fire on schedule/trigger.
    case waiting
    /// Loaded, exited cleanly (exit 0), no pending trigger.
    case stopped
    /// Loaded, exited with non-zero code.
    case error(exitCode: Int)
    /// Loaded, terminated by signal.
    case killed(signal: Int)
    /// Explicitly disabled via `launchctl disable`.
    case disabled
    /// Plist exists on disk but service not bootstrapped into launchd.
    case notLoaded

    var displayName: String {
        switch self {
        case .running: "Running"
        case .waiting: "Waiting"
        case .stopped: "Stopped"
        case .error(let code): "Error (\(code))"
        case .killed(let signal): "Killed (\(Self.signalName(signal)))"
        case .disabled: "Disabled"
        case .notLoaded: "Not Loaded"
        }
    }

    var statusColor: Color {
        switch self {
        case .running: .green
        case .waiting: .blue
        case .stopped: .gray
        case .error: .red
        case .killed: .orange
        case .disabled: .gray
        case .notLoaded: .gray
        }
    }

    /// Whether to show a filled circle or a slashed/outline circle.
    var indicatorStyle: StatusIndicatorStyle {
        switch self {
        case .running, .waiting, .stopped, .error, .killed: .filled
        case .disabled: .slashed
        case .notLoaded: .outline
        }
    }

    private static func signalName(_ signal: Int) -> String {
        switch signal {
        case 9: "SIGKILL"
        case 15: "SIGTERM"
        case 6: "SIGABRT"
        case 11: "SIGSEGV"
        case 2: "SIGINT"
        default: "SIG\(signal)"
        }
    }
}

enum StatusIndicatorStyle: Sendable {
    case filled
    case slashed
    case outline
}

/// Simplified status categories for filtering (collapses associated values).
enum StatusFilter: String, CaseIterable, Identifiable, Sendable {
    case running = "Running"
    case waiting = "Waiting"
    case stopped = "Stopped"
    case error = "Error"
    case killed = "Killed"
    case disabled = "Disabled"
    case notLoaded = "Not Loaded"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .running: .green
        case .waiting: .blue
        case .stopped: .gray
        case .error: .red
        case .killed: .orange
        case .disabled: .gray
        case .notLoaded: .gray
        }
    }

    func matches(_ status: ServiceStatus) -> Bool {
        switch (self, status) {
        case (.running, .running): true
        case (.waiting, .waiting): true
        case (.stopped, .stopped): true
        case (.error, .error): true
        case (.killed, .killed): true
        case (.disabled, .disabled): true
        case (.notLoaded, .notLoaded): true
        default: false
        }
    }
}
