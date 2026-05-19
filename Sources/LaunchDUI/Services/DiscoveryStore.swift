import Foundation
import os

/// Owns the persisted baseline of discovered launchd services and the unread
/// "inbox" derived from it. Encapsulates first-run backfill, corruption
/// recovery, Apple-source auto-acknowledgment, and atomic JSON persistence.
///
/// SIP is the trust root for the Apple-source policy: third parties cannot
/// write to `/System/Library/Launch{Agents,Daemons}` with SIP enabled, so
/// services discovered there are recorded as already-read on first sight.
/// If SIP is disabled, malicious daemons placed there will be auto-acked —
/// a known limit of v1.
actor DiscoveryStore {

    struct ServiceInput: Sendable {
        let label: String
        let plistPath: String
        let source: ServiceSource
    }

    private static let log = Logger(subsystem: "com.47ng.launchdui", category: "DiscoveryStore")

    private let fileURL: URL
    private var records: [String: DiscoveryRecord] = [:]
    private var loaded = false
    /// True when the on-disk file was missing or unparseable at load time.
    /// Drives the first-run "ack everything" path in `reconcile`.
    private var isFirstRun = false

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.fileURL = appSupport
            .appendingPathComponent("launchdui", isDirectory: true)
            .appendingPathComponent("discovery.json")
    }

    /// Diff `currentServices` against the persisted baseline. Drops labels no
    /// longer on disk and records new labels with the appropriate `readAt`:
    /// `now` on first run, `firstSeenAt` for Apple sources, `nil` for everything
    /// else (i.e. surfaced as unread).
    func reconcile(currentServices: [ServiceInput]) {
        loadIfNeeded()
        let now = Date()
        let firstRun = isFirstRun
        let currentLabels = Set(currentServices.map(\.label))

        records = records.filter { currentLabels.contains($0.key) }

        for service in currentServices where records[service.label] == nil {
            let firstSeen = PlistBirthtimeReader.birthtime(at: service.plistPath) ?? now
            let readAt: Date?
            if firstRun {
                readAt = now
            } else if service.source.isAppleManaged {
                readAt = firstSeen
            } else {
                readAt = nil
            }
            records[service.label] = DiscoveryRecord(firstSeenAt: firstSeen, readAt: readAt)
        }

        isFirstRun = false
        save()
    }

    func markRead(label: String) {
        loadIfNeeded()
        guard var record = records[label], record.readAt == nil else { return }
        record.readAt = Date()
        records[label] = record
        save()
    }

    func markAllRead() {
        loadIfNeeded()
        let now = Date()
        var changed = false
        for (label, var record) in records where record.readAt == nil {
            record.readAt = now
            records[label] = record
            changed = true
        }
        if changed { save() }
    }

    func unreadLabels() -> Set<String> {
        loadIfNeeded()
        var result: Set<String> = []
        for (label, record) in records where record.readAt == nil {
            result.insert(label)
        }
        return result
    }

    func firstSeen(label: String) -> Date? {
        loadIfNeeded()
        return records[label]?.firstSeenAt
    }

    // MARK: - Private

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([String: DiscoveryRecord].self, from: data)
        else {
            isFirstRun = true
            return
        }
        records = decoded
        isFirstRun = false
    }

    private func save() {
        do {
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Persistence is best-effort — a failure must not crash the app —
            // but a silent failure would re-surface every label as "new" on
            // every launch, so make sure it lands somewhere observable.
            Self.log.error("Failed to persist discovery baseline to \(self.fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension ServiceSource {
    /// True for services shipped by Apple in SIP-protected directories.
    var isAppleManaged: Bool {
        switch self {
        case .appleAgent, .appleDaemon: true
        case .userAgent, .systemAgent, .systemDaemon: false
        }
    }
}
