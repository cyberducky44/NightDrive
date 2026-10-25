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
        if coordinator.last3D != is3D {
            coordinator.last3D = is3D
            let camera = map.camera
            camera.pitch = is3D ? 55 : 0
            map.setCamera(camera, animated: !reduceMotion)
        }
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

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: NightMapView
        var marker: MLNPointAnnotation?
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
            appliedPOISettings = nil
            appliedRank = nil
            applied3D = nil
            applyStyleSettings(to: mapView)
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
