import Combine
import Foundation

/// One route and one location manager across phone and the future approved CarPlay scene.
@MainActor
final class NavigationRuntime {
    static let shared = NavigationRuntime()
    let gps = LocationService()
    let session = NavigationSession()
    lazy var voice = VoiceGuidance(session: session)
    private var phoneActive = true
    private var carConnected = false
    private var observations = Set<AnyCancellable>()
    static var carPlayEnabled: Bool { Bundle.main.object(forInfoDictionaryKey: "NightDriveCarPlayEnabled") as? Bool == true }

    private init() {
        _ = voice
        gps.$now.receive(on: RunLoop.main).sink { [weak self] now in
            guard let self else { return }
            self.session.update(self.gps.currentLocation, now: now)
        }.store(in: &observations)
        session.$phase.receive(on: RunLoop.main).sink { [weak self] _ in self?.updateActivity() }.store(in: &observations)
    }
    func setPhoneActive(_ active: Bool) { phoneActive = active; updateActivity() }
    func setCarConnected(_ connected: Bool) {
        // The entitlement and matching scene manifest are installed only after Apple approval.
        carConnected = connected && Self.carPlayEnabled
        updateActivity()
    }
    private func updateActivity() {
        let navigatingInCar = carConnected && session.phase == .navigating
        gps.setCarNavigationActive(navigatingInCar)
        gps.setActive(phoneActive || carConnected)
        if !phoneActive && !carConnected { session.update(nil) }
    }
}
