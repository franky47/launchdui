import SwiftUI

/// Single source of truth for all UI state.
@MainActor @Observable
final class AppState {
    var services: [LaunchdService] = []
    var selectedServiceID: String?
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let repository = ServiceRepository()

    /// Services grouped by source, filtered by search text.
    var groupedServices: [(source: ServiceSource, services: [LaunchdService])] {
        let filtered: [LaunchdService]
        if searchText.isEmpty {
            filtered = services
        } else {
            let query = searchText.lowercased()
            filtered = services.filter {
                $0.label.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query)
            }
        }

        return ServiceSource.allCases.compactMap { source in
            let group = filtered.filter { $0.source == source }
            guard !group.isEmpty else { return nil }
            return (source: source, services: group)
        }
    }

    /// The currently selected service.
    var selectedService: LaunchdService? {
        guard let id = selectedServiceID else { return nil }
        return services.first { $0.id == id }
    }

    /// Load all services from disk and runtime.
    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            services = try await repository.loadAll()
            await loadDetailForSelection()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Load detailed info for the selected service.
    func loadDetailForSelection() async {
        guard let id = selectedServiceID,
              let index = services.firstIndex(where: { $0.id == id }) else { return }

        // Skip if we already have detail
        guard services[index].detailedInfo == nil else { return }

        let updated = await repository.loadDetail(for: services[index])
        // Re-check index in case services were refreshed
        if let i = services.firstIndex(where: { $0.id == id }) {
            services[i] = updated
        }
    }
}
