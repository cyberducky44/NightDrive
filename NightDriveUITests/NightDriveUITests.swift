import XCTest

final class NightDriveUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testExploreControlsAttributionAndAbout() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["mode_free"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["mode_follow"].isHittable)
        XCTAssertTrue(app.buttons["mode_driving"].isHittable)
        XCTAssertTrue(app.links["© OpenStreetMap"].exists)
        app.buttons["toggle3D"].tap()
        XCTAssertEqual(app.buttons["toggle3D"].label, "Switch to 3D map")
        app.buttons["toggle3D"].tap()
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "NightDrive portrait"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["aboutButton"].tap()
        XCTAssertTrue(app.navigationBars["NightDrive"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Location & privacy"].exists)
        app.buttons["Done"].tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: app.buttons["mode_free"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    }

    @MainActor
    func testLandscapeControlsRemainAccessible() throws {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["mode_driving"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["mode_driving"].isHittable)
        XCTAssertTrue(app.buttons["aboutButton"].isHittable)
        XCTAssertTrue(app.links["© OpenStreetMap"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "NightDrive landscape"
        shot.lifetime = .keepAlways
        add(shot)
    }
    @MainActor
    func testDeniedLocationKeepsExplorationAvailable() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        XCTAssertTrue(app.buttons["mode_follow"].waitForExistence(timeout: 15))
        app.buttons["mode_follow"].tap()
        let deny = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        XCTAssertTrue(deny.waitForExistence(timeout: 10))
        deny.tap()
        XCTAssertTrue(app.staticTexts["Location access denied"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Open location settings"].exists)
        XCTAssertTrue(app.buttons["mode_free"].isSelected)
        XCTAssertTrue(app.buttons["mode_free"].isHittable)
    }

}
