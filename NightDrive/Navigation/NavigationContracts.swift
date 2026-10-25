import CoreLocation

struct RouteRequest {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
}

struct DriveRoute: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let durationSeconds: Double
    let maneuvers: [RouteManeuver]
}

struct RouteManeuver: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let instruction: String
    let distanceMeters: Double
    let durationSeconds: Double
    let type: String
    let modifier: String?
    let startMeters: Double

    var symbol: String {
        if type == "arrive" { return "flag.checkered" }
        if type.contains("roundabout") || type == "rotary" { return "arrow.trianglehead.2.clockwise.rotate.90" }
        switch modifier {
        case "left", "sharp left": return "arrow.turn.up.left"
        case "right", "sharp right": return "arrow.turn.up.right"
        case "slight left": return "arrow.up.left"
        case "slight right": return "arrow.up.right"
        case "uturn": return "arrow.uturn.down"
        default: return "arrow.up"
        }
    }
}

@MainActor
protocol RoutingService {
    func route(for request: RouteRequest) async throws -> DriveRoute
}

// Phone and future CarPlay adapters share the same session, not their scene lifecycle.
@MainActor
protocol NavigationPresenting: AnyObject {
    func present(route: DriveRoute)
    func endNavigation()
}

enum RouteFormatting {
    static func distance(_ meters: Double) -> String {
        meters < 160 ? "\(max(0, Int((meters / 10).rounded()) * 10)) m" : String(format: "%.1f mi", meters / 1609.344)
    }
    static func time(_ seconds: Double) -> String {
        let minutes = max(1, Int(ceil(seconds / 60)))
        return minutes >= 60 ? "\(minutes / 60) hr \(minutes % 60) min" : "\(minutes) min"
    }
}
