import Foundation

/// Parses the output of `launchctl print-disabled gui/<uid>`.
///
/// Output format:
/// ```
/// disabled services = {
///     "com.example.service" => enabled
///     "com.other.service" => disabled
/// }
/// ```
struct LaunchctlDisabledParser {

    /// Parse the output and return a set of disabled service labels.
    static func parse(_ output: String) -> Set<String> {
        var disabled = Set<String>()

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Match lines like: "com.example.service" => disabled
            guard trimmed.contains("=>") else { continue }
            let parts = trimmed.split(separator: "=>", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let labelPart = parts[0].trimmingCharacters(in: .whitespaces)
            let statusPart = parts[1].trimmingCharacters(in: .whitespaces)

            // Strip quotes from label
            let label = labelPart.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            if statusPart.hasPrefix("disabled") {
                disabled.insert(label)
            }
        }

        return disabled
    }
}
