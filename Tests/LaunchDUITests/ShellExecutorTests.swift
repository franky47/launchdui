import Testing
import Foundation
@testable import LaunchdUI

@Suite("ShellExecutor")
struct ShellExecutorTests {

    @Test("Throws error for nonexistent executable")
    func throwsForInvalidPath() async {
        // This exercises the process.run() failure path.
        // Bug: terminationHandler is set before run(), so if run() throws
        // and the handler somehow fires, the continuation resumes twice → crash.
        // After fix: terminationHandler is cleared on run() failure.
        do {
            _ = try await ShellExecutor.run("/nonexistent/binary/that/does/not/exist")
            Issue.record("Should have thrown")
        } catch {
            // Should throw cleanly, not crash
            #expect(error is CocoaError || error is ShellError || error is POSIXError)
        }
    }

    @Test("Returns stdout for successful command")
    func returnsStdout() async throws {
        let output = try await ShellExecutor.run("/bin/echo", arguments: ["hello"])
        #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test("Throws ShellError for non-zero exit")
    func throwsForNonZeroExit() async {
        do {
            _ = try await ShellExecutor.run("/bin/sh", arguments: ["-c", "exit 42"])
            Issue.record("Should have thrown")
        } catch let error as ShellError {
            if case .nonZeroExit(let status, _) = error {
                #expect(status == 42)
            } else {
                Issue.record("Expected nonZeroExit")
            }
        } catch {
            Issue.record("Expected ShellError, got \(error)")
        }
    }
}
