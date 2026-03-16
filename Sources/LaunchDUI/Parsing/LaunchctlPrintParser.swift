import Foundation

/// Parses the output of `launchctl print gui/<uid>/<label>`.
///
/// This is a key-value block format with indented sections.
/// We extract useful fields into a flat dictionary.
struct LaunchctlPrintParser {

    /// Parse the detailed print output into key-value pairs.
    static func parse(_ output: String) -> [String: String] {
        var result: [String: String] = [:]

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Match lines like: "key = value"
            guard let eqRange = trimmed.range(of: " = ") else { continue }

            let key = String(trimmed[trimmed.startIndex..<eqRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[eqRange.upperBound...])
                .trimmingCharacters(in: .whitespaces)

            guard !key.isEmpty else { continue }

            // Store known useful keys
            switch key {
            case "pid", "state", "program", "working directory",
                 "last exit code", "spawn type", "runs", "timeout",
                 "domain", "type", "path":
                result[key] = value
            default:
                // Also capture anything that looks useful
                if key.contains("path") || key.contains("pid") || key.contains("state") {
                    result[key] = value
                }
            }
        }

        return result
    }
}
