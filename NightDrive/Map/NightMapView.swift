import SwiftUI
import MapLibre
import CoreLocation

struct NightMapView: UIViewRepresentable {
    @Binding var mode: CameraMode
    @Binding var mapStatus: String
    let location: CLLocation?
    let heading: Double?
    let is3D: Bool
    let poiSettings: POISettings
    let recenterID: Int
    let reloadID: Int
    let reduceMotion: Bool
    let selectedSpot: MapSpot?
    let focusedSpotID: UUID?
    let route: DriveRoute?
    let overviewID: Int
    let routePanelHeight: CGFloat
    let onSpot: (MapSpot) -> Void
    let onCenter: (CLLocationCoordinate2D) -> Void

    static var styleURL: URL { Bundle.main.url(forResource: "nightdrive", withExtension: "json")! }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MLNMapView {
        let map = MLNMapView(frame: .zero, styleURL: Self.styleURL)
        map.delegate = context.coordinator
        map.backgroundColor = UIColor(NightTheme.navy)
        map.minimumZoomLevel = 2
        map.maximumZoomLevel = 19
        map.showsUserLocation = false // LocationService owns the only CLLocationManager.
        map.logoView.isHidden = true
        map.attributionButton.isHidden = true // Always-visible linked attribution lives in SwiftUI.
        map.compassView.isHidden = true
        map.accessibilityIdentifier = "nightMap"
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.selectPOI(_:)))
        tap.cancelsTouchesInView = false
        // Preserve MapLibre's double-tap zoom and pan gestures.
        for recognizer in map.gestureRecognizers ?? [] {
            if let doubleTap = recognizer as? UITapGestureRecognizer, doubleTap.numberOfTapsRequired > 1 {
                tap.require(toFail: doubleTap)
            }
        }
        map.addGestureRecognizer(tap)
        let press = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.selectSpot(_:)))
        press.minimumPressDuration = 0.6
        map.addGestureRecognizer(press)
        map.setCenter(CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278), zoomLevel: 15.7, animated: false)
        context.coordinator.last3D = is3D
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if coordinator.lastReloadID != reloadID {
            coordinator.lastReloadID = reloadID
            map.reloadStyle(map)
        }
        coordinator.applyStyleSettings(to: map)
        if coordinator.spotID != selectedSpot?.id {
            if let marker = coordinator.spotMarker { map.removeAnnotation(marker) }
            coordinator.spotMarker = nil
            coordinator.spotID = selectedSpot?.id
            if let selectedSpot {
                let marker = SpotAnnotation()
                marker.coordinate = selectedSpot.coordinate
                marker.title = selectedSpot.name
                coordinator.spotMarker = marker
                map.addAnnotation(marker)
            }
        }
        if let selectedSpot, focusedSpotID == selectedSpot.id, coordinator.lastFocusedSpotID != focusedSpotID {
            coordinator.lastFocusedSpotID = focusedSpotID
            coordinator.initializedCamera = true
            map.setCenter(selectedSpot.coordinate, zoomLevel: 16.5, animated: !reduceMotion)
        }
        if coordinator.last3D != is3D {
            coordinator.last3D = is3D
            let camera = map.camera
            camera.pitch = is3D ? 55 : 0
            map.setCamera(camera, animated: !reduceMotion)
        }
        coordinator.applyRoute(to: map)
        coordinator.fitRouteIfNeeded(to: map)
        guard let location else {
            if let marker = coordinator.marker { map.removeAnnotation(marker); coordinator.marker = nil }
            coordinator.lastLocationDate = nil
            return
        }
        if let marker = coordinator.marker {
            if coordinator.lastLocationDate != location.timestamp { marker.coordinate = location.coordinate }
        }
        else {
            let marker = MLNPointAnnotation()
            marker.coordinate = location.coordinate
            marker.title = "Your location"
            coordinator.marker = marker
            map.addAnnotation(marker)
        }
        let changed = coordinator.lastMode != mode || coordinator.lastLocationDate != location.timestamp || (mode == .driving && coordinator.lastHeading != heading) || coordinator.lastRecenterID != recenterID
        coordinator.lastMode = mode
        coordinator.lastLocationDate = location.timestamp
        coordinator.lastHeading = heading
        guard mode != .free, changed, !coordinator.gestureInProgress else { return }
        coordinator.lastRecenterID = recenterID
        let camera = MLNMapCamera(lookingAtCenter: location.coordinate,
                                 altitude: mode.altitude,
                                 pitch: is3D ? (mode == .driving ? 55 : 50) : 0,
                                 heading: mode.bearing(location: location, heading: heading))
        map.setCamera(camera, withDuration: reduceMotion ? 0 : 0.7, animationTimingFunction: CAMediaTimingFunction(name: .easeOut))
    }

    static func dismantleUIView(_ map: MLNMapView, coordinator: Coordinator) {
        map.delegate = nil
    }

    final class SpotAnnotation: MLNPointAnnotation {}

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: NightMapView
        var marker: MLNPointAnnotation?
        var spotMarker: SpotAnnotation?
        var spotID: UUID?
        var lastFocusedSpotID: UUID?
        var appliedRouteID: UUID?
        var appliedOverviewID = 0
        var lastMode: CameraMode = .free
        var lastLocationDate: Date?
        var lastHeading: Double?
        var last3D = true
        var lastReloadID = 0
        var lastRecenterID = 0
        var appliedPOISettings: POISettings?
        var appliedRank: Int?
        var applied3D: Bool?
        var gestureInProgress = false
        var initializedCamera = false
        init(_ parent: NightMapView) { self.parent = parent }

        @objc func selectPOI(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended,
                  let map = recognizer.view as? MLNMapView else { return }
            let point = recognizer.location(in: map)
            if let spot = parent.selectedSpot {
                let markerPoint = map.convert(spot.coordinate, toPointTo: map)
                if hypot(markerPoint.x - point.x, markerPoint.y - point.y) <= 26 {
                    parent.onSpot(spot)
                    return
                }
            }
            guard parent.poiSettings.enabled else { return }
            let area = CGRect(x: point.x - 18, y: point.y - 18, width: 36, height: 36)
            let features = map.visibleFeatures(in: area, styleLayerIdentifiers: ["points-of-interest"])
            let nearest = features.min { left, right in
                let a = map.convert(left.coordinate, toPointTo: map)
                let b = map.convert(right.coordinate, toPointTo: map)
                return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
            }
            guard let feature = nearest else { return }
            let name = feature.attributes["name:en"] as? String ?? feature.attributes["name"] as? String ?? "Map place"
            parent.onSpot(MapSpot(coordinate: feature.coordinate, name: name,
                                  category: feature.attributes["class"] as? String ?? "Place"))
        }
        @objc func selectSpot(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began, let map = recognizer.view as? MLNMapView else { return }
            let coordinate = map.convert(recognizer.location(in: map), toCoordinateFrom: map)
            parent.onSpot(MapSpot(coordinate: coordinate, name: "Dropped pin", category: nil))
        }

        func mapView(_ mapView: MLNMapView, regionWillChangeWith reason: MLNCameraChangeReason, animated: Bool) {
            let gestures: MLNCameraChangeReason = [.gesturePan, .gesturePinch, .gestureRotate, .gestureZoomIn, .gestureZoomOut, .gestureOneFingerZoom, .gestureTilt]
            if !reason.intersection(gestures).isEmpty {
                gestureInProgress = true
                DispatchQueue.main.async { self.parent.mode = .free }
            }
        }
        func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
            gestureInProgress = false
            applyStyleSettings(to: mapView)
            let center = mapView.centerCoordinate
            DispatchQueue.main.async { [weak self] in self?.parent.onCenter(center) }
        }
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            // Original ring + exclamation geometry inspired by the game's side-job marker.
            let marker = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 22)).image { context in
                UIColor(NightTheme.navy).setFill()
                context.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 20, height: 20))
                let gold = UIColor(red: 0.95, green: 0.81, blue: 0.44, alpha: 1)
                gold.setStroke()
                context.cgContext.setLineWidth(1.8)
                context.cgContext.strokeEllipse(in: CGRect(x: 2, y: 2, width: 18, height: 18))
                gold.setFill()
                context.cgContext.fill(CGRect(x: 10, y: 5.5, width: 2, height: 7))
                context.cgContext.fillEllipse(in: CGRect(x: 9.75, y: 14, width: 2.5, height: 2.5))
            }
            style.setImage(marker, forName: "nightdrive-poi")
            appliedRouteID = nil
            applyRoute(to: mapView)
            fitRouteIfNeeded(to: mapView)
            appliedPOISettings = nil
            appliedRank = nil
            applied3D = nil
            applyStyleSettings(to: mapView)
        }

        func applyRoute(to map: MLNMapView) {
            guard let style = map.style, appliedRouteID != parent.route?.id else { return }
            for id in ["route-line", "route-casing"] {
                if let layer = style.layer(withIdentifier: id) { style.removeLayer(layer) }
            }
            if let source = style.source(withIdentifier: "route") { style.removeSource(source) }
            appliedRouteID = parent.route?.id
            guard let route = parent.route else { return }
            let shape = MLNPolyline(coordinates: route.coordinates, count: UInt(route.coordinates.count))
            let source = MLNShapeSource(identifier: "route", shape: shape, options: nil)
            style.addSource(source)
            for (id, color, width) in [("route-casing", UIColor(NightTheme.navy), 10),
                                       ("route-line", UIColor(red: 0.4, green: 1, blue: 0.72, alpha: 1), 5)] {
                let layer = MLNLineStyleLayer(identifier: id, source: source)
                layer.lineColor = NSExpression(forConstantValue: color)
                layer.lineWidth = NSExpression(forConstantValue: width)
                layer.lineJoin = NSExpression(forConstantValue: "round")
                layer.lineCap = NSExpression(forConstantValue: "round")
                style.addLayer(layer)
            }
        }

        func fitRouteIfNeeded(to map: MLNMapView) {
            guard let route = parent.route, map.style != nil, map.bounds.height > 100,
                  appliedOverviewID != parent.overviewID else { return }
            appliedOverviewID = parent.overviewID
            initializedCamera = true
            // Keep the actual road geometry clear of the route card in both orientations.
            let insets = map.bounds.width > 700
                ? UIEdgeInsets(top: 45, left: 40, bottom: 80, right: 440)
                : UIEdgeInsets(top: parent.routePanelHeight + map.safeAreaInsets.top + 28, left: 36, bottom: 90, right: 36)
            map.setVisibleCoordinates(route.coordinates, count: UInt(route.coordinates.count), edgePadding: insets,
                                      direction: 0, duration: parent.reduceMotion ? 0 : 0.6,
                                      animationTimingFunction: nil, completionHandler: nil)
        }

        func applyStyleSettings(to map: MLNMapView) {
            guard let style = map.style else { return }
            if applied3D != parent.is3D {
                style.layer(withIdentifier: "buildings-3d")?.isVisible = parent.is3D
                applied3D = parent.is3D
            }
            guard let layer = style.layer(withIdentifier: "points-of-interest") as? MLNSymbolStyleLayer else { return }
            let settings = parent.poiSettings
            let rank = settings.density.maximumRank(at: map.zoomLevel)
            if appliedPOISettings != settings || appliedRank != rank {
                layer.predicate = settings.predicate(at: map.zoomLevel)
                layer.isVisible = settings.enabled && !settings.categories.isEmpty
                if appliedPOISettings?.showsNames != settings.showsNames {
                    layer.text = settings.showsNames ? NSExpression(mglJSONObject: [
                        "step", ["zoom"], "", 17, ["coalesce", ["get", "name:en"], ["get", "name"]]
                    ]) : NSExpression(forConstantValue: "")
                }
                appliedPOISettings = settings
                appliedRank = rank
            }
        }

        func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
            if !initializedCamera, parent.mode == .free {
                initializedCamera = true
                let camera = mapView.camera
                camera.pitch = parent.is3D ? 50 : 0
                camera.heading = 20
                mapView.setCamera(camera, animated: false)
            }
            setStatus("Map ready")
        }
        func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
            setStatus("Map unavailable · Check connection")
        }
        private func setStatus(_ status: String) {
            DispatchQueue.main.async { if self.parent.mapStatus != status { self.parent.mapStatus = status } }
        }
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            if annotation is SpotAnnotation {
                let view = MLNAnnotationView(reuseIdentifier: "spot")
                view.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                view.backgroundColor = .systemYellow
                view.layer.cornerRadius = 18
                view.layer.borderColor = UIColor.white.cgColor
                view.layer.borderWidth = 3
                let label = UILabel(frame: view.bounds)
                label.text = "!"
                label.textColor = UIColor(NightTheme.navy)
                label.font = .boldSystemFont(ofSize: 24)
                label.textAlignment = .center
                view.addSubview(label)
                view.isEnabled = false
                return view
            }
            let view = MLNAnnotationView(reuseIdentifier: "gps")
            view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            view.backgroundColor = UIColor(NightTheme.cyan)
            view.layer.cornerRadius = 12
            view.layer.borderColor = UIColor.white.cgColor
            view.layer.borderWidth = 3
            view.layer.shadowColor = UIColor(NightTheme.cyan).cgColor
            view.layer.shadowRadius = 12
            view.layer.shadowOpacity = 0.9
            view.layer.shadowOffset = .zero
            view.isEnabled = false
            return view
        }
    }
}
