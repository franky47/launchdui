import Foundation

/// Parses the TSV output of `launchctl list`.
///
/// Format: each line is `PID\tExitStatus\tLabel`
/// - PID is `-` when not running
/// - ExitStatus is the last exit code
struct LaunchctlListParser {

    struct Entry: Sendable, Equatable {
        let pid: Int?
        let lastExitStatus: Int
        let label: String
    }

    /// Parse the raw output of `launchctl list` into entries.
    static func parse(_ output: String) -> [Entry] {
        output.split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parseLine(String($0)) }
    }

    private static func parseLine(_ line: String) -> Entry? {
        let columns = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
        guard columns.count == 3 else { return nil }

        let pidString = String(columns[0]).trimmingCharacters(in: .whitespaces)
        let exitString = String(columns[1]).trimmingCharacters(in: .whitespaces)
        let label = String(columns[2]).trimmingCharacters(in: .whitespaces)

        // Skip the header line
        guard label != "Label" else { return nil }
        guard !label.isEmpty else { return nil }

        let pid = pidString == "-" ? nil : Int(pidString)
        let exitStatus = Int(exitString) ?? 0

        return Entry(pid: pid, lastExitStatus: exitStatus, label: label)
    }
}
