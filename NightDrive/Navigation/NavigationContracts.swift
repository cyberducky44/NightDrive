import CoreLocation

// Stage 2 boundary. A future provider must supply real route geometry and maneuvers.
// No routing service, CarPlay entitlement or background GPS is enabled in Stage 1.
struct RouteRequest {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
}

struct DriveRoute {
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let durationSeconds: Double
    let maneuvers: [RouteManeuver]
}

struct RouteManeuver {
    let coordinate: CLLocationCoordinate2D
    let instruction: String
    let distanceMeters: Double
}

protocol RoutingService {
    func route(for request: RouteRequest) async throws -> DriveRoute
}

// Future phone and CarPlay presenters can consume the same navigation session.
// Platform-specific scene lifecycle remains outside the routing provider.
@MainActor
protocol NavigationPresenting: AnyObject {
    func present(route: DriveRoute)
    func endNavigation()
}
