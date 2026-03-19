import SwiftUI

/// Bottom-right panel: tabbed viewer with Tree, Source, and optional Logs/Errors tabs.
struct PlistInspectorView: View {
    let value: PlistValue
    let standardOutURL: URL?
    let standardErrorURL: URL?
    let serviceID: String
    @Binding var tabSelections: [String: Tab]

    enum Tab: Hashable {
        case tree
        case source
        case logs
        case errors

        var label: String {
            switch self {
            case .tree: "Tree"
            case .source: "Source"
            case .logs: "Logs"
            case .errors: "Errors"
            }
        }

        var icon: String {
            switch self {
            case .tree: "list.bullet.indent"
            case .source: "chevron.left.forwardslash.chevron.right"
            case .logs: "doc.text"
            case .errors: "exclamationmark.triangle"
            }
        }
    }

    private var availableTabs: [Tab] {
        var tabs: [Tab] = [.tree, .source]
        if standardOutURL != nil { tabs.append(.logs) }
        if standardErrorURL != nil { tabs.append(.errors) }
        return tabs
    }

    /// The remembered tab for this service, validated against available tabs.
    private var effectiveTab: Tab {
        let remembered = tabSelections[serviceID] ?? .tree
        return availableTabs.contains(remembered) ? remembered : .tree
    }

    private func selectTab(_ tab: Tab) {
        tabSelections[serviceID] = tab
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
                ForEach(availableTabs, id: \.self) { tab in
                    Button {
                        selectTab(tab)
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .hidden()
                            .overlay {
                                Label(tab.label, systemImage: tab.icon)
                                    .font(.subheadline)
                                    .fontWeight(effectiveTab == tab ? .semibold : .regular)
                                    .foregroundStyle(effectiveTab == tab ? .primary : .secondary)
                            }
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
        switch effectiveTab {
        case .tree:
            PlistTreeView(value: value)
        case .source:
            PlistSourceView(value: value)
        case .logs:
            if let url = standardOutURL {
                LogTabView(fileURL: url)
                    .id(url)
            }
        case .errors:
            if let url = standardErrorURL {
                LogTabView(fileURL: url)
                    .id(url)
            }
        }
    }
}
