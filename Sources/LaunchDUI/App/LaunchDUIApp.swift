import SwiftUI

@main
struct LaunchdUIApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(state: state)
        }
        .defaultSize(width: 1000, height: 700)
    }
}
