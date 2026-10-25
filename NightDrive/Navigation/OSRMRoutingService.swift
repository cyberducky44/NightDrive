import Foundation
import CoreLocation

enum RouteError: LocalizedError {
    case unavailable, noRoute, invalidResponse, busy, invalidCoordinates
    var errorDescription: String? {
        switch self {
        case .noRoute: return "No driving route found. Try a nearby road or another start."
        case .busy: return "Routing is busy. Wait a moment before trying again."
        case .invalidCoordinates: return "Choose a different start and destination."
        case .invalidResponse: return "The routing response could not be used. Try again later."
        case .unavailable: return "Routing unavailable. Check your connection and try again."
        }
    }
}

@MainActor
final class OSRMRoutingService: RoutingService {
    // FOSSGIS public car profile. Modest non-commercial internal beta use only.
    static let endpoint = "https://routing.openstreetmap.de/routed-car/route/v1/driving/"
    private static var nextRequestAt = Date.distantPast
    private let session: URLSession
    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        config.urlCache = nil
        config.httpCookieStorage = nil
        self.session = session ?? URLSession(configuration: config)
    }
    static func request(for route: RouteRequest) throws -> URLRequest {
        guard CLLocationCoordinate2DIsValid(route.origin), CLLocationCoordinate2DIsValid(route.destination),
              CLLocation(latitude: route.origin.latitude, longitude: route.origin.longitude)
                .distance(from: CLLocation(latitude: route.destination.latitude, longitude: route.destination.longitude)) >= 20 else {
            throw RouteError.invalidCoordinates
        }
        let coordinates = [route.origin, route.destination].map {
            String(format: "%.6f,%.6f", locale: Locale(identifier: "en_US_POSIX"), $0.longitude, $0.latitude)
        }.joined(separator: ";")
        var components = URLComponents(string: endpoint + coordinates)!
        components.queryItems = [URLQueryItem(name: "steps", value: "true"),
                                URLQueryItem(name: "geometries", value: "geojson"),
                                URLQueryItem(name: "overview", value: "full"),
                                URLQueryItem(name: "alternatives", value: "false"),
                                URLQueryItem(name: "generate_hints", value: "false"),
                                URLQueryItem(name: "radiuses", value: "100;100")]
        var request = URLRequest(url: components.url!)
        request.setValue("NightDrive/0.2 (https://github.com/cyberducky44/NightDrive)", forHTTPHeaderField: "User-Agent")
        return request
    }
    func route(for request: RouteRequest) async throws -> DriveRoute {
        let urlRequest = try Self.request(for: request)
        try Task.checkCancellation()
        // Fail fast instead of queueing requests that could burst after cancellation.
        guard Date() >= Self.nextRequestAt else { throw RouteError.busy }
        Self.nextRequestAt = Date().addingTimeInterval(2)
        let (data, response) = try await session.data(for: urlRequest)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw RouteError.unavailable }
        if http.statusCode == 429 {
            let delay = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 60
            Self.nextRequestAt = Date().addingTimeInterval(min(3600, max(30, delay)))
            throw RouteError.busy
        }
        guard data.count <= 10_000_000 else { throw RouteError.invalidResponse }
        if http.statusCode == 400 { return try Self.decode(data) }
        guard (200..<300).contains(http.statusCode) else { throw RouteError.unavailable }
        return try Self.decode(data)
    }

    static func decode(_ data: Data) throws -> DriveRoute {
        let response: Response
        do { response = try JSONDecoder().decode(Response.self, from: data) }
        catch { throw RouteError.invalidResponse }
        guard response.code == "Ok" else {
            if ["NoRoute", "NoSegment"].contains(response.code) { throw RouteError.noRoute }
            throw RouteError.invalidResponse
        }
        guard let route = response.routes?.first,
              route.distance.isFinite, route.distance > 0, route.distance <= 2_000_000,
              route.duration.isFinite, route.duration > 0,
              route.geometry.type == "LineString", (2...50_000).contains(route.geometry.coordinates.count) else {
            throw RouteError.invalidResponse
        }
        let coordinates = try route.geometry.coordinates.map(coordinate)
        guard RouteGeometry(coordinates).length > 1 else { throw RouteError.invalidResponse }
        var offset = 0.0
        let steps = route.legs.flatMap(\.steps)
        guard (2...5000).contains(steps.count), steps.first?.maneuver.type == "depart",
              steps.last?.maneuver.type == "arrive" else { throw RouteError.invalidResponse }
        let maneuvers = try steps.map { step -> RouteManeuver in
            guard step.distance.isFinite, step.distance >= 0,
                  step.duration.isFinite, step.duration >= 0 else { throw RouteError.invalidResponse }
            defer { offset += step.distance }
            return RouteManeuver(coordinate: try coordinate(step.maneuver.location),
                                 instruction: instruction(step.maneuver.type, modifier: step.maneuver.modifier,
                                                          road: step.name, exit: step.maneuver.exit),
                                 distanceMeters: step.distance, durationSeconds: step.duration,
                                 type: step.maneuver.type, modifier: step.maneuver.modifier, startMeters: offset)
        }
        guard abs(offset - route.distance) < max(20, route.distance * 0.02) else { throw RouteError.invalidResponse }
        return DriveRoute(coordinates: coordinates, distanceMeters: route.distance,
                          durationSeconds: route.duration, maneuvers: maneuvers)
    }
    private static func coordinate(_ pair: [Double]) throws -> CLLocationCoordinate2D {
        guard pair.count == 2, pair.allSatisfy(\.isFinite) else { throw RouteError.invalidResponse }
        let coordinate = CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        guard CLLocationCoordinate2DIsValid(coordinate) else { throw RouteError.invalidResponse }
        return coordinate
    }
    static func instruction(_ type: String, modifier: String?, road: String, exit: Int?) -> String {
        let direction = modifier == "uturn" ? "back" : (modifier ?? "straight")
        let action: String
        switch type {
        case "depart": action = "Head \(direction)"
        case "arrive": return "Reach the route end\(modifier == "left" || modifier == "right" ? " on the " + direction : "")"
        case "roundabout", "rotary": action = exit.map { "At the roundabout, take exit \($0)" } ?? "Enter the roundabout"
        case "exit roundabout", "exit rotary": action = "Exit the roundabout"
        case "roundabout turn": action = "At the roundabout, turn \(direction)"
        case "merge": action = "Merge \(direction)"
        case "on ramp": action = "Take the ramp \(direction)"
        case "off ramp": action = "Take the exit \(direction)"
        case "fork": action = "Keep \(direction) at the fork"
        case "end of road": action = "At the end of the road, turn \(direction)"
        case "continue", "new name", "notification": action = modifier == "uturn" ? "Make a U-turn" : "Continue \(direction)"
        default: action = modifier == "uturn" ? "Make a U-turn" : "Turn \(direction)"
        }
        return road.isEmpty ? action : action + " onto " + road
    }
    private struct Response: Decodable { let code: String; let routes: [Route]? }
    private struct Route: Decodable {
        let geometry: Geometry; let distance: Double; let duration: Double; let legs: [Leg]
    }
    private struct Geometry: Decodable { let type: String; let coordinates: [[Double]] }
    private struct Leg: Decodable { let steps: [Step] }
    private struct Step: Decodable { let name: String; let distance: Double; let duration: Double; let maneuver: Maneuver }
    private struct Maneuver: Decodable { let location: [Double]; let type: String; let modifier: String?; let exit: Int? }
}
