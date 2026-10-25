import XCTest
import CoreLocation
@testable import NightDrive

final class CameraAndLocationTests: XCTestCase {
    private func fix(age: TimeInterval = 0, accuracy: Double = 5, speed: Double = 10, course: Double = 90) -> CLLocation {
        CLLocation(coordinate: .init(latitude: 51.5074, longitude: -0.1278), altitude: 0,
                   horizontalAccuracy: accuracy, verticalAccuracy: 5, course: course, speed: speed,
                   timestamp: Date().addingTimeInterval(-age))
    }
    func testFreshAccurateFixIsAccepted() { XCTAssertTrue(LocationQuality.usable(fix())) }
    func testStaleAndInvalidFixesAreRejected() {
        XCTAssertFalse(LocationQuality.usable(fix(age: 20)))
        XCTAssertFalse(LocationQuality.usable(fix(accuracy: -1)))
        XCTAssertFalse(LocationQuality.usable(fix(accuracy: 2000)))
        XCTAssertFalse(LocationQuality.usable(fix(age: -30)))
    }
    func testUnknownSpeedDoesNotBecomeZero() {
        XCTAssertNil(LocationQuality.speedMPH(fix(speed: -1)))
        XCTAssertNil(LocationQuality.speedMPH(nil))
        XCTAssertNil(LocationQuality.speedMPH(fix(age: 30)))
    }
    func testSpeedConversion() { XCTAssertEqual(LocationQuality.speedMPH(fix(speed: 10)), 22) }
    func testDrivingUsesCourseOnlyWhenMoving() {
        XCTAssertEqual(CameraMode.driving.bearing(location: fix(), heading: 20), 90)
        XCTAssertEqual(CameraMode.driving.bearing(location: fix(speed: 0), heading: 20), 20)
        XCTAssertEqual(CameraMode.driving.bearing(location: fix(course: -1), heading: nil), 0)
    }
    func testFollowRemainsNorthUp() {
        XCTAssertEqual(CameraMode.follow.bearing(location: fix(), heading: 20), 0)
        XCTAssertEqual(CameraMode.follow.pitch, 0)
        XCTAssertEqual(CameraMode.driving.pitch, 55)
    }
    func testPOICategoriesAndDensityExcludeUnwantedFeatures() {
        var settings = POISettings()
        settings.categories = [.parking, .fuel]
        let filter = settings.predicate(at: 16)
        XCTAssertTrue(filter.evaluate(with: ["name": "Car park", "class": "parking", "rank": 1]))
        XCTAssertTrue(filter.evaluate(with: ["name": "Charger", "class": "fuel", "rank": 2]))
        XCTAssertFalse(filter.evaluate(with: ["name": "Cafe", "class": "cafe", "rank": 1]))
        XCTAssertFalse(filter.evaluate(with: ["name": "Crowded car park", "class": "parking", "rank": 3]))
        settings.categories = []
        XCTAssertFalse(settings.predicate(at: 18).evaluate(with: ["name": "Car park", "class": "parking", "rank": 1]))
        settings.categories = [.other]
        XCTAssertTrue(settings.predicate(at: 16).evaluate(with: ["name": "Office", "class": "office", "rank": 1]))
        XCTAssertFalse(settings.predicate(at: 16).evaluate(with: ["name": "Cafe", "class": "cafe", "rank": 1]))
    }
    func testPOIDensityRemainsBoundedAndIncreasesWithZoom() {
        for density in POIDensity.allCases {
            XCTAssertLessThan(density.maximumRank(at: 16), density.maximumRank(at: 17))
            XCTAssertLessThan(density.maximumRank(at: 17), density.maximumRank(at: 18))
            XCTAssertLessThanOrEqual(density.maximumRank(at: 20), 60)
        }
        XCTAssertLessThan(POIDensity.light.maximumRank(at: 16), POIDensity.detailed.maximumRank(at: 16))
    }
    func testBundledStyleHasAttributionAndRealHeightExpressions() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "nightdrive", withExtension: "json"))
        let style = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let sources = try XCTUnwrap(style["sources"] as? [String: [String: Any]])
        XCTAssertEqual(sources["openmaptiles"]?["url"] as? String, "https://tiles.openfreemap.org/planet")
        XCTAssertTrue((sources["openmaptiles"]?["attribution"] as? String)?.contains("OpenStreetMap") == true)
        let layers = try XCTUnwrap(style["layers"] as? [[String: Any]])
        XCTAssertEqual(Set(layers.compactMap { $0["id"] as? String }).count, layers.count)
        let poi = try XCTUnwrap(layers.first { $0["id"] as? String == "points-of-interest" })
        XCTAssertEqual(poi["source-layer"] as? String, "poi")
        XCTAssertEqual(poi["minzoom"] as? Int, 15)
        let layout = try XCTUnwrap(poi["layout"] as? [String: Any])
        XCTAssertEqual(layout["visibility"] as? String, "none")
        XCTAssertNotNil(layout["text-field"])
        XCTAssertEqual(layout["icon-image"] as? String, "nightdrive-poi")
        let buildings = try XCTUnwrap(layers.first { $0["id"] as? String == "buildings-3d" })
        XCTAssertEqual(buildings["type"] as? String, "fill-extrusion")
        let paint = try XCTUnwrap(buildings["paint"] as? [String: Any])
        XCTAssertNotNil(paint["fill-extrusion-height"] as? [Any])
    }
}
