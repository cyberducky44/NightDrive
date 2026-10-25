import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var accuracy: CLAccuracyAuthorization = .fullAccuracy
    @Published private(set) var location: CLLocation?
    @Published private(set) var heading: Double?
    @Published private(set) var errorMessage: String?
    @Published private(set) var now = Date()
    private let manager = CLLocationManager()
    private var active = true
    private var ticker: AnyCancellable?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.headingFilter = 5
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = true
        authorization = manager.authorizationStatus
        accuracy = manager.accuracyAuthorization
        ticker = Timer.publish(every: 2, on: .main, in: .common).autoconnect().sink { [weak self] date in
            self?.now = date
        }
    }

    var isAuthorized: Bool { authorization == .authorizedAlways || authorization == .authorizedWhenInUse }
    var currentLocation: CLLocation? {
        guard active, let location, LocationQuality.usable(location, now: now) else { return nil }
        return location
    }
    var status: String {
        switch authorization {
        case .notDetermined: return "Location is off"
        case .denied: return "Location access denied"
        case .restricted: return "Location access restricted"
        default:
            if let errorMessage { return errorMessage }
            guard currentLocation != nil else { return "Waiting for GPS" }
            return accuracy == .reducedAccuracy ? "Approximate location" : "GPS connected"
        }
    }

    func requestAccess() {
        if authorization == .notDetermined { manager.requestWhenInUseAuthorization() }
        else { startIfAuthorized() }
    }

    func setCarNavigationActive(_ enabled: Bool) {
        let permitted = (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String])?.contains("location") == true
        manager.allowsBackgroundLocationUpdates = enabled && permitted
        manager.showsBackgroundLocationIndicator = enabled && permitted
    }

    func setActive(_ value: Bool) {
        active = value
        now = Date()
        if value { startIfAuthorized() }
        else {
            manager.stopUpdatingLocation()
            manager.stopUpdatingHeading()
            heading = nil
        }
    }

    private func startIfAuthorized() {
        guard active, isAuthorized else { return }
        errorMessage = nil
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        accuracy = manager.accuracyAuthorization
        if isAuthorized { startIfAuthorized() }
        else {
            manager.stopUpdatingLocation()
            manager.stopUpdatingHeading()
            location = nil
            heading = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        now = Date()
        guard let latest = locations.last, LocationQuality.usable(latest, now: now) else { return }
        location = latest
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let error = error as? CLError else { errorMessage = "Location unavailable"; return }
        if error.code != .locationUnknown { errorMessage = "Location unavailable" }
    }
}
