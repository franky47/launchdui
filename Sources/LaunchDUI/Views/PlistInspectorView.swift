import SwiftUI

/// Bottom-right panel: tabbed plist viewer with Tree and Source tabs.
struct PlistInspectorView: View {
    let value: PlistValue
    @State private var selectedTab: Tab = .tree

    enum Tab: String, CaseIterable {
        case tree = "Tree"
        case source = "Source"
    }

    var body: some View {
        VStack(spacing: 0) {
            picker
            Divider()
            tabContent
        }
    }

    private var picker: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(8)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .tree:
            PlistTreeView(value: value)
        case .source:
            PlistSourceView(value: value)
        }
    }
}
