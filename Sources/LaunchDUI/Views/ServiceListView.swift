import SwiftUI

// MARK: - Row identity for flat list (headers + services in one selection model)

enum ListRowID: Hashable {
    case header(ServiceSource)
    case service(String)
}

private enum FlatRow: Identifiable {
    case header(source: ServiceSource, count: Int, isExpanded: Bool)
    case service(LaunchdService)

    var id: ListRowID {
        switch self {
        case .header(let source, _, _): .header(source)
        case .service(let svc): .service(svc.id)
        }
    }
}

/// Left column: filterable, grouped service list.
struct ServiceListView: View {
    @Bindable var state: AppState
    @State private var expandedGroups: Set<ServiceSource> = [
        .userAgent, .systemAgent, .systemDaemon
    ]
    @State private var selectedRow: ListRowID?

    private var flatRows: [FlatRow] {
        var rows: [FlatRow] = []
        for group in state.groupedServices {
            let isExpanded = expandedGroups.contains(group.source)
            rows.append(.header(source: group.source, count: group.services.count, isExpanded: isExpanded))
            if isExpanded {
                rows.append(contentsOf: group.services.map { .service($0) })
            }
        }
        return rows
    }

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
        List(selection: $selectedRow) {
            ForEach(flatRows) { row in
                switch row {
                case .header(let source, let count, let isExpanded):
                    GroupHeaderRow(source: source, count: count, isExpanded: isExpanded)
                        .tag(row.id)
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedGroups.contains(source) {
                                    expandedGroups.remove(source)
                                } else {
                                    expandedGroups.insert(source)
                                }
                            }
                        }

                case .service(let service):
                    ServiceRow(service: service)
                        .tag(row.id)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onChange(of: selectedRow) { _, newValue in
            if case .service(let id) = newValue {
                state.selectedServiceID = id
            }
        }
        .onKeyPress(.return) {
            if case .header(let source) = selectedRow {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedGroups.contains(source) {
                        expandedGroups.remove(source)
                    } else {
                        expandedGroups.insert(source)
                    }
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            if case .header(let source) = selectedRow {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedGroups.contains(source) {
                        expandedGroups.remove(source)
                    } else {
                        expandedGroups.insert(source)
                    }
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            if case .header(let source) = selectedRow, !expandedGroups.contains(source) {
                _ = withAnimation { expandedGroups.insert(source) }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.leftArrow) {
            if case .header(let source) = selectedRow, expandedGroups.contains(source) {
                _ = withAnimation { expandedGroups.remove(source) }
                return .handled
            }
            return .ignored
        }
    }
}

// MARK: - Group Header Row

private struct GroupHeaderRow: View {
    let source: ServiceSource
    let count: Int
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .frame(width: 10, alignment: .center)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            Text("\(source.displayName) (\(count))")
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(source.displayName), \(count) services")
        .accessibilityHint(isExpanded ? "Double-tap to collapse" : "Double-tap to expand")
    }
}

// MARK: - Filter Chip

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
