import SwiftUI

/// Left column: filterable, grouped service list.
struct ServiceListView: View {
    @Bindable var state: AppState
    @State private var expandedGroups: Set<ServiceSource> = [
        .userAgent, .systemAgent, .systemDaemon
    ]

    var body: some View {
        VStack(spacing: 0) {
            searchField
            statusFilterBar
            scheduleFilterBar
            Divider()
            if state.groupedServices.isEmpty {
                Spacer()
                if !state.searchText.isEmpty {
                    Text("No services matching \"\(state.searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No services matching filters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                serviceList
            }
        }
    }

    private var searchField: some View {
        TextField("Search services...", text: $state.searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(StatusFilter.allCases) { filter in
                    if let count = state.statusCounts[filter] {
                        FilterChip(
                            label: filter.rawValue,
                            count: count,
                            color: filter.color,
                            isActive: state.activeStatusFilters.contains(filter)
                        ) {
                            if state.activeStatusFilters.contains(filter) {
                                state.activeStatusFilters.remove(filter)
                            } else {
                                state.activeStatusFilters.insert(filter)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }

    private var scheduleFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ScheduleFilter.allCases) { filter in
                    if let count = state.scheduleCounts[filter] {
                        FilterChip(
                            label: filter.rawValue,
                            count: count,
                            color: .secondary,
                            icon: filter.icon,
                            isActive: state.activeScheduleFilters.contains(filter)
                        ) {
                            if state.activeScheduleFilters.contains(filter) {
                                state.activeScheduleFilters.remove(filter)
                            } else {
                                state.activeScheduleFilters.insert(filter)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }

    private var serviceList: some View {
        List(selection: $state.selectedServiceID) {
            ForEach(state.groupedServices, id: \.source) { group in
                DisclosureGroup(
                    isExpanded: bindingForGroup(group.source)
                ) {
                    ForEach(group.services) { service in
                        ServiceRow(service: service)
                            .tag(service.id)
                    }
                } label: {
                    HStack {
                        Text("\(group.source.displayName) (\(group.services.count))")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if expandedGroups.contains(group.source) {
                                expandedGroups.remove(group.source)
                            } else {
                                expandedGroups.insert(group.source)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func bindingForGroup(_ source: ServiceSource) -> Binding<Bool> {
        Binding(
            get: { expandedGroups.contains(source) },
            set: { isExpanded in
                if isExpanded {
                    expandedGroups.insert(source)
                } else {
                    expandedGroups.remove(source)
                }
            }
        )
    }
}

private struct FilterChip: View {
    let label: String
    let count: Int
    let color: Color
    var icon: String? = nil
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(isActive ? color : .secondary)
                } else {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }

                Text(label)
                    .font(.caption)

                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? color.opacity(0.2) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? color.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
