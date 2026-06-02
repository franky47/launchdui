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

    @Test("Per-segment counts are unfiltered tallies of the login dimension")
    func segmentCountsAreUnfiltered() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
            service("com.c", runAtLoad: true),
        ]
        #expect(state.loginFilterCount(.all) == 3)
        #expect(state.loginFilterCount(.login) == 2)
        #expect(state.loginFilterCount(.triggered) == 1)
    }

    @Test("loginFilter .all shows every service")
    func allShowsEverything() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
        ]
        state.loginFilter = .all
        let labels = state.groupedServices.flatMap { $0.services.map(\.label) }
        #expect(labels.sorted() == ["com.a", "com.b"])
    }

    @Test("loginFilter .login narrows to RunAtLoad services")
    func loginNarrowsList() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
        ]
        state.loginFilter = .login
        let labels = state.groupedServices.flatMap { $0.services.map(\.label) }
        #expect(labels == ["com.a"])
    }

    @Test("loginFilter .triggered narrows to non-RunAtLoad services")
    func triggeredNarrowsList() {
        let state = AppState()
        state.services = [
            service("com.a", runAtLoad: true),
            service("com.b", runAtLoad: false),
        ]
        state.loginFilter = .triggered
        let labels = state.groupedServices.flatMap { $0.services.map(\.label) }
        #expect(labels == ["com.b"])
    }
}
