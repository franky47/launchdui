import SwiftUI

/// Left column: filterable, grouped service list.
struct ServiceListView: View {
    @Bindable var state: AppState

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
                    "\(group.source.displayName) (\(group.services.count))"
                ) {
                    ForEach(group.services) { service in
                        ServiceRow(service: service)
                            .tag(service.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
