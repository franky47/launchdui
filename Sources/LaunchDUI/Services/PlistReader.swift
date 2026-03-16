import Foundation

/// Reads .plist files from disk using PropertyListSerialization.
/// Handles binary, XML, and OpenStep formats natively.
struct PlistReader: Sendable {

    /// Read a plist file and return its contents as a PlistValue.
    static func read(at path: String) throws -> PlistValue {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return PlistValue.from(plist)
    }

    /// Read a plist file and return the raw dictionary.
    static func readDictionary(at path: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw PlistReaderError.notADictionary(path)
        }
        return dict
    }

    /// Generate XML source representation of plist data.
    static func xmlSource(for plistValue: PlistValue) throws -> String {
        let object = plistValue.toPropertyList()
        let data = try PropertyListSerialization.data(
            fromPropertyList: object,
            format: .xml,
            options: 0
        )
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Extract schedule information from a plist dictionary.
    static func extractSchedule(from dict: [String: Any]) -> ServiceSchedule {
        if let interval = dict["StartInterval"] as? Int {
            return .interval(interval)
        }

        if let calendarInterval = dict["StartCalendarInterval"] as? [String: Any] {
            return .calendarInterval([ServiceSchedule.CalendarEntry(from: calendarInterval)])
        }

        if let calendarIntervals = dict["StartCalendarInterval"] as? [[String: Any]] {
            return .calendarInterval(calendarIntervals.map { ServiceSchedule.CalendarEntry(from: $0) })
        }

        if let watchPaths = dict["WatchPaths"] as? [String] {
            return .watchPaths(watchPaths)
        }

        if let keepAlive = dict["KeepAlive"] as? Bool, keepAlive {
            return .keepAlive
        }

        // KeepAlive can also be a dictionary of conditions
        if dict["KeepAlive"] is [String: Any] {
            return .keepAlive
        }

        return .onDemand
    }

    /// Extract the program path from a plist dictionary.
    static func extractProgram(from dict: [String: Any]) -> String? {
        if let program = dict["Program"] as? String {
            return program
        }
        if let args = dict["ProgramArguments"] as? [String], let first = args.first {
            return first
        }
        return nil
    }
}

enum PlistReaderError: Error, LocalizedError {
    case notADictionary(String)

    var errorDescription: String? {
        switch self {
        case .notADictionary(let path):
            "Plist at \(path) is not a dictionary"
        }
    }
}

// MARK: - PlistValue conversion back to property list objects

extension PlistValue {
    /// Convert back to an `Any` suitable for PropertyListSerialization.
    func toPropertyList() -> Any {
        switch self {
        case .string(let s): return s
        case .integer(let n): return n
        case .real(let d): return d
        case .bool(let b): return b
        case .date(let d): return d
        case .data(let d): return d
        case .array(let items): return items.map { $0.toPropertyList() }
        case .dictionary(let entries):
            var dict: [String: Any] = [:]
            for entry in entries {
                dict[entry.key] = entry.value.toPropertyList()
            }
            return dict
        }
    }
}
