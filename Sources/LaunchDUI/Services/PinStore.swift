import Foundation

/// Persists user-pinned service labels in UserDefaults.
@MainActor @Observable
final class PinStore {
    private static let key = "pinnedServices"
    private let defaults: UserDefaults

    private(set) var pinnedLabels: [String] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.pinnedLabels = defaults.stringArray(forKey: Self.key) ?? []
    }

    func pin(label: String) {
        guard !pinnedLabels.contains(label) else { return }
        pinnedLabels.append(label)
        save()
    }

    func unpin(label: String) {
        pinnedLabels.removeAll { $0 == label }
        save()
    }

    func togglePin(label: String) {
        if isPinned(label: label) {
            unpin(label: label)
        } else {
            pin(label: label)
        }
    }

    func isPinned(label: String) -> Bool {
        pinnedLabels.contains(label)
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        pinnedLabels.move(fromOffsets: fromOffsets, toOffset: toOffset)
        save()
    }

    private func save() {
        defaults.set(pinnedLabels, forKey: Self.key)
    }
}
