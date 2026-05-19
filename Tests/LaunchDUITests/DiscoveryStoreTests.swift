import Testing
import Foundation
@testable import LaunchdUI

@Suite("DiscoveryStore")
struct DiscoveryStoreTests {

    private func makeStoreURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("discovery-\(UUID().uuidString)")
            .appendingPathComponent("discovery.json")
    }

    private func input(
        _ label: String,
        source: ServiceSource = .userAgent,
        plistPath: String? = nil
    ) -> DiscoveryStore.ServiceInput {
        DiscoveryStore.ServiceInput(
            label: label,
            plistPath: plistPath ?? "/nonexistent/\(label).plist",
            source: source
        )
    }

    @Test("First run records every service as already-read with empty inbox")
    func firstRunBackfill() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DiscoveryStore(fileURL: url)

        await store.reconcile(currentServices: [input("a"), input("b"), input("c")])

        let unread = await store.unreadLabels()
        #expect(unread.isEmpty)
        #expect(await store.firstSeen(label: "a") != nil)
    }

    @Test("Subsequent run surfaces a new label as unread")
    func newLabelDetected() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a"), input("b")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [input("a"), input("b"), input("c")])

        let unread = await store2.unreadLabels()
        #expect(unread == ["c"])
    }

    @Test("Labels no longer on disk are dropped from the baseline")
    func removedLabelDropped() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a"), input("b")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [input("a")])

        #expect(await store2.firstSeen(label: "b") == nil)
    }

    @Test("Reinstalling a previously-removed label resurfaces it as unread")
    func reinstallSurfacesAsUnread() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a"), input("b")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [input("a")])

        let store3 = DiscoveryStore(fileURL: url)
        await store3.reconcile(currentServices: [input("a"), input("b")])

        #expect(await store3.unreadLabels() == ["b"])
    }

    @Test("Round-trip: state persists across re-instantiation")
    func loadRoundTrip() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a"), input("b")])
        let firstSeenA = await store1.firstSeen(label: "a")

        let store2 = DiscoveryStore(fileURL: url)
        // Trigger load via reconcile with the same set so nothing changes
        await store2.reconcile(currentServices: [input("a"), input("b")])

        #expect(await store2.firstSeen(label: "a") == firstSeenA)
        #expect(await store2.unreadLabels().isEmpty)
    }

    @Test("Corrupt JSON file is treated as first run")
    func corruptionRecovery() async throws {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let store = DiscoveryStore(fileURL: url)
        await store.reconcile(currentServices: [input("a"), input("b")])

        // First-run path → empty inbox
        #expect(await store.unreadLabels().isEmpty)
    }

    @Test("Apple-source services on a subsequent run are auto-acknowledged")
    func appleSourceAutoAcknowledged() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [
            input("a"),
            input("apple.agent", source: .appleAgent),
            input("apple.daemon", source: .appleDaemon),
            input("third-party", source: .systemDaemon),
        ])

        let unread = await store2.unreadLabels()
        #expect(unread == ["third-party"])
    }

    @Test("markRead clears the unread flag and is idempotent")
    func markReadIdempotency() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("a")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [input("a"), input("b")])
        #expect(await store2.unreadLabels() == ["b"])

        await store2.markRead(label: "b")
        #expect(await store2.unreadLabels().isEmpty)

        // Idempotent — second call is a no-op
        await store2.markRead(label: "b")
        #expect(await store2.unreadLabels().isEmpty)
    }

    @Test("markAllRead clears every unread label")
    func markAllReadClearsInbox() async {
        let url = makeStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DiscoveryStore(fileURL: url)
        await store1.reconcile(currentServices: [input("seed")])

        let store2 = DiscoveryStore(fileURL: url)
        await store2.reconcile(currentServices: [
            input("seed"), input("a"), input("b"), input("c"),
        ])
        #expect(await store2.unreadLabels().count == 3)

        await store2.markAllRead()
        #expect(await store2.unreadLabels().isEmpty)
    }
}
