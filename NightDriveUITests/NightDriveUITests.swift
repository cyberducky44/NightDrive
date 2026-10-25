import XCTest
import CoreLocation

final class NightDriveUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testExploreControlsAttributionAndAbout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
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
        app.launchArguments = ["--mute-guidance"]
        app.launch()
        let poi = app.buttons["poiFilters"]
        XCTAssertTrue(poi.waitForExistence(timeout: 15))
        XCTAssertEqual(poi.value as? String, "Off")
        poi.tap()
        XCTAssertTrue(app.navigationBars["Points of interest"].waitForExistence(timeout: 5))
        let readySwitch = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: app.switches["togglePOIs"])
        XCTAssertEqual(XCTWaiter.wait(for: [readySwitch], timeout: 5), .completed)
        app.switches["togglePOIs"].coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(app.switches["togglePOIs"].value as? String, "1")
        app.buttons["Done"].tap()
        XCTAssertEqual(poi.value as? String, "On")
        app.buttons["speedDetails"].tap()
        XCTAssertTrue(app.staticTexts["gpsStatus"].exists)
        // Swipe across the details drawer, leaving map pan gestures untouched.
        app.staticTexts["gpsStatus"].swipeLeft()
        XCTAssertTrue(app.buttons["showControls"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["cameraMenu"].exists)
        XCTAssertFalse(app.staticTexts["gpsStatus"].exists)
        XCTAssertTrue(app.links["© OpenStreetMap"].isHittable)
        XCTAssertTrue(app.buttons["recenterButton"].isHittable)
        app.buttons["showControls"].tap()
        XCTAssertTrue(poi.waitForExistence(timeout: 5))
        XCTAssertEqual(poi.value as? String, "On")
        poi.tap()
        XCTAssertTrue(app.navigationBars["Points of interest"].waitForExistence(timeout: 5))
        app.switches["togglePOIs"].coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        app.buttons["Done"].tap()
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
    func testPOICategoryControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.launch()
        XCTAssertTrue(app.buttons["poiFilters"].waitForExistence(timeout: 15))
        app.buttons["poiFilters"].tap()
        XCTAssertTrue(app.navigationBars["Points of interest"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.switches["poiNames"].value as? String, "0")
        app.buttons["poiDriving"].tap()
        XCTAssertEqual(app.switches["togglePOIs"].value as? String, "1")
        app.buttons["poiAll"].tap()
        app.buttons["poiClear"].tap()
        app.switches["poi_parking"].swipeUp()
        XCTAssertTrue(app.staticTexts["No categories selected — no POIs will appear."].waitForExistence(timeout: 5))
        // A compact Duo sheet may scroll its navigation chrome out of view.
        app.staticTexts["No categories selected — no POIs will appear."].swipeDown()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["recenterButton"].isHittable)
    }

    @MainActor
    func testRecenterAfterPanningInColchester() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.resetAuthorizationStatus(for: .location)
        // Public city-centre fixture; no physical-device location is recorded.
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 51.8893, longitude: 0.9012))
        defer { XCUIDevice.shared.location = nil }
        app.launch()
        XCTAssertTrue(app.buttons["recenterButton"].waitForExistence(timeout: 15))
        app.buttons["recenterButton"].tap()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow While Using App"]
        XCTAssertTrue(allow.waitForExistence(timeout: 10))
        allow.tap()
        XCTAssertTrue(app.staticTexts["GPS connected"].waitForExistence(timeout: 15))
        if app.buttons["Close GPS details"].exists { app.buttons["Close GPS details"].tap() }
        XCTAssertEqual(app.buttons["cameraMenu"].label, "Camera mode, Follow")
        // Pan in the unobstructed map area, then use the dedicated recenter button.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.55))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.55)))
        let explore = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Camera mode, Explore"), object: app.buttons["cameraMenu"])
        XCTAssertEqual(XCTWaiter.wait(for: [explore], timeout: 5), .completed)
        app.buttons["recenterButton"].tap()
        XCTAssertEqual(app.buttons["cameraMenu"].label, "Camera mode, Follow")
        app.buttons["recenterButton"].tap() // Also works when already following the same fix.
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Recentered on simulated Colchester location"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testDroppedSpotOpensNativeSearchAndReturns() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.launch()
        XCTAssertTrue(app.buttons["openPlaces"].waitForExistence(timeout: 15))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.55)).press(forDuration: 1.0)
        XCTAssertTrue(app.buttons["closeSpot"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dropped pin"].exists)
        app.buttons["findSpotPlaces"].tap()
        XCTAssertTrue(app.textFields["placeSearchField"].waitForExistence(timeout: 5))
        app.buttons["submitPlaceSearch"].tap()
        XCTAssertTrue(app.staticTexts["Enter an address, postcode or place."].waitForExistence(timeout: 5))
        app.buttons["closePlaces"].tap()
        XCTAssertTrue(app.buttons["recenterButton"].waitForExistence(timeout: 5))
        app.buttons["hideControls"].tap()
        XCTAssertTrue(app.buttons["openPlaces"].isHittable)
        app.buttons["openPlaces"].tap()
        XCTAssertTrue(app.textFields["placeSearchField"].waitForExistence(timeout: 5))
        app.buttons["closePlaces"].tap()
    }

    /// Live service smoke check: requires Photon connectivity, not a fixture.
    @MainActor
    func testLivePhotonSearchSelectsPlaceOnNeonMap() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.launch()
        XCTAssertTrue(app.buttons["openPlaces"].waitForExistence(timeout: 15))
        app.buttons["openPlaces"].tap()
        let field = app.textFields["placeSearchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Colchester Castle")
        app.buttons["submitPlaceSearch"].tap()
        let result = app.buttons.matching(identifier: "placeResult").firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30), "Live Photon returned no result; inspect network/service status.")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Live Photon Colchester search"
        shot.lifetime = .keepAlways
        add(shot)
        result.tap()
        XCTAssertTrue(app.buttons["closeSpot"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Colchester Castle"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "51.890")).firstMatch.exists)
        XCTAssertFalse(app.otherElements["applePlacesMap"].exists)
        app.buttons["closeSpot"].tap()
        XCTAssertTrue(app.buttons["openPlaces"].waitForExistence(timeout: 5))

    }

    @MainActor
    func testLandscapeControlsRemainAccessible() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["cameraMenu"].isHittable)
        XCTAssertTrue(app.buttons["aboutButton"].isHittable)
        XCTAssertTrue(app.buttons["hideControls"].isHittable)
        XCTAssertTrue(app.links["© OpenStreetMap"].isHittable)
        let location = app.buttons["recenterButton"]
        XCTAssertTrue(location.isHittable)
        if app.frame.width >= 440 {
            XCTAssertLessThan(location.frame.maxX, app.frame.midX, "Wide layouts keep recenter in the left sidebar")
        }
        app.buttons["hideControls"].tap()
        XCTAssertTrue(location.isHittable)
        XCTAssertGreaterThan(location.frame.midX, app.frame.midX, "Hidden rail keeps a floating recenter button")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "NightDrive compact landscape"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testDeniedLocationKeepsExplorationAvailable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 15))
        app.buttons["recenterButton"].tap()
        let deny = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        XCTAssertTrue(deny.waitForExistence(timeout: 10))
        deny.tap()
        XCTAssertTrue(app.staticTexts["Location access denied"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Open location settings"].exists)
        XCTAssertEqual(app.buttons["cameraMenu"].label, "Camera mode, Explore")
        XCTAssertTrue(app.buttons["cameraMenu"].isHittable)
    }
    @MainActor
    func testLiveDrivingRoutePreviewGuidanceAndCancellation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--mute-guidance"]
        app.resetAuthorizationStatus(for: .location)
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 51.8893, longitude: 0.9012))
        defer { XCUIDevice.shared.location = nil }
        app.launch()
        XCTAssertTrue(app.buttons["recenterButton"].waitForExistence(timeout: 15))
        app.buttons["recenterButton"].tap()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow While Using App"]
        XCTAssertTrue(allow.waitForExistence(timeout: 10)); allow.tap()
        XCTAssertTrue(app.staticTexts["GPS connected"].waitForExistence(timeout: 15))
        if app.buttons["Close GPS details"].exists { app.buttons["Close GPS details"].tap() }
        app.buttons["openPlaces"].tap()
        let field = app.textFields["placeSearchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText("Colchester railway station")
        app.buttons["submitPlaceSearch"].tap()
        let result = app.buttons.matching(identifier: "placeResult").firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30)); result.tap()
        let directions = app.buttons["spotDirections"]
        XCTAssertTrue(directions.waitForExistence(timeout: 5)); directions.tap()
        XCTAssertTrue(app.buttons["routeFromGPS"].waitForExistence(timeout: 5)); app.buttons["routeFromGPS"].tap()
        XCTAssertTrue(app.staticTexts["routeSummary"].waitForExistence(timeout: 35), "OSRM live route unavailable")
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        capture("Routing overview")
        app.buttons["routeTurns"].tap()
        app.scrollViews["routeContents"].swipeUp()
        capture("Routing maneuvers")
        app.scrollViews["routeContents"].swipeDown()
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(latitude: 51.88931, longitude: 0.9012))
        app.buttons["startGuidance"].tap()
        capture("Guidance start state")
        XCTAssertTrue(app.staticTexts["ON ROUTE"].waitForExistence(timeout: 10), app.debugDescription)
        capture("Routing guidance")
        XCTAssertTrue(app.links["© OpenStreetMap"].exists)
        app.buttons["endRoute"].tap()
        XCTAssertTrue(app.buttons["openPlaces"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["endRoute"].exists)
    }

    @MainActor
    func testRouteMapStartAndCancelWithoutGPS() throws {
        let app = XCUIApplication(); app.resetAuthorizationStatus(for: .location); app.launch()
        XCTAssertTrue(app.buttons["openPlaces"].waitForExistence(timeout: 15))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.55)).press(forDuration: 1)
        XCTAssertTrue(app.buttons["spotDirections"].waitForExistence(timeout: 5)); app.buttons["spotDirections"].tap()
        app.buttons["chooseRouteStart"].tap()
        XCTAssertTrue(app.buttons["useRouteStart"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["endRoute"].waitForExistence(timeout: 5))
        app.buttons["endRoute"].tap()
        XCTAssertTrue(app.buttons["cameraMenu"].waitForExistence(timeout: 5))
    }

}
