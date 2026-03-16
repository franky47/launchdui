import SwiftUI

/// Root view: two-column HSplitView with service list and detail panel.
struct ContentView: View {
    @Bindable var state: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HSplitView {
            ServiceListView(state: state)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 450)

            DetailPanelView(service: state.selectedService)
                .frame(minWidth: 400)
        }
        .frame(minWidth: 750, minHeight: 500)
        .task {
            await state.refresh()
        }
        .onChange(of: state.selectedServiceID) {
            Task {
                await state.loadDetailForSelection()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await state.refresh() }
            }
        }
        .background {
            Button("") {
                Task { await state.refresh() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .hidden()
        }
        .overlay(alignment: .top) {
            if state.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(8)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = state.errorMessage {
                errorBanner(error)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .lineLimit(2)
            Spacer()
            Button("Dismiss") {
                state.errorMessage = nil
            }
            .buttonStyle(.borderless)
        }
        .font(.caption)
        .padding(8)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(8)
    }
}
