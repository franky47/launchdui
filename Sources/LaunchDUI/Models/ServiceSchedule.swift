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
