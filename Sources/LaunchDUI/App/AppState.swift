import SwiftUI

/// Single source of truth for all UI state.
@MainActor @Observable
final class AppState {
    var services: [LaunchdService] = []
    var selectedServiceID: String?
    var searchText: String = ""
    var activeStatusFilters: Set<StatusFilter> = []
    var activeScheduleFilters: Set<ScheduleFilter> = []
    var isLoading: Bool = false
    var errorMessage: String?

    let pinStore = PinStore()
    private let repository = ServiceRepository()

    /// Counts per status category across all services (unfiltered).
    var statusCounts: [StatusFilter: Int] {
        var counts: [StatusFilter: Int] = [:]
        for filter in StatusFilter.allCases {
            let count = services.count(where: { filter.matches($0.status) })
            if count > 0 {
                counts[filter] = count
            }
        }
        return counts
    }

    /// Counts per schedule category across all services (unfiltered).
    var scheduleCounts: [ScheduleFilter: Int] {
        var counts: [ScheduleFilter: Int] = [:]
        for filter in ScheduleFilter.allCases {
            let count = services.count(where: { filter.matches($0.schedule) })
            if count > 0 {
                counts[filter] = count
            }
        }
        return counts
    }

    /// Pinned services in user-defined order, filtered by current search/filters.
    var pinnedServices: [LaunchdService] {
        let filtered = applyFilters(to: services)
        let pinnedSet = Set(pinStore.pinnedLabels)
        let filteredPinned = filtered.filter { pinnedSet.contains($0.label) }
        // Maintain pin order
        return pinStore.pinnedLabels.compactMap { label in
            filteredPinned.first { $0.label == label }
        }
    }

    /// Services grouped by source, filtered by search text, status, and schedule filters.
    /// Excludes pinned services.
    var groupedServices: [(source: ServiceSource, services: [LaunchdService])] {
        let pinnedSet = Set(pinStore.pinnedLabels)
        let filtered = applyFilters(to: services).filter { !pinnedSet.contains($0.label) }

        return ServiceSource.allCases.compactMap { source in
            let group = filtered.filter { $0.source == source }
            guard !group.isEmpty else { return nil }
            return (source: source, services: group)
        }
    }

    private func applyFilters(to services: [LaunchdService]) -> [LaunchdService] {
        var filtered = services

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter {
                $0.label.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query)
            }
        }

        if !activeStatusFilters.isEmpty {
            filtered = filtered.filter { service in
                activeStatusFilters.contains { $0.matches(service.status) }
            }
        }

        if !activeScheduleFilters.isEmpty {
            filtered = filtered.filter { service in
                activeScheduleFilters.contains { $0.matches(service.schedule) }
            }
        }

        return filtered
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
