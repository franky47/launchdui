import Foundation

/// Per-label discovery state persisted by `DiscoveryStore`.
/// `readAt == nil` means the service is in the "new" inbox; otherwise it has been
/// acknowledged (either by the user or auto-acked at first sight).
struct DiscoveryRecord: Codable, Sendable, Equatable {
    var firstSeenAt: Date
    var readAt: Date?
}
