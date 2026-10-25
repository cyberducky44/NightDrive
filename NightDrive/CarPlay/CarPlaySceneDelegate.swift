import CarPlay
import Combine
import CoreLocation
import MapKit
import MapLibre
import SwiftUI

/// Compiled adapter; not registered or entitled in the normal phone build.
/// Activate Config/CarPlay.xcconfig only after Apple's navigation entitlement approval.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate, CPSearchTemplateDelegate {
    private let runtime = NavigationRuntime.shared
    private var controller: CPInterfaceController?
    private var window: CPWindow?
    private var mapController: CarMapController?
    private var mapTemplate: CPMapTemplate?
    private var carSession: CPNavigationSession?
    private var trip: CPTrip?
    private var presentedRouteID: UUID?
    private var maneuvers: [UUID: CPManeuver] = [:]
    private var observations = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = UUID()
    private var isPaused = false

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        guard NavigationRuntime.carPlayEnabled else { return }
        controller = interfaceController; self.window = window
        let map = CarMapController(runtime: runtime)
        mapController = map; window.rootViewController = map
        let template = CPMapTemplate()
        template.mapDelegate = self
        template.guidanceBackgroundColor = UIColor(NightTheme.navy)
        template.mapButtons = [mapButton("location.fill") { [weak self] in self?.mapController?.recenter() },
                               mapButton("map") { [weak self] in self?.mapController?.overview() },
                               mapButton("speaker.slash") { [weak self] in self?.runtime.voice.isMuted.toggle() },
                               mapButton("hand.draw") { [weak self] in self?.togglePan() }]
        template.leadingNavigationBarButtons = [CPBarButton(title: "Search") { [weak self] _ in self?.openSearch() }]
        template.trailingNavigationBarButtons = [CPBarButton(title: "End") { [weak self] _ in self?.runtime.session.endNavigation() },
                                                 CPBarButton(title: "Reroute") { [weak self] _ in self?.reroute() }]
        mapTemplate = template
        interfaceController.setRootTemplate(template, animated: false, completion: nil)
        runtime.setCarConnected(true)
        runtime.session.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.synchronize() }.store(in: &observations)
        synchronize()
    }
    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        searchTask?.cancel(); searchGeneration = UUID(); observations.removeAll()
        carSession?.cancelTrip(); carSession = nil; trip = nil; presentedRouteID = nil
        runtime.setCarConnected(false)
        window.rootViewController = nil
        controller = nil; self.window = nil; mapController = nil; mapTemplate = nil
    }
    private func mapButton(_ symbol: String, action: @escaping () -> Void) -> CPMapButton {
        let button = CPMapButton { _ in action() }
        button.image = UIImage(systemName: symbol)
        return button
    }
    private func synchronize() {
        guard let template = mapTemplate else { return }
        let model = runtime.session
        guard let route = model.route, let destination = model.destination else {
            carSession?.cancelTrip(); carSession = nil; trip = nil; presentedRouteID = nil
            template.hideTripPreviews()
            if let message = model.message { showMessage(message) }
            return
        }
        if presentedRouteID != route.id {
            carSession?.cancelTrip(); carSession = nil; isPaused = false
            presentedRouteID = route.id
            let choice = CPRouteChoice(summaryVariants: [RouteFormatting.time(route.durationSeconds)],
                                       additionalInformationVariants: [RouteFormatting.distance(route.distanceMeters)],
                                       selectionSummaryVariants: ["Driving · no live traffic"])
            let origin = MKMapItem(location: CLLocation(latitude: route.coordinates[0].latitude, longitude: route.coordinates[0].longitude), address: nil)
            origin.name = model.originName
            let target = MKMapItem(location: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude), address: nil); target.name = destination.name
            let trip = CPTrip(origin: origin, destination: target, routeChoices: [choice])
            self.trip = trip
            maneuvers = Dictionary(uniqueKeysWithValues: route.maneuvers.map { step in
                let maneuver = CPManeuver()
                maneuver.instructionVariants = [step.instruction]
                maneuver.symbolImage = UIImage(systemName: step.symbol)
                maneuver.initialTravelEstimates = estimates(step.distanceMeters, step.durationSeconds)
                return (step.id, maneuver)
            })
            template.showTripPreviews([trip], textConfiguration: nil)
            template.updateEstimates(estimates(route.distanceMeters, route.durationSeconds), for: trip)
            mapController?.overview()
        }
        guard let trip else { return }
        if model.phase == .arrived {
            carSession?.finishTrip(); carSession = nil
            template.hideTripPreviews()
            return
        }
        guard model.phase == .navigating else { return }
        if carSession == nil {
            template.hideTripPreviews()
            carSession = template.startNavigationSession(for: trip)
            carSession?.add(route.maneuvers.compactMap { maneuvers[$0.id] })
            mapController?.recenter()
        }
        if let status = model.guidanceStatus {
            carSession?.pauseTrip(for: model.isOffRoute ? .rerouting : .locating, description: status)
            isPaused = true
            return
        }
        // Restart the presentation after a location pause; the shared route/progress is unchanged.
        if isPaused {
            carSession?.cancelTrip()
            carSession = template.startNavigationSession(for: trip)
            carSession?.add(route.maneuvers.compactMap { maneuvers[$0.id] })
            isPaused = false
        }
        if let next = model.nextManeuver, let maneuver = maneuvers[next.id] {
            carSession?.upcomingManeuvers = [maneuver]
            let seconds = model.secondsToManeuver
            carSession?.updateEstimates(estimates(model.distanceToManeuver, seconds), for: maneuver)
        }
        template.updateEstimates(estimates(model.remainingMeters, model.remainingSeconds), for: trip)
    }
    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        if runtime.session.start(location: runtime.gps.currentLocation) { synchronize() }
        else { showMessage(runtime.session.message ?? "Waiting for GPS") }
    }
    func mapTemplateDidCancelNavigation(_ mapTemplate: CPMapTemplate) {
        runtime.session.endNavigation()
        carSession?.cancelTrip(); carSession = nil
    }
    private func togglePan() {
        guard let template = mapTemplate else { return }
        if template.isPanningInterfaceVisible { template.dismissPanningInterface(animated: true) }
        else { template.showPanningInterface(animated: true) }
        template.leadingNavigationBarButtons = [CPBarButton(title: "Done") { [weak self] _ in
            guard let self else { return }
            self.mapTemplate?.dismissPanningInterface(animated: true)
            self.mapTemplate?.leadingNavigationBarButtons = [CPBarButton(title: "Search") { [weak self] _ in self?.openSearch() }]
        }]
    }
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        let dx: CGFloat = direction.contains(.left) ? 80 : direction.contains(.right) ? -80 : 0
        let dy: CGFloat = direction.contains(.up) ? 80 : direction.contains(.down) ? -80 : 0
        mapController?.pan(CGPoint(x: dx, y: dy))
    }
    private var previousTranslation = CGPoint.zero
    func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) { previousTranslation = .zero }
    func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithTranslation translation: CGPoint, velocity: CGPoint) {
        mapController?.pan(CGPoint(x: translation.x - previousTranslation.x, y: translation.y - previousTranslation.y))
        previousTranslation = translation
    }
    private func estimates(_ meters: Double, _ seconds: Double) -> CPTravelEstimates {
        CPTravelEstimates(distanceRemaining: Measurement(value: max(0, meters), unit: UnitLength.meters), timeRemaining: max(0, seconds))
    }
    private func reroute() {
        guard NavigationSession.usableFix(runtime.gps.currentLocation), let location = runtime.gps.currentLocation else {
            showMessage("A fresh precise location is needed. Grant location access before your journey."); return
        }
        runtime.session.calculate(from: location.coordinate, name: "my location")
    }
    private func showMessage(_ text: String) {
        guard controller?.presentedTemplate == nil else { return }
        let alert = CPAlertTemplate(titleVariants: [text], actions: [CPAlertAction(title: "OK", style: .cancel) { [weak self] _ in self?.controller?.dismissTemplate(animated: true, completion: nil) }])
        controller?.presentTemplate(alert, animated: true, completion: nil)
    }
    private func openSearch() {
        let search = CPSearchTemplate(); search.delegate = self
        controller?.pushTemplate(search, animated: true, completion: nil)
    }
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        // No autocomplete requests to the public provider. Select the explicit Search row.
        searchTask?.cancel(); searchGeneration = UUID()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { completionHandler([]); return }
        let row = CPListItem(text: "Search for \(query.prefix(100))", detailText: "Photon · search and map area are sent")
        row.userInfo = String(query.prefix(200))
        completionHandler([row])
    }
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        guard let query = item.userInfo as? String else { completionHandler(); return }
        searchTask?.cancel()
        let token = UUID(); searchGeneration = token
        let center = runtime.gps.currentLocation?.coordinate ?? mapController?.map.centerCoordinate ?? .init(latitude: 51.5074, longitude: -0.1278)
        searchTask = Task { [weak self] in
            defer { completionHandler() }
            do {
                let places = try await PhotonPlaceSearch().search(query: query, center: center)
                guard let self, !Task.isCancelled, self.searchGeneration == token else { return }
                let rows = places.map { place in
                    let row = CPListItem(text: place.name, detailText: place.address)
                    row.handler = { [weak self] _, done in self?.preview(place); done() }
                    return row
                }
                let section = CPListSection(items: rows.isEmpty ? [CPListItem(text: "No places found", detailText: "Try another search")] : rows)
                self.controller?.pushTemplate(CPListTemplate(title: "Places · Photon / OSM", sections: [section]), animated: true, completion: nil)
            } catch {
                guard !Task.isCancelled else { return }
                self?.showMessage("Search unavailable. Try again later.")
            }
        }
    }
    private func preview(_ place: SearchPlace) {
        guard NavigationSession.usableFix(runtime.gps.currentLocation), let location = runtime.gps.currentLocation else {
            showMessage("A fresh precise location is needed for a driving route."); return
        }
        let alert = CPAlertTemplate(titleVariants: ["Route to \(place.name)? Start and destination are sent to FOSSGIS / OSRM."], actions: [
            CPAlertAction(title: "Route", style: .default) { [weak self] _ in
                guard let self else { return }
                self.controller?.dismissTemplate(animated: false, completion: nil)
                self.controller?.popToRootTemplate(animated: true, completion: nil)
                self.runtime.session.choose(place.spot)
                self.runtime.session.calculate(from: location.coordinate, name: "my location")
            }, CPAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in self?.controller?.dismissTemplate(animated: true, completion: nil) }
        ])
        controller?.presentTemplate(alert, animated: true, completion: nil)
    }
}

/// CarPlay's custom window contains only the map and its source attribution.
/// All controls and maneuver presentation come from Apple's templates above.
@MainActor
private final class CarMapController: UIViewController {
    let map = MLNMapView(frame: .zero, styleURL: NightMapView.styleURL)
    private let runtime: NavigationRuntime
    private var observations = Set<AnyCancellable>()
    private var routeID: UUID?
    private var followsLocation = true
    private var gpsMarker: MLNPointAnnotation?
    init(runtime: NavigationRuntime) { self.runtime = runtime; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func loadView() { view = map }
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        map.showsUserLocation = false
        map.isUserInteractionEnabled = false
        map.setCenter(.init(latitude: 51.5074, longitude: -0.1278), zoomLevel: 14, animated: false)
        map.logoView.isHidden = true
        // Non-interactive attribution is part of map content, never a custom control.
        map.attributionButton.isHidden = true
        let credit = UILabel()
        credit.text = "© OpenStreetMap · OpenMapTiles · OpenFreeMap · OSRM / FOSSGIS"
        credit.font = .systemFont(ofSize: 10); credit.textColor = .white; credit.backgroundColor = UIColor(NightTheme.navy)
        credit.translatesAutoresizingMaskIntoConstraints = false
        map.addSubview(credit)
        NSLayoutConstraint.activate([credit.bottomAnchor.constraint(equalTo: map.safeAreaLayoutGuide.bottomAnchor), credit.centerXAnchor.constraint(equalTo: map.centerXAnchor)])
        runtime.session.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.refresh() }.store(in: &observations)
        runtime.gps.$now.receive(on: RunLoop.main).sink { [weak self] _ in self?.refresh() }.store(in: &observations)
    }
    func pan(_ translation: CGPoint) {
        followsLocation = false
        let center = CGPoint(x: map.bounds.midX - translation.x, y: map.bounds.midY - translation.y)
        map.setCenter(map.convert(center, toCoordinateFrom: map), animated: false)
    }
    func recenter() { followsLocation = true; refresh() }
    func overview() {
        followsLocation = false
        guard let route = runtime.session.route else { return }
        map.setVisibleCoordinates(route.coordinates, count: UInt(route.coordinates.count), edgePadding: UIEdgeInsets(top: 100, left: 220, bottom: 80, right: 70), animated: false)
    }
    private func refresh() {
        if let style = map.style, routeID != runtime.session.route?.id {
            if let layer = style.layer(withIdentifier: "car-route-line") { style.removeLayer(layer) }
            if let source = style.source(withIdentifier: "car-route") { style.removeSource(source) }
            routeID = runtime.session.route?.id
            if let route = runtime.session.route {
                let source = MLNShapeSource(identifier: "car-route", shape: MLNPolyline(coordinates: route.coordinates, count: UInt(route.coordinates.count)), options: nil)
                style.addSource(source)
                let layer = MLNLineStyleLayer(identifier: "car-route-line", source: source)
                layer.lineColor = NSExpression(forConstantValue: UIColor.systemMint); layer.lineWidth = NSExpression(forConstantValue: 6)
                style.addLayer(layer)
            }
        }
        guard let location = runtime.gps.currentLocation else {
            if let marker = gpsMarker { map.removeAnnotation(marker); gpsMarker = nil }; return
        }
        if gpsMarker == nil { gpsMarker = MLNPointAnnotation(); map.addAnnotation(gpsMarker!) }
        gpsMarker?.coordinate = location.coordinate
        if followsLocation {
            map.setCamera(MLNMapCamera(lookingAtCenter: location.coordinate, altitude: 850, pitch: 40,
                                      heading: CameraMode.driving.bearing(location: location, heading: runtime.gps.heading)), animated: false)
        }
    }
}

extension CarMapController: @preconcurrency MLNMapViewDelegate {
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        routeID = nil; refresh()
        if runtime.session.phase == .preview { overview() }
    }
}
