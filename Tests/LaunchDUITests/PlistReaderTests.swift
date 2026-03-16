import Testing
import Foundation
@testable import LaunchDUI

@Suite("PlistReader")
struct PlistReaderTests {

    private func createTempPlist(_ dict: [String: Any]) throws -> String {
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let path = NSTemporaryDirectory() + "test-\(UUID().uuidString).plist"
        try data.write(to: URL(fileURLWithPath: path))
        return path
    }

    @Test("Reads XML plist from disk")
    func readsXmlPlist() throws {
        let dict: [String: Any] = [
            "Label": "com.test.service",
            "Program": "/usr/bin/test",
            "KeepAlive": true,
        ]
        let path = try createTempPlist(dict)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let value = try PlistReader.read(at: path)
        if case .dictionary(let entries) = value {
            let keys = entries.map(\.key)
            #expect(keys.contains("Label"))
            #expect(keys.contains("Program"))
            #expect(keys.contains("KeepAlive"))
        } else {
            Issue.record("Expected dictionary")
        }
    }

    @Test("Reads raw dictionary")
    func readsDictionary() throws {
        let dict: [String: Any] = ["Label": "com.test.service"]
        let path = try createTempPlist(dict)
        defer { try? FileManager.default.removeItem(atPath: path) }

        let result = try PlistReader.readDictionary(at: path)
        #expect(result["Label"] as? String == "com.test.service")
    }

    @Test("Extracts schedule: StartInterval")
    func extractsStartInterval() {
        let dict: [String: Any] = ["StartInterval": 300]
        let schedule = PlistReader.extractSchedule(from: dict)
        #expect(schedule == .interval(300))
    }

    @Test("Extracts schedule: StartCalendarInterval single")
    func extractsSingleCalendar() {
        let dict: [String: Any] = [
            "StartCalendarInterval": ["Hour": 12, "Minute": 0] as [String: Any],
        ]
        let schedule = PlistReader.extractSchedule(from: dict)
        if case .calendarInterval(let entries) = schedule {
            #expect(entries.count == 1)
            #expect(entries[0].hour == 12)
            #expect(entries[0].minute == 0)
        } else {
            Issue.record("Expected calendarInterval")
        }
    }

    @Test("Extracts schedule: StartCalendarInterval array")
    func extractsMultiCalendar() {
        let dict: [String: Any] = [
            "StartCalendarInterval": [
                ["Hour": 8, "Minute": 0] as [String: Any],
                ["Hour": 20, "Minute": 0] as [String: Any],
            ] as [[String: Any]],
        ]
        let schedule = PlistReader.extractSchedule(from: dict)
        if case .calendarInterval(let entries) = schedule {
            #expect(entries.count == 2)
        } else {
            Issue.record("Expected calendarInterval")
        }
    }

    @Test("Extracts schedule: WatchPaths")
    func extractsWatchPaths() {
        let dict: [String: Any] = ["WatchPaths": ["/var/log/test.log"]]
        let schedule = PlistReader.extractSchedule(from: dict)
        #expect(schedule == .watchPaths(["/var/log/test.log"]))
    }

    @Test("Extracts schedule: KeepAlive bool")
    func extractsKeepAliveBool() {
        let dict: [String: Any] = ["KeepAlive": true]
        let schedule = PlistReader.extractSchedule(from: dict)
        #expect(schedule == .keepAlive)
    }

    @Test("Extracts schedule: KeepAlive dictionary")
    func extractsKeepAliveDict() {
        let dict: [String: Any] = ["KeepAlive": ["SuccessfulExit": false] as [String: Any]]
        let schedule = PlistReader.extractSchedule(from: dict)
        #expect(schedule == .keepAlive)
    }

    @Test("Extracts schedule: on demand (no schedule keys)")
    func extractsOnDemand() {
        let dict: [String: Any] = ["Label": "com.test"]
        let schedule = PlistReader.extractSchedule(from: dict)
        #expect(schedule == .onDemand)
    }

    @Test("Extracts program from Program key")
    func extractsProgramKey() {
        let dict: [String: Any] = ["Program": "/usr/bin/test"]
        #expect(PlistReader.extractProgram(from: dict) == "/usr/bin/test")
    }

    @Test("Extracts program from ProgramArguments")
    func extractsProgramArguments() {
        let dict: [String: Any] = ["ProgramArguments": ["/usr/bin/test", "-v"]]
        #expect(PlistReader.extractProgram(from: dict) == "/usr/bin/test")
    }

    @Test("Generates XML source from PlistValue")
    func generatesXmlSource() throws {
        let value = PlistValue.dictionary([
            (key: "Label", value: .string("com.test")),
        ])
        let xml = try PlistReader.xmlSource(for: value)
        #expect(xml.contains("com.test"))
        #expect(xml.contains("<plist"))
    }
}
