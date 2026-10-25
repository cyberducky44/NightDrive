import CoreLocation

enum CameraMode: String, CaseIterable, Identifiable {
    case free, follow, driving
    var id: String { rawValue }
    var title: String {
        switch self { case .free: return "Explore"; case .follow: return "Follow"; case .driving: return "Drive" }
    }
    var symbol: String {
        switch self { case .free: return "hand.draw"; case .follow: return "location.fill"; case .driving: return "car.fill" }
    }
    var pitch: Double { self == .driving ? 55 : 0 }
    var altitude: Double { self == .driving ? 650 : 1100 }

    func bearing(location: CLLocation, heading: Double?) -> Double {
        guard self == .driving else { return 0 }
        if location.speed >= 2, location.course >= 0 { return location.course }
        return heading ?? 0
    }
}

enum LocationQuality {
    static func usable(_ location: CLLocation, now: Date = Date()) -> Bool {
        CLLocationCoordinate2DIsValid(location.coordinate)
            && location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 1000
            && abs(location.timestamp.timeIntervalSince(now)) <= 15
    }
    static func speedMPH(_ location: CLLocation?) -> Int? {
        guard let location, usable(location), location.speed >= 0 else { return nil }
        return Int((location.speed * 2.236936).rounded())
    }
}
