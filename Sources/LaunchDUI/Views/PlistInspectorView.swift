import SwiftUI

/// Bottom-right panel: tabbed plist viewer with Tree and Source tabs.
struct PlistInspectorView: View {
    let value: PlistValue
    @State private var selectedTab: Tab = .tree

    enum Tab: CaseIterable {
        case tree
        case source

        var label: String {
            switch self {
            case .tree: "Tree"
            case .source: "Source"
            }
        }

        var icon: String {
            switch self {
            case .tree: "list.bullet.indent"
            case .source: "chevron.left.forwardslash.chevron.right"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            tabContent
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 12)

            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 1.5)
        }
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
