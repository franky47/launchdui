import Testing
import Foundation
@testable import LaunchdUI

@Suite("LogTailer")
struct LogTailerTests {

    private func createTempFile(_ content: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("logtest-\(UUID().uuidString).log")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("Reads last 500 lines from a file with more lines")
    func readsLast500Lines() throws {
        let lines = (1...700).map { "Line \($0)" }
        let url = try createTempFile(lines.joined(separator: "\n") + "\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        #expect(result.lines.count == 500)
        #expect(result.lines.first == "Line 201")
        #expect(result.lines.last == "Line 700")
    }

    @Test("Reads all lines when file has fewer than maxLines")
    func readsFewerThanMax() throws {
        let lines = (1...10).map { "Line \($0)" }
        let url = try createTempFile(lines.joined(separator: "\n") + "\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        #expect(result.lines.count == 10)
        #expect(result.lines.first == "Line 1")
        #expect(result.lines.last == "Line 10")
    }

    @Test("Returns empty for an empty file")
    func emptyFile() throws {
        let url = try createTempFile("")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        #expect(result.lines.isEmpty)
        #expect(result.offset == 0)
    }

    @Test("Handles file without trailing newline")
    func noTrailingNewline() throws {
        let url = try createTempFile("line1\nline2\nline3")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        #expect(result.lines == ["line1", "line2", "line3"])
    }

    @Test("Handles single line file")
    func singleLine() throws {
        let url = try createTempFile("only line\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        #expect(result.lines == ["only line"])
    }

    @Test("Returns correct offset equal to file size")
    func offsetMatchesFileSize() throws {
        let content = "hello\nworld\n"
        let url = try createTempFile(content)
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let result = try tailer.readTail()

        let expectedSize = UInt64(content.utf8.count)
        #expect(result.offset == expectedSize)
    }

    @Test("Respects custom maxLines")
    func customMaxLines() throws {
        let lines = (1...100).map { "Line \($0)" }
        let url = try createTempFile(lines.joined(separator: "\n") + "\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url, maxLines: 5)
        let result = try tailer.readTail()

        #expect(result.lines.count == 5)
        #expect(result.lines.first == "Line 96")
        #expect(result.lines.last == "Line 100")
    }

    // MARK: - Live tailing

    @Test("Streams new lines appended to file")
    func streamsNewLines() async throws {
        let url = try createTempFile("initial\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let initial = try tailer.readTail()
        #expect(initial.lines == ["initial"])

        let stream = tailer.stream(from: initial.offset)

        // Append new content
        let handle = try FileHandle(forWritingTo: url)
        handle.seekToEndOfFile()
        handle.write("new line 1\nnew line 2\n".data(using: .utf8)!)
        try handle.close()

        var received: [String] = []
        for await batch in stream {
            received.append(contentsOf: batch)
            if received.count >= 2 { break }
        }

        #expect(received == ["new line 1", "new line 2"])
    }

    @Test("Cancellation stops the stream cleanly")
    func cancellation() async throws {
        let url = try createTempFile("line\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let tailer = LogTailer(url: url)
        let initial = try tailer.readTail()
        let stream = tailer.stream(from: initial.offset)

        let task = Task {
            for await _ in stream {}
        }

        try await Task.sleep(for: .milliseconds(50))
        task.cancel()
        await task.value
    }
}
