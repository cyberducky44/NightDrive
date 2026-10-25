import SwiftUI
import MapKit

/// Apple search results and built-in Apple POIs stay on this Apple map.
struct ApplePlacesMap: UIViewRepresentable {
    let initialRegion: MKCoordinateRegion
    let results: [ApplePlace]
    let resultVersion: UUID
    let onRegion: (MKCoordinateRegion) -> Void
    let onPlace: (ApplePlace) -> Void
    let onError: (String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
        map.selectableMapFeatures = [.pointsOfInterest]
        map.setRegion(initialRegion, animated: false)
        map.accessibilityIdentifier = "applePlacesMap"
        return map
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        guard coordinator.version != resultVersion else { return }
        coordinator.version = resultVersion
        // Cancel a pending feature lookup if a newer search supersedes it.
        coordinator.cancelLookup()
        map.removeAnnotations(map.annotations.filter { $0 is PlaceAnnotation })
        let pins = results.map(PlaceAnnotation.init)
        map.addAnnotations(pins)
        if !pins.isEmpty { map.showAnnotations(pins, animated: !UIAccessibility.isReduceMotionEnabled) }
    }
    static func dismantleUIView(_ map: MKMapView, coordinator: Coordinator) {
        coordinator.cancelLookup()
        map.delegate = nil
    }

    final class PlaceAnnotation: NSObject, MKAnnotation {
        let place: ApplePlace
        var coordinate: CLLocationCoordinate2D { place.item.location.coordinate }
        var title: String? { place.title }
        init(_ place: ApplePlace) { self.place = place }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ApplePlacesMap
        var version: UUID?
        private var request: MKMapItemRequest?
        private var lookupID = UUID()
        init(_ parent: ApplePlacesMap) { self.parent = parent }
        func cancelLookup() { lookupID = UUID(); request?.cancel(); request = nil }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.onRegion(mapView.region)
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is PlaceAnnotation else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "applePlace")
            view.markerTintColor = UIColor(NightTheme.navy)
            view.glyphTintColor = .systemYellow
            view.glyphImage = UIImage(systemName: "exclamationmark")
            view.canShowCallout = false
            return view
        }
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            cancelLookup()
            mapView.deselectAnnotation(annotation, animated: false)
            if let pin = annotation as? PlaceAnnotation {
                parent.onError(nil)
                parent.onPlace(pin.place)
            } else if let feature = annotation as? MKMapFeatureAnnotation {
                let id = lookupID
                let request = MKMapItemRequest(mapFeatureAnnotation: feature)
                self.request = request
                parent.onError("Loading place details…")
                request.getMapItem { [weak self] item, error in
                    guard let self, self.lookupID == id else { return }
                    self.request = nil
                    if let item {
                        self.parent.onError(nil)
                        self.parent.onPlace(ApplePlace(item: item))
                    } else {
                        self.parent.onError("Place details unavailable. Try again or search by name.")
                    }
                }
            }
        }
    }
}

struct ApplePlaceCard: UIViewControllerRepresentable {
    let place: ApplePlace
    let onDismiss: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onDismiss) }
    func makeUIViewController(context: Context) -> MKMapItemDetailViewController {
        let controller = MKMapItemDetailViewController(mapItem: place.item, displaysMap: true)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: MKMapItemDetailViewController, context: Context) {}
    final class Coordinator: NSObject, MKMapItemDetailViewControllerDelegate {
        let dismiss: () -> Void
        init(_ dismiss: @escaping () -> Void) { self.dismiss = dismiss }
        func mapItemDetailViewControllerDidFinish(_ detailViewController: MKMapItemDetailViewController) { dismiss() }
    }
}
