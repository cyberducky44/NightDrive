import CoreLocation
import Combine

// Local geometry only: GPS samples never go to a map-matching server.
struct RouteGeometry {
    struct Projection { let meters: Double; let distanceFromRoute: Double }
    let coordinates: [CLLocationCoordinate2D]
    let cumulative: [Double]
    var length: Double { cumulative.last ?? 0 }
    init(_ coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        var lengths = [0.0]
        for index in coordinates.indices.dropFirst() {
            let a = coordinates[index - 1], b = coordinates[index]
            lengths.append(lengths.last! + CLLocation(latitude: a.latitude, longitude: a.longitude)
                .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude)))
        }
        cumulative = lengths
    }
    func project(_ point: CLLocationCoordinate2D, within range: ClosedRange<Double>) -> Projection? {
        guard coordinates.count >= 2, length > 0 else { return nil }
        // Binary search skips distant geometry on long routes.
        var low = 0, high = cumulative.count - 1
        while low < high {
            let mid = (low + high) / 2
            if cumulative[mid] < range.lowerBound { low = mid + 1 } else { high = mid }
        }
        let start = max(0, low - 1)
        var best: Projection?
        let scale = max(0.01, cos(point.latitude * .pi / 180))
        func xy(_ coordinate: CLLocationCoordinate2D) -> (Double, Double) {
            var lon = coordinate.longitude - point.longitude
            if lon > 180 { lon -= 360 }; if lon < -180 { lon += 360 }
            return (lon * 111_320 * scale, (coordinate.latitude - point.latitude) * 111_320)
        }
        for index in start..<(coordinates.count - 1) {
            if cumulative[index] > range.upperBound { break }
            let a = xy(coordinates[index]), b = xy(coordinates[index + 1])
            let dx = b.0 - a.0, dy = b.1 - a.1, square = dx * dx + dy * dy
            let t = square > 0 ? min(1, max(0, -(a.0 * dx + a.1 * dy) / square)) : 0
            let meters = cumulative[index] + t * (cumulative[index + 1] - cumulative[index])
            guard range.contains(meters) else { continue }
            let distance = hypot(a.0 + t * dx, a.1 + t * dy)
            if best == nil || distance < best!.distanceFromRoute {
                best = Projection(meters: meters, distanceFromRoute: distance)
            }
        }
        return best
    }
}

@MainActor
final class NavigationSession: ObservableObject, NavigationPresenting {
    enum Phase: Hashable { case choosingStart, loading, preview, navigating, arrived }
    @Published private(set) var destination: MapSpot?
    @Published private(set) var route: DriveRoute?
    @Published private(set) var phase: Phase = .choosingStart
    @Published private(set) var message: String?
    @Published private(set) var guidanceStatus: String?
    @Published private(set) var progressMeters = 0.0
    @Published private(set) var isOffRoute = false
    @Published private(set) var overviewID = 0
    @Published private(set) var originName = ""
    private var geometry: RouteGeometry?
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private var lastFix: CLLocation?
    private var offRouteSince: Date?
    private let service: RoutingService

    init(service: RoutingService? = nil) { self.service = service ?? OSRMRoutingService() }
    func choose(_ destination: MapSpot) {
        endNavigation()
        self.destination = destination
    }
    func calculate(from origin: CLLocationCoordinate2D, name: String) {
        guard let destination else { return }
        task?.cancel()
        let token = UUID(); generation = token
        phase = .loading; message = nil; route = nil; geometry = nil
        originName = name; resetProgress()
        task = Task { [weak self, service] in
            do {
                let result = try await service.route(for: RouteRequest(origin: origin, destination: destination.coordinate))
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.present(route: result)
            } catch {
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.phase = .choosingStart
                self.message = (error as? RouteError)?.errorDescription ?? RouteError.unavailable.errorDescription
            }
        }
    }
    func present(route: DriveRoute) {
        self.route = route
        geometry = RouteGeometry(route.coordinates)
        resetProgress()
        phase = .preview
        overviewID += 1
    }
    func requireGPS() { message = "Enable location and wait for a precise GPS fix, then try again." }
    func overview() { overviewID += 1 }
    static func usableFix(_ fix: CLLocation?, now: Date = Date()) -> Bool {
        guard let fix else { return false }
        return LocationQuality.usable(fix, now: now) && fix.horizontalAccuracy <= 50
    }
    func start(location: CLLocation?, now: Date = Date()) -> Bool {
        guard let route, let first = route.coordinates.first,
              Self.usableFix(location, now: now), let location else {
            message = "A fresh, precise GPS position is needed to start guidance."
            return false
        }
        guard location.distance(from: CLLocation(latitude: first.latitude, longitude: first.longitude)) <= 100 else {
            message = "You are away from this start. Route from your location first."
            return false
        }
        resetProgress(); message = nil; phase = .navigating
        update(location, now: now)
        return true
    }
    func update(_ location: CLLocation?, now: Date = Date()) {
        guard phase == .navigating, let route, let geometry else { return }
        guard Self.usableFix(location, now: now), let location else {
            guidanceStatus = "Guidance paused · waiting for precise GPS"
            // No accumulated off-route evidence through gaps or backgrounding.
            offRouteSince = nil
            return
        }
        guidanceStatus = nil
        guard lastFix?.timestamp != location.timestamp else { return }
        let elapsed = min(15, max(0, location.timestamp.timeIntervalSince(lastFix?.timestamp ?? location.timestamp)))
        if let lastFix, location.timestamp <= lastFix.timestamp { return }
        let alongGeometry = progressMeters / route.distanceMeters * geometry.length
        let forward = max(150, max(0, location.speed) * elapsed * 1.8 + 50)
        let projection = geometry.project(location.coordinate,
                                          within: max(0, alongGeometry - 30)...min(geometry.length, alongGeometry + forward))
        lastFix = location
        let tolerance = max(35, location.horizontalAccuracy * 1.5)
        guard let projection, projection.distanceFromRoute <= tolerance else {
            if offRouteSince == nil { offRouteSince = location.timestamp }
            if location.timestamp.timeIntervalSince(offRouteSince!) >= 6 { isOffRoute = true }
            guidanceStatus = isOffRoute ? "Off route · recalculate when safe" : "Checking route position…"
            return
        }
        offRouteSince = nil; isOffRoute = false
        progressMeters = max(0, min(route.distanceMeters, projection.meters / geometry.length * route.distanceMeters))
        if remainingMeters < 35, let end = route.coordinates.last,
           location.distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)) < 35 {
            phase = .arrived; progressMeters = route.distanceMeters
        }
    }
    var nextManeuver: RouteManeuver? {
        guard let route else { return nil }
        return route.maneuvers.first { $0.startMeters > progressMeters + 8 } ?? route.maneuvers.last
    }
    var distanceToManeuver: Double { max(0, (nextManeuver?.startMeters ?? 0) - progressMeters) }
    var secondsToManeuver: Double {
        guard let route, let next = nextManeuver else { return 0 }
        let afterTurn = route.maneuvers.filter { $0.startMeters >= next.startMeters }.reduce(0) { $0 + $1.durationSeconds }
        return max(0, remainingSeconds - afterTurn)
    }
    var remainingMeters: Double { max(0, (route?.distanceMeters ?? 0) - progressMeters) }
    var remainingSeconds: Double {
        guard let route else { return 0 }
        return route.maneuvers.reduce(0) { total, step in
            guard step.distanceMeters > 0 else { return total }
            let fraction = min(1, max(0, (step.startMeters + step.distanceMeters - progressMeters) / step.distanceMeters))
            return total + step.durationSeconds * fraction
        }
    }
    func endNavigation() {
        generation = UUID(); task?.cancel(); task = nil
        destination = nil; route = nil; geometry = nil; phase = .choosingStart; message = nil
        resetProgress()
    }
    private func resetProgress() {
        progressMeters = 0; lastFix = nil; offRouteSince = nil; isOffRoute = false; guidanceStatus = nil
    }
}
