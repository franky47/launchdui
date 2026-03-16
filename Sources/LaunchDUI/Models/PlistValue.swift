import Foundation

/// A recursive, Sendable representation of property list data.
/// Used to safely cross actor isolation boundaries under Swift 6 strict concurrency.
enum PlistValue: Sendable, Equatable {
    case string(String)
    case integer(Int)
    case real(Double)
    case bool(Bool)
    case date(Date)
    case data(Data)
    case array([PlistValue])
    case dictionary([(key: String, value: PlistValue)])

    /// Convert a raw `[String: Any]` plist dictionary to a `PlistValue`.
    static func from(_ any: Any) -> PlistValue {
        switch any {
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            // NSNumber can wrap bools — check identity against CF singletons
            if number === kCFBooleanTrue || number === kCFBooleanFalse {
                return .bool(number.boolValue)
            }
            // 'd' (0x64) = double, 'f' (0x66) = float
            let type = number.objCType.pointee
            if type == 0x64 || type == 0x66 {
                return .real(number.doubleValue)
            }
            return .integer(number.intValue)
        case let date as Date:
            return .date(date)
        case let data as Data:
            return .data(data)
        case let array as [Any]:
            return .array(array.map { from($0) })
        case let dict as [String: Any]:
            let sorted = dict.sorted { $0.key < $1.key }
            return .dictionary(sorted.map { (key: $0.key, value: from($0.value)) })
        default:
            return .string(String(describing: any))
        }
    }

    /// Type label for display in the tree view.
    var typeLabel: String {
        switch self {
        case .string: "String"
        case .integer: "Number"
        case .real: "Real"
        case .bool: "Boolean"
        case .date: "Date"
        case .data: "Data"
        case .array(let items): "Array(\(items.count))"
        case .dictionary(let entries): "Dict(\(entries.count))"
        }
    }

    /// Short preview of the value for display.
    var preview: String? {
        switch self {
        case .string(let s): s
        case .integer(let n): String(n)
        case .real(let d): String(d)
        case .bool(let b): b ? "true" : "false"
        case .date(let d): d.formatted()
        case .data(let d): "\(d.count) bytes"
        case .array, .dictionary: nil
        }
    }

    /// Equatable conformance for dictionary case (tuples aren't automatically Equatable).
    static func == (lhs: PlistValue, rhs: PlistValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let a), .string(let b)): return a == b
        case (.integer(let a), .integer(let b)): return a == b
        case (.real(let a), .real(let b)): return a == b
        case (.bool(let a), .bool(let b)): return a == b
        case (.date(let a), .date(let b)): return a == b
        case (.data(let a), .data(let b)): return a == b
        case (.array(let a), .array(let b)): return a == b
        case (.dictionary(let a), .dictionary(let b)):
            guard a.count == b.count else { return false }
            for (entryA, entryB) in zip(a, b) {
                if entryA.key != entryB.key || entryA.value != entryB.value { return false }
            }
            return true
        default: return false
        }
    }
}
