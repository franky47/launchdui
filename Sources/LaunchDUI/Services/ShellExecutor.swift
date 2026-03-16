import Foundation

/// Async wrapper around `Process` for running read-only shell commands.
struct ShellExecutor: Sendable {
    /// Run a command and return its stdout. Throws on non-zero exit.
    static func run(_ command: String, arguments: [String] = []) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { process in
                let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: ShellError.nonZeroExit(
                        status: process.terminationStatus,
                        stderr: errorMessage
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                // Clear the handler to prevent any possibility of double-resume
                process.terminationHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

enum ShellError: Error, LocalizedError {
    case nonZeroExit(status: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .nonZeroExit(let status, let stderr):
            "Command exited with status \(status): \(stderr)"
        }
    }
}
