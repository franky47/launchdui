import Foundation

/// Represents a launchd service's scheduling configuration.
enum ServiceSchedule: Sendable, Equatable {
    /// Runs on calendar intervals (StartCalendarInterval).
    case calendarInterval([CalendarEntry])
    /// Runs at a fixed interval in seconds (StartInterval).
    case interval(Int)
    /// Runs when watched paths change (WatchPaths).
    case watchPaths([String])
    /// Kept alive continuously (KeepAlive = true).
    case keepAlive
    /// No explicit schedule — launched on demand.
    case onDemand

    struct CalendarEntry: Sendable, Equatable {
        var month: Int?
        var day: Int?
        var weekday: Int?
        var hour: Int?
        var minute: Int?

        init(from dict: [String: Any]) {
            self.month = dict["Month"] as? Int
            self.day = dict["Day"] as? Int
            self.weekday = dict["Weekday"] as? Int
            self.hour = dict["Hour"] as? Int
            self.minute = dict["Minute"] as? Int
        }

        init(month: Int? = nil, day: Int? = nil, weekday: Int? = nil, hour: Int? = nil, minute: Int? = nil) {
            self.month = month
            self.day = day
            self.weekday = weekday
            self.hour = hour
            self.minute = minute
        }
    }
}

/// Simplified schedule categories for filtering.
enum ScheduleFilter: String, CaseIterable, Identifiable, Sendable {
    case calendarInterval = "Calendar"
    case interval = "Interval"
    case watchPaths = "Watch Paths"
    case keepAlive = "Keep Alive"
    case onDemand = "On Demand"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .calendarInterval: "calendar"
        case .interval: "timer"
        case .watchPaths: "eye"
        case .keepAlive: "arrow.clockwise"
        case .onDemand: "hand.tap"
        }
    }

    static func from(_ schedule: ServiceSchedule) -> ScheduleFilter {
        switch schedule {
        case .calendarInterval: .calendarInterval
        case .interval: .interval
        case .watchPaths: .watchPaths
        case .keepAlive: .keepAlive
        case .onDemand: .onDemand
        }
    }

    func matches(_ schedule: ServiceSchedule) -> Bool {
        switch (self, schedule) {
        case (.calendarInterval, .calendarInterval): true
        case (.interval, .interval): true
        case (.watchPaths, .watchPaths): true
        case (.keepAlive, .keepAlive): true
        case (.onDemand, .onDemand): true
        default: false
        }
    }
}
