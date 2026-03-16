import Testing
@testable import LaunchdUI

@Suite("ScheduleFormatter")
struct ScheduleFormatterTests {

    // MARK: - Interval

    @Test("Formats seconds interval")
    func formatsSeconds() {
        #expect(ScheduleFormatter.format(.interval(30)) == "Every 30 seconds")
    }

    @Test("Formats single minute interval")
    func formatsSingleMinute() {
        #expect(ScheduleFormatter.format(.interval(60)) == "Every minute")
    }

    @Test("Formats multi-minute interval")
    func formatsMinutes() {
        #expect(ScheduleFormatter.format(.interval(300)) == "Every 5 minutes")
    }

    @Test("Formats single hour interval")
    func formatsSingleHour() {
        #expect(ScheduleFormatter.format(.interval(3600)) == "Every hour")
    }

    @Test("Formats multi-hour interval")
    func formatsHours() {
        #expect(ScheduleFormatter.format(.interval(7200)) == "Every 2 hours")
    }

    @Test("Formats single day interval")
    func formatsSingleDay() {
        #expect(ScheduleFormatter.format(.interval(86400)) == "Every day")
    }

    @Test("Formats multi-day interval")
    func formatsDays() {
        #expect(ScheduleFormatter.format(.interval(172800)) == "Every 2 days")
    }

    // MARK: - Calendar Interval

    @Test("Formats daily at specific time")
    func formatsDailyTime() {
        let entry = ServiceSchedule.CalendarEntry(hour: 12, minute: 0)
        let result = ScheduleFormatter.format(.calendarInterval([entry]))
        #expect(result == "Daily at 12:00")
    }

    @Test("Formats daily at hour with no minute")
    func formatsDailyHour() {
        let entry = ServiceSchedule.CalendarEntry(hour: 8)
        let result = ScheduleFormatter.format(.calendarInterval([entry]))
        #expect(result == "Daily at 08:00")
    }

    @Test("Formats weekday schedule")
    func formatsWeekday() {
        let entry = ServiceSchedule.CalendarEntry(weekday: 1, hour: 9, minute: 30)
        let result = ScheduleFormatter.format(.calendarInterval([entry]))
        #expect(result == "Monday at 09:30")
    }

    @Test("Formats empty calendar entry as every minute")
    func formatsEmptyEntry() {
        let entry = ServiceSchedule.CalendarEntry()
        let result = ScheduleFormatter.format(.calendarInterval([entry]))
        #expect(result == "Every minute")
    }

    @Test("Formats multiple calendar entries")
    func formatsMultipleEntries() {
        let entries = [
            ServiceSchedule.CalendarEntry(hour: 8, minute: 0),
            ServiceSchedule.CalendarEntry(hour: 20, minute: 0),
        ]
        let result = ScheduleFormatter.format(.calendarInterval(entries))
        #expect(result == "Daily at 08:00; Daily at 20:00")
    }

    // MARK: - Other schedules

    @Test("Formats watch paths")
    func formatsWatchPaths() {
        let result = ScheduleFormatter.format(.watchPaths(["/var/log/system.log", "/tmp/trigger"]))
        #expect(result == "When changed: system.log, trigger")
    }

    @Test("Formats keep alive")
    func formatsKeepAlive() {
        #expect(ScheduleFormatter.format(.keepAlive) == "Always running (KeepAlive)")
    }

    @Test("Formats on demand")
    func formatsOnDemand() {
        #expect(ScheduleFormatter.format(.onDemand) == "On demand")
    }
}
