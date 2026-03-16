import SwiftUI

/// Right column: top/bottom vertical split with service status and plist inspector.
struct DetailPanelView: View {
    let service: LaunchdService?

    var body: some View {
        if let service {
            VSplitView {
                ServiceStatusView(service: service)
                    .frame(minHeight: 200)

                if let plist = service.plistContents {
                    PlistInspectorView(value: plist)
                        .frame(minHeight: 200)
                } else {
                    emptyPlistView
                        .frame(minHeight: 200)
                }
            }
        } else {
            emptySelectionView
        }
    }

    private var emptySelectionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sidebar.left")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Select a service")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyPlistView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Unable to read plist")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
