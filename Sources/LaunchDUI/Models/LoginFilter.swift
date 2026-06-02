import Foundation

/// Tri-state filter over the `RunAtLoad` (boot/login) dimension.
/// Orthogonal to `StatusFilter` / `ScheduleFilter`; exactly one state is
/// active at a time (mutually exclusive, unlike the OR-set chip filters).
enum LoginFilter: String, CaseIterable, Identifiable, Sendable {
    /// No constraint on the login dimension.
    case all = "All"
    /// Only services that launch at load (`RunAtLoad == true`).
    case login = "Login"
    /// Only services that do not launch at load — they start on a
    /// trigger (timer, watch path, socket, keepalive) instead.
    case triggered = "Triggered"

    var id: String { rawValue }

    /// SF Symbol for the segment, or `nil` for the neutral "All" state.
    var icon: String? {
        switch self {
        case .all: nil
        case .login: "power"
        case .triggered: "alarm"
        }
    }

    /// Whether a service with the given `runAtLoad` flag passes this filter.
    /// `.all` matches everything.
    func matches(runAtLoad: Bool) -> Bool {
        switch self {
        case .all: true
        case .login: runAtLoad
        case .triggered: !runAtLoad
        }
    }
}
