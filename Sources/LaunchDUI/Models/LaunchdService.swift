import Foundation

/// Core domain model representing a single launchd service.
struct LaunchdService: Sendable, Identifiable {
    /// The unique launchd label (e.g. "com.apple.Spotlight").
    let label: String

    /// Where the plist was found on disk.
    let source: ServiceSource

    /// Full path to the .plist file.
    let plistPath: String

    /// Runtime status derived from `launchctl list` + `print-disabled`.
    var status: ServiceStatus

    /// The program or script this service runs.
    var program: String?

    /// Program arguments from the plist.
    var programArguments: [String]?

    /// Scheduling information extracted from the plist.
    var schedule: ServiceSchedule

    /// Raw plist content as a Sendable tree.
    var plistContents: PlistValue?

    /// Detailed runtime info from `launchctl print` (loaded lazily).
    var detailedInfo: [String: String]?

    var id: String { label }

    /// Human-friendly display name derived from the label.
    var displayName: String {
        // Use the last component of reverse-DNS labels
        // e.g. "com.apple.Spotlight" -> "Spotlight"
        label.components(separatedBy: ".").last ?? label
    }
}
