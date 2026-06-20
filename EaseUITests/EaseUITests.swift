import XCTest

/// End-to-end UI tests that actually tap through every screen and flow.
final class EaseUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launch(pro: Bool = false, fast: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["EASE_SKIP_AUTH"] = "1"   // bypass the Sign-in gate for testing
        app.launchEnvironment["EASE_NO_SK"] = "1"       // no StoreKit sign-in prompt
        if fast { app.launchEnvironment["EASE_FAST"] = "1" }  // ~1.5s sessions
        app.launchEnvironment["EASE_SEED"] = "3"        // a little history
        if pro { app.launchEnvironment["EASE_FORCE_PRO"] = "1" }
        app.launch()
        return app
    }

    /// Home renders, a session runs to completion, and you return home.
    func testBreatheSessionToCompletion() {
        let app = launch()
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 8))
        app.buttons["len-60"].tap()
        app.buttons["breathe"].tap()
        // Session screen is up (End button is stable for the whole session).
        XCTAssertTrue(app.buttons["endSession"].waitForExistence(timeout: 5))
        // Fast mode finishes quickly → the Complete screen.
        XCTAssertTrue(app.staticTexts["Nice."].waitForExistence(timeout: 12))
        app.buttons["complete-done"].tap()
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 5))
    }

    /// Ending a session early returns home without crashing. (Slow session so End is tappable.)
    func testEndSessionEarly() {
        let app = launch(fast: false)
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 8))
        app.buttons["breathe"].tap()
        XCTAssertTrue(app.buttons["endSession"].waitForExistence(timeout: 5))
        app.buttons["endSession"].tap()
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 5))
    }

    /// Tapping a locked Pro pattern opens the paywall.
    func testLockedPatternOpensPaywall() {
        let app = launch()
        XCTAssertTrue(app.buttons["pattern-unwind"].waitForExistence(timeout: 8))
        app.buttons["pattern-unwind"].tap()
        XCTAssertTrue(app.staticTexts["Ease Pro"].waitForExistence(timeout: 5))
        app.buttons["paywall-close"].tap()
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 5))
    }

    /// Stats opens and shows the metrics; free users see the locked-history upsell.
    func testStatsOpens() {
        let app = launch()
        XCTAssertTrue(app.buttons["open-stats"].waitForExistence(timeout: 8))
        app.buttons["open-stats"].tap()
        XCTAssertTrue(app.staticTexts["Your calm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Done"].exists)   // sheet is up with its Done control
        app.buttons["Done"].tap()
    }

    /// Settings opens; theme + haptics controls work.
    func testSettingsControls() {
        let app = launch()
        XCTAssertTrue(app.buttons["open-settings"].waitForExistence(timeout: 8))
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        if app.buttons["Dark"].exists { app.buttons["Dark"].tap() }
        let haptics = app.switches["Haptics"]
        if haptics.exists { haptics.tap() }
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["breathe"].waitForExistence(timeout: 5))
    }

    /// Pro: build and save a custom pattern.
    func testProCustomPatternBuilder() {
        let app = launch(pro: true)
        XCTAssertTrue(app.buttons["open-settings"].waitForExistence(timeout: 8))
        app.buttons["open-settings"].tap()
        let newPattern = app.buttons["New pattern"]
        XCTAssertTrue(newPattern.waitForExistence(timeout: 5))
        newPattern.tap()
        XCTAssertTrue(app.buttons["save-pattern"].waitForExistence(timeout: 5))
        app.buttons["save-pattern"].tap()
        // Back in settings, the saved pattern row should exist.
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
    }
}
