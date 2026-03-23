import Testing
import Foundation
@testable import LaunchdUI

@Suite("PinStore")
@MainActor
struct PinStoreTests {

    private func makeStore() -> PinStore {
        let defaults = UserDefaults(suiteName: "PinStoreTests-\(UUID().uuidString)")!
        return PinStore(defaults: defaults)
    }

    @Test("Starts with no pinned labels")
    func startsEmpty() {
        let store = makeStore()
        #expect(store.pinnedLabels.isEmpty)
    }

    @Test("Pinning adds label to pinnedLabels")
    func pinAddsLabel() {
        let store = makeStore()
        store.pin(label: "com.example.service")
        #expect(store.pinnedLabels == ["com.example.service"])
    }

    @Test("Unpinning removes label from pinnedLabels")
    func unpinRemovesLabel() {
        let store = makeStore()
        store.pin(label: "com.example.service")
        store.unpin(label: "com.example.service")
        #expect(store.pinnedLabels.isEmpty)
    }

    @Test("Toggle pins unpinned label, unpins pinned label")
    func togglePin() {
        let store = makeStore()
        store.togglePin(label: "com.example.service")
        #expect(store.pinnedLabels == ["com.example.service"])
        store.togglePin(label: "com.example.service")
        #expect(store.pinnedLabels.isEmpty)
    }

    @Test("isPinned returns correct state")
    func isPinned() {
        let store = makeStore()
        #expect(!store.isPinned(label: "com.example.service"))
        store.pin(label: "com.example.service")
        #expect(store.isPinned(label: "com.example.service"))
    }

    @Test("Pinning preserves insertion order")
    func preservesOrder() {
        let store = makeStore()
        store.pin(label: "com.example.alpha")
        store.pin(label: "com.example.beta")
        store.pin(label: "com.example.gamma")
        #expect(store.pinnedLabels == ["com.example.alpha", "com.example.beta", "com.example.gamma"])
    }

    @Test("Pinning a duplicate is a no-op")
    func duplicateIsNoOp() {
        let store = makeStore()
        store.pin(label: "com.example.service")
        store.pin(label: "com.example.service")
        #expect(store.pinnedLabels == ["com.example.service"])
    }

    @Test("Move reorders pinned labels")
    func moveReorders() {
        let store = makeStore()
        store.pin(label: "com.example.alpha")
        store.pin(label: "com.example.beta")
        store.pin(label: "com.example.gamma")
        store.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(store.pinnedLabels == ["com.example.gamma", "com.example.alpha", "com.example.beta"])
    }

    @Test("State persists across re-instantiation")
    func persistence() {
        let suiteName = "PinStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = PinStore(defaults: defaults)
        store1.pin(label: "com.example.alpha")
        store1.pin(label: "com.example.beta")

        let store2 = PinStore(defaults: defaults)
        #expect(store2.pinnedLabels == ["com.example.alpha", "com.example.beta"])
    }
}
