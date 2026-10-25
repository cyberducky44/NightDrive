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
    func testBundledStyleHasAttributionAndRealHeightExpressions() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "nightdrive", withExtension: "json"))
        let style = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let sources = try XCTUnwrap(style["sources"] as? [String: [String: Any]])
        XCTAssertEqual(sources["openmaptiles"]?["url"] as? String, "https://tiles.openfreemap.org/planet")
        XCTAssertTrue((sources["openmaptiles"]?["attribution"] as? String)?.contains("OpenStreetMap") == true)
        let layers = try XCTUnwrap(style["layers"] as? [[String: Any]])
        XCTAssertEqual(Set(layers.compactMap { $0["id"] as? String }).count, layers.count)
        let buildings = try XCTUnwrap(layers.first { $0["id"] as? String == "buildings-3d" })
        XCTAssertEqual(buildings["type"] as? String, "fill-extrusion")
        let paint = try XCTUnwrap(buildings["paint"] as? [String: Any])
        XCTAssertNotNil(paint["fill-extrusion-height"] as? [Any])
    }
}
