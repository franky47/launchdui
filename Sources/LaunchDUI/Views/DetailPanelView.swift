import SwiftUI

/// Right column: top/bottom vertical split with service status and plist inspector.
struct DetailPanelView: View {
    let service: LaunchdService?
    let pinStore: PinStore
    @State private var tabSelections: [String: PlistInspectorView.Tab] = [:]

    var body: some View {
        if let service {
            VSplitView {
                ServiceStatusView(service: service, pinStore: pinStore)
                    .frame(minHeight: 200)

                if let plist = service.plistContents {
                    PlistInspectorView(
                        value: plist,
                        standardOutURL: service.standardOutPath.map { URL(fileURLWithPath: $0) },
                        standardErrorURL: service.standardErrorPath.map { URL(fileURLWithPath: $0) },
                        serviceID: service.id,
                        tabSelections: $tabSelections
                    )
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
