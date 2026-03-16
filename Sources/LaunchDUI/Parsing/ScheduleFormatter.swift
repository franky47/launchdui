import Foundation

/// Formats `ServiceSchedule` values into human-readable strings.
struct ScheduleFormatter {

    static func format(_ schedule: ServiceSchedule) -> String {
        switch schedule {
        case .calendarInterval(let entries):
            if entries.isEmpty { return "No schedule" }
            return entries.map { formatCalendarEntry($0) }.joined(separator: "; ")

        case .interval(let seconds):
            return formatInterval(seconds)

        case .watchPaths(let paths):
            let names = paths.map { ($0 as NSString).lastPathComponent }
            return "When changed: \(names.joined(separator: ", "))"

        case .keepAlive:
            return "Always running (KeepAlive)"

        case .onDemand:
            return "On demand"
        }
    }

    private static func formatCalendarEntry(_ entry: ServiceSchedule.CalendarEntry) -> String {
        var parts: [String] = []

        // Weekday
        if let weekday = entry.weekday {
            parts.append(weekdayName(weekday))
        }

        // Day of month
        if let day = entry.day {
            parts.append("day \(day)")
        }

        // Month
        if let month = entry.month {
            parts.append(monthName(month))
        }

        // Time
        let hour = entry.hour
        let minute = entry.minute

        if let h = hour, let m = minute {
            parts.append("at \(String(format: "%02d:%02d", h, m))")
        } else if let h = hour {
            parts.append("at \(String(format: "%02d:00", h))")
        } else if let m = minute {
            parts.append("at minute \(m)")
        }

        if parts.isEmpty {
            return "Every minute"
        }

        // Build a readable sentence
        if entry.weekday == nil && entry.day == nil && entry.month == nil {
            if hour != nil {
                return "Daily \(parts.joined(separator: " "))"
            } else {
                return "Every hour \(parts.joined(separator: " "))"
            }
        }

        return parts.joined(separator: " ")
    }

    private static func formatInterval(_ seconds: Int) -> String {
        if seconds < 60 {
            return "Every \(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return minutes == 1 ? "Every minute" : "Every \(minutes) minutes"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return hours == 1 ? "Every hour" : "Every \(hours) hours"
        } else {
            let days = seconds / 86400
            return days == 1 ? "Every day" : "Every \(days) days"
        }
    }

    private static func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 0: "Sunday"
        case 1: "Monday"
        case 2: "Tuesday"
        case 3: "Wednesday"
        case 4: "Thursday"
        case 5: "Friday"
        case 6: "Saturday"
        default: "Day \(weekday)"
        }
    }

    private static func monthName(_ month: Int) -> String {
        switch month {
        case 1: "January"
        case 2: "February"
        case 3: "March"
        case 4: "April"
        case 5: "May"
        case 6: "June"
        case 7: "July"
        case 8: "August"
        case 9: "September"
        case 10: "October"
        case 11: "November"
        case 12: "December"
        default: "Month \(month)"
        }
    }
}
