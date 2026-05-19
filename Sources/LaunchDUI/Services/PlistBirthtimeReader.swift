import Foundation

/// Returns the creation date (birthtime) of a file, falling back to its
/// modification date when birthtime is unavailable. Returns `nil` for missing
/// files. Hides the `URLResourceKey` plumbing from callers.
struct PlistBirthtimeReader: Sendable {
    static func birthtime(at path: String) -> Date? {
        let url = URL(fileURLWithPath: path)
        let keys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return nil
        }
        return values.creationDate ?? values.contentModificationDate
    }
}
