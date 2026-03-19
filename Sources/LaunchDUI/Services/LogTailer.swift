import Foundation

/// Reads and live-tails log files efficiently.
final class LogTailer: Sendable {
    let url: URL
    let maxLines: Int

    init(url: URL, maxLines: Int = 500) {
        self.url = url
        self.maxLines = maxLines
    }

    /// Read the last `maxLines` lines from the file.
    /// Returns the lines and the byte offset at the end of the file.
    func readTail() throws -> (lines: [String], offset: UInt64) {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let fileSize = try handle.seekToEnd()
        if fileSize == 0 { return ([], 0) }

        let chunkSize: UInt64 = 65_536
        var chunks: [Data] = []
        var position = fileSize
        var newlineCount = 0

        while position > 0 && newlineCount <= maxLines {
            let readSize = min(chunkSize, position)
            position -= readSize
            try handle.seek(toOffset: position)
            guard let data = try handle.read(upToCount: Int(readSize)) else { break }
            chunks.insert(data, at: 0)
            newlineCount += data.lazy.filter { $0 == UInt8(ascii: "\n") }.count
        }

        var collected = Data()
        for chunk in chunks {
            collected.append(chunk)
        }
        let content = String(decoding: collected, as: UTF8.self)
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        if lines.last?.isEmpty == true {
            lines.removeLast()
        }

        return (Array(lines.suffix(maxLines)), fileSize)
    }

    /// Start live-tailing the file from a given byte offset.
    /// Returns an AsyncStream that yields batches of new lines as they are appended.
    /// Cancel the consuming task to stop tailing and release resources.
    func stream(from offset: UInt64) -> AsyncStream<[String]> {
        let url = self.url

        return AsyncStream<[String]> { continuation in
            let monitorFd = open(url.path, O_RDONLY | O_EVTONLY)
            guard monitorFd >= 0 else {
                continuation.finish()
                return
            }

            guard let readHandle = try? FileHandle(forReadingFrom: url) else {
                close(monitorFd)
                continuation.finish()
                return
            }

            let state = TailState(handle: readHandle, offset: offset)
            let queue = DispatchQueue(label: "com.launchdui.log-tailer", qos: .utility)

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: monitorFd,
                eventMask: [.write, .extend],
                queue: queue
            )

            source.setEventHandler {
                if let lines = state.readNewContent() {
                    continuation.yield(lines)
                }
            }

            source.setCancelHandler {
                state.close()
                close(monitorFd)
            }

            continuation.onTermination = { @Sendable _ in
                source.cancel()
            }

            source.resume()
        }
    }
}

/// Thread-safe mutable state for reading new content from a tailed file.
private final class TailState: @unchecked Sendable {
    private let lock = NSLock()
    private let readHandle: FileHandle
    private var currentOffset: UInt64
    private var partialLine: String = ""

    init(handle: FileHandle, offset: UInt64) {
        self.readHandle = handle
        self.currentOffset = offset
    }

    func readNewContent() -> [String]? {
        lock.withLock {
            do {
                try readHandle.seek(toOffset: currentOffset)
                guard let data = try readHandle.read(upToCount: 1_048_576), !data.isEmpty else { return nil }
                currentOffset += UInt64(data.count)
                let text = partialLine + String(decoding: data, as: UTF8.self)
                var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

                if !text.hasSuffix("\n") && !lines.isEmpty {
                    partialLine = lines.removeLast()
                } else {
                    partialLine = ""
                    if lines.last?.isEmpty == true { lines.removeLast() }
                }

                return lines.isEmpty ? nil : lines
            } catch {
                return nil
            }
        }
    }

    func close() {
        lock.withLock {
            try? readHandle.close()
        }
    }
}
