import Testing
import Foundation
@testable import LaunchdUI

@MainActor
@Suite("AppState login filter")
struct AppStateLoginFilterTests {

    private func service(_ label: String, runAtLoad: Bool) -> LaunchdService {
        LaunchdService(
            label: label,
            source: .userAgent,
            plistPath: "/tmp/\(label).plist",
            status: .notLoaded,
            program: nil,
            programArguments: nil,
            schedule: .onDemand,
            runAtLoad: runAtLoad,
            plistContents: nil,
            detailedInfo: nil,
            standardOutPath: nil,
            standardErrorPath: nil
        )
    }

    @Test("loginCount tallies RunAtLoad services regardless of filter")
    func loginCountIsUnfiltered() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
            service("com.c", runAtLoad: true),
        ]
        #expect(state.loginCount == 2)
    }

    @Test("showLoginOnly narrows grouped list to RunAtLoad services")
    func showLoginOnlyNarrowsList() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
        ]

        let allLabels = state.groupedServices.flatMap { $0.services.map(\.label) }
        #expect(allLabels.sorted() == ["com.a", "com.b"])

        state.showLoginOnly = true
        let loginLabels = state.groupedServices.flatMap { $0.services.map(\.label) }
        #expect(loginLabels == ["com.a"])
    }
}
