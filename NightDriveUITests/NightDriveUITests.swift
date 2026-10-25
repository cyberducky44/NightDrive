import XCTest

final class NightDriveUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testExploreControlsAttributionAndAbout() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.buttons["cameraMenu"].label, "Camera mode, Explore")
        app.buttons["cameraMenu"].tap()
        XCTAssertTrue(app.buttons["mode_follow"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["mode_driving"].isHittable)
        app.buttons["mode_free"].tap()
        XCTAssertTrue(app.links["© OpenStreetMap"].exists)
        app.buttons["toggle3D"].tap()
        XCTAssertEqual(app.buttons["toggle3D"].label, "Switch to 3D map")
        app.buttons["toggle3D"].tap()
        app.buttons["aboutButton"].tap()
        XCTAssertTrue(app.navigationBars["NightDrive"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Map controls"].exists)
        app.buttons["Done"].tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: app.buttons["cameraMenu"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    }

    @MainActor
    func testPOIsAndSwipeToFullScreen() throws {
        let app = XCUIApplication()
        app.launch()
        let poi = app.buttons["togglePOIs"]
        XCTAssertTrue(poi.waitForExistence(timeout: 15))
        XCTAssertEqual(poi.value as? String, "Off")
        poi.tap()
        XCTAssertEqual(poi.value as? String, "On")
        app.buttons["speedDetails"].tap()
        XCTAssertTrue(app.staticTexts["gpsStatus"].exists)
        // Swipe across the details drawer, leaving map pan gestures untouched.
        app.staticTexts["gpsStatus"].swipeLeft()
        XCTAssertTrue(app.buttons["showControls"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["cameraMenu"].exists)
        XCTAssertFalse(app.staticTexts["gpsStatus"].exists)
        XCTAssertTrue(app.links["© OpenStreetMap"].isHittable)
        app.buttons["showControls"].tap()
        XCTAssertTrue(poi.waitForExistence(timeout: 5))
        XCTAssertEqual(poi.value as? String, "On")
        poi.tap()
        XCTAssertEqual(poi.value as? String, "Off")
        app.buttons["hideControls"].tap()
        XCTAssertTrue(app.buttons["showControls"].waitForExistence(timeout: 5))
        app.buttons["showControls"].tap()
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 5))
        // XCTest's generic swipe is too short inside a 52-point button.
        // Cross the actual rail width, as a finger swipe would.
        let speed = app.buttons["speedDetails"]
        speed.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: speed.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)))
        XCTAssertTrue(app.buttons["showControls"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLandscapeControlsRemainAccessible() throws {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["cameraMenu"].isHittable)
        XCTAssertTrue(app.buttons["aboutButton"].isHittable)
        XCTAssertTrue(app.buttons["hideControls"].isHittable)
        XCTAssertTrue(app.links["© OpenStreetMap"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "NightDrive compact landscape"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testDeniedLocationKeepsExplorationAvailable() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 15))
        app.buttons["cameraMenu"].tap()
        app.buttons["mode_follow"].tap()
        let deny = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        XCTAssertTrue(deny.waitForExistence(timeout: 10))
        deny.tap()
        XCTAssertTrue(app.staticTexts["Location access denied"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Open location settings"].exists)
        XCTAssertEqual(app.buttons["cameraMenu"].label, "Camera mode, Explore")
        XCTAssertTrue(app.buttons["cameraMenu"].isHittable)
    }
}
