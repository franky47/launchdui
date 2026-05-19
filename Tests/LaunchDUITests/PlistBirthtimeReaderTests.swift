import Testing
import Foundation
@testable import LaunchdUI

@Suite("PlistBirthtimeReader")
struct PlistBirthtimeReaderTests {

    private func writeTempFile(contents: String = "x") throws -> String {
        let path = NSTemporaryDirectory() + "birthtime-\(UUID().uuidString).plist"
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    @Test("Returns a date for an existing file")
    func returnsDateForExistingFile() throws {
        let path = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let date = PlistBirthtimeReader.birthtime(at: path)
        #expect(date != nil)
        // Should be very recent.
        if let date {
            #expect(abs(date.timeIntervalSinceNow) < 5)
        }
    }

    @Test("Returns nil for a missing file")
    func returnsNilForMissingFile() {
        let path = "/tmp/nonexistent-\(UUID().uuidString).plist"
        #expect(PlistBirthtimeReader.birthtime(at: path) == nil)
    }

}
