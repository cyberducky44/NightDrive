import XCTest
import CoreLocation
@testable import NightDrive

@MainActor
final class RoutingTests: XCTestCase {
    private let origin = CLLocationCoordinate2D(latitude: 51.8893, longitude: 0.9012)
    private func location(_ latitude: Double, _ longitude: Double = 0.9012, accuracy: Double = 5, at date: Date) -> CLLocation {
        CLLocation(coordinate: .init(latitude: latitude, longitude: longitude), altitude: 0,
                   horizontalAccuracy: accuracy, verticalAccuracy: 5, course: 0, speed: 10, timestamp: date)
    }
    private var route: DriveRoute {
        let coordinates = [origin, .init(latitude: 51.8903, longitude: 0.9012), .init(latitude: 51.8913, longitude: 0.9012)]
        return DriveRoute(coordinates: coordinates, distanceMeters: 222.5, durationSeconds: 50,
                          maneuvers: [RouteManeuver(coordinate: coordinates[0], instruction: "Head north", distanceMeters: 111.25, durationSeconds: 25, type: "depart", modifier: nil, startMeters: 0),
                                      RouteManeuver(coordinate: coordinates[1], instruction: "Continue", distanceMeters: 111.25, durationSeconds: 25, type: "continue", modifier: nil, startMeters: 111.25),
                                      RouteManeuver(coordinate: coordinates[2], instruction: "Arrive", distanceMeters: 0, durationSeconds: 0, type: "arrive", modifier: nil, startMeters: 222.5)])
    }
    func testRequestUsesCarProfileAndExplicitCoordinatesOnly() throws {
        let request = try OSRMRoutingService.request(for: .init(origin: origin, destination: .init(latitude: 51.8995, longitude: 0.8927)))
        XCTAssertEqual(request.url?.host, "routing.openstreetmap.de")
        XCTAssertTrue(request.url!.path.contains("routed-car/route/v1/driving/0.901200,51.889300;0.892700,51.899500"))
        XCTAssertTrue(request.url!.absoluteString.contains("radiuses=100;100"))
        XCTAssertNotNil(request.value(forHTTPHeaderField: "User-Agent"))
        XCTAssertThrowsError(try OSRMRoutingService.request(for: .init(origin: origin, destination: origin)))
    }
    func testDecodeActualPublicColchesterRouteAndRejectErrors() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "colchester-route", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let decoded = try OSRMRoutingService.decode(data)
        XCTAssertEqual(decoded.distanceMeters, 2006.9, accuracy: 0.1)
        XCTAssertEqual(decoded.maneuvers.count, 18)
        XCTAssertEqual(decoded.coordinates.count, 128)
        XCTAssertTrue(decoded.maneuvers.contains { $0.instruction.contains("roundabout") })
        XCTAssertThrowsError(try OSRMRoutingService.decode(Data(#"{"code":"NoRoute"}"#.utf8))) { XCTAssertEqual(($0 as? RouteError), .noRoute) }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var routes = try XCTUnwrap(json["routes"] as? [[String: Any]])
        routes[0]["geometry"] = ["type": "LineString", "coordinates": [[0, 999], [1, 2]]]
        json["routes"] = routes
        XCTAssertThrowsError(try OSRMRoutingService.decode(JSONSerialization.data(withJSONObject: json)))
        XCTAssertEqual(OSRMRoutingService.instruction("turn", modifier: "uturn", road: "", exit: nil), "Make a U-turn")
        XCTAssertEqual(OSRMRoutingService.instruction("roundabout", modifier: nil, road: "A12", exit: 3), "At the roundabout, take exit 3 onto A12")
    }
    func testGuidanceRequiresAccurateFreshFixNearStart() {
        let session = NavigationSession(); session.present(route: route)
        let now = Date()
        XCTAssertFalse(session.start(location: location(51.8893, accuracy: 500, at: now), now: now))
        XCTAssertFalse(session.start(location: location(51.8893, at: now.addingTimeInterval(-30)), now: now))
        XCTAssertFalse(session.start(location: location(51.8993, at: now), now: now))
        XCTAssertTrue(session.start(location: location(51.8893, at: now), now: now))
        XCTAssertEqual(session.phase, .navigating)
    }
    func testProgressPausesForPoorGPSAndArrivesOnlyAtEnd() {
        let session = NavigationSession(); session.present(route: route)
        let now = Date()
        XCTAssertTrue(session.start(location: location(51.8893, at: now), now: now))
        session.update(location(51.8903, at: now.addingTimeInterval(10)), now: now.addingTimeInterval(10))
        XCTAssertEqual(session.progressMeters, 111.25, accuracy: 1)
        XCTAssertEqual(session.remainingSeconds, 25, accuracy: 1)
        session.update(nil, now: now.addingTimeInterval(30))
        XCTAssertNotNil(session.guidanceStatus)
        XCTAssertEqual(session.progressMeters, 111.25, accuracy: 1)
        session.update(location(51.8913, accuracy: 500, at: now.addingTimeInterval(31)), now: now.addingTimeInterval(31))
        XCTAssertEqual(session.phase, .navigating)
        session.update(location(51.8913, at: now.addingTimeInterval(35)), now: now.addingTimeInterval(35))
        XCTAssertEqual(session.phase, .arrived)
        XCTAssertEqual(session.remainingMeters, 0)
        session.endNavigation()
        XCTAssertNil(session.route)
        XCTAssertNil(session.destination)
    }
    func testOffRouteNeedsSustainedEvidenceAndNeverContactsService() {
        let service = ControlledRouting(); let session = NavigationSession(service: service)
        session.present(route: route)
        let now = Date()
        XCTAssertTrue(session.start(location: location(51.8893, at: now), now: now))
        session.update(location(51.8893, 0.9032, at: now.addingTimeInterval(2)), now: now.addingTimeInterval(2))
        XCTAssertFalse(session.isOffRoute)
        session.update(location(51.8893, 0.9032, at: now.addingTimeInterval(9)), now: now.addingTimeInterval(9))
        XCTAssertTrue(session.isOffRoute)
        XCTAssertEqual(session.progressMeters, 0)
        XCTAssertEqual(service.calls, 0)
        session.update(location(51.8898, at: now.addingTimeInterval(12)), now: now.addingTimeInterval(12))
        XCTAssertFalse(session.isOffRoute)
        XCTAssertGreaterThan(session.progressMeters, 40)
    }
    func testProjectionDoesNotJumpToDistantLoopOrAcrossDateline() throws {
        let geometry = RouteGeometry([origin, .init(latitude: 51.8993, longitude: 0.9012), origin])
        let projection = try XCTUnwrap(geometry.project(origin, within: 0...150))
        XCTAssertEqual(projection.meters, 0, accuracy: 0.1)
        let crossing = RouteGeometry([.init(latitude: 0, longitude: 179.999), .init(latitude: 0, longitude: -179.999)])
        XCTAssertLessThan(crossing.length, 230)
        let middle = try XCTUnwrap(crossing.project(.init(latitude: 0, longitude: 180), within: 0...crossing.length))
        XCTAssertEqual(middle.distanceFromRoute, 0, accuracy: 1)
    }
    func testVoiceCuesAreOncePerTurnAndDistanceBand() {
        var policy = VoiceCuePolicy()
        let route = route, turn = route.maneuvers[1]
        XCTAssertNil(policy.cue(routeID: route.id, maneuver: turn, distance: 900))
        XCTAssertNotNil(policy.cue(routeID: route.id, maneuver: turn, distance: 250))
        XCTAssertNil(policy.cue(routeID: route.id, maneuver: turn, distance: 200))
        XCTAssertEqual(policy.cue(routeID: route.id, maneuver: turn, distance: 30), "Continue")
        XCTAssertNil(policy.cue(routeID: route.id, maneuver: turn, distance: 20))
        policy.reset()
        XCTAssertNotNil(policy.cue(routeID: route.id, maneuver: turn, distance: 20))
        XCTAssertNil(policy.cue(routeID: route.id, maneuver: turn, distance: 150))
    }

    private final class ControlledRouting: RoutingService {
        var calls = 0
        var pending: [CheckedContinuation<DriveRoute, Error>] = []
        func route(for request: RouteRequest) async throws -> DriveRoute {
            calls += 1
            return try await withCheckedThrowingContinuation { pending.append($0) }
        }
    }
    func testCancelledAndSupersededRoutesCannotReturnToMap() async {
        let service = ControlledRouting(); let session = NavigationSession(service: service)
        let destination = MapSpot(coordinate: origin, name: "Public test", category: nil)
        session.choose(destination); session.calculate(from: origin, name: "Map start")
        for _ in 0..<100 where service.calls < 1 { await Task.yield() }
        XCTAssertEqual(service.calls, 1)
        session.choose(destination); session.calculate(from: origin, name: "New start")
        for _ in 0..<100 where service.calls < 2 { await Task.yield() }
        XCTAssertEqual(service.calls, 2)
        service.pending[0].resume(returning: route)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertNil(session.route)
        session.endNavigation()
        service.pending[1].resume(returning: route)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertNil(session.route)
        XCTAssertNil(session.destination)
    }
}
