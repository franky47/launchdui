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
            serviceList
        }
    }

    private var searchField: some View {
        TextField("Search services...", text: $state.searchText)
            .textFieldStyle(.roundedBorder)
            .padding(8)
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
                    Text("\(group.source.displayName) (\(group.services.count))")
                }
            }
        }
        .listStyle(.sidebar)
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
