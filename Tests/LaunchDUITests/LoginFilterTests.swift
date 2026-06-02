import Testing
@testable import LaunchdUI

@Suite("LoginFilter")
struct LoginFilterTests {

    @Test("`.all` matches regardless of runAtLoad")
    func allMatchesEverything() {
        #expect(LoginFilter.all.matches(runAtLoad: true))
        #expect(LoginFilter.all.matches(runAtLoad: false))
    }

    @Test("`.login` matches only RunAtLoad services")
    func loginMatchesRunAtLoad() {
        #expect(LoginFilter.login.matches(runAtLoad: true))
        #expect(!LoginFilter.login.matches(runAtLoad: false))
    }

    @Test("`.triggered` matches only non-RunAtLoad services")
    func triggeredMatchesComplement() {
        #expect(!LoginFilter.triggered.matches(runAtLoad: true))
        #expect(LoginFilter.triggered.matches(runAtLoad: false))
    }
}
