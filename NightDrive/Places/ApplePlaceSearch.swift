import MapKit
import Combine

struct PlacesRequest: Identifiable {
    let id = UUID()
    var query = ""
    var center: CLLocationCoordinate2D
}

struct ApplePlace: Identifiable {
    let id = UUID()
    let item: MKMapItem
    var title: String { item.name ?? "Selected place" }
    var address: String { item.address?.fullAddress ?? "Address unavailable" }
}

@MainActor
protocol ApplePlaceSearching {
    func search(query: String, region: MKCoordinateRegion) async throws -> [MKMapItem]
    func cancel()
}

@MainActor
final class MapKitPlaceSearch: ApplePlaceSearching {
    private var active: MKLocalSearch?
    func search(query: String, region: MKCoordinateRegion) async throws -> [MKMapItem] {
        active?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)
        active = search
        return try await search.start().mapItems
    }
    func cancel() { active?.cancel(); active = nil }
}

/// Apple results live only in this screen's memory and are never sent to MapLibre.
@MainActor
final class ApplePlaceSearchModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [ApplePlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message = "Search for an address, postcode or place, or tap a place on the map."
    @Published private(set) var resultVersion = UUID()
    var region: MKCoordinateRegion
    private let service: any ApplePlaceSearching
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(request: PlacesRequest, service: (any ApplePlaceSearching)? = nil) {
        query = request.query
        region = MKCoordinateRegion(center: request.center, latitudinalMeters: 6000, longitudinalMeters: 6000)
        self.service = service ?? MapKitPlaceSearch()
    }

    func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        cancel()
        results = []
        resultVersion = UUID()
        guard !text.isEmpty else {
            message = "Enter an address, postcode or place."
            return
        }
        let requestID = UUID()
        generation = requestID
        isLoading = true
        message = "Searching Apple Maps…"
        let searchRegion = region
        task = Task {
            do {
                let items = try await service.search(query: text, region: searchRegion)
                guard !Task.isCancelled, generation == requestID else { return }
                results = items.prefix(25).map { ApplePlace(item: $0) }
                resultVersion = UUID()
                message = results.isEmpty ? "No places found. Try a town, postcode or a more specific name." : "\(results.count) results · Tap a result or marker for details."
            } catch {
                guard !Task.isCancelled, generation == requestID else { return }
                message = "Search unavailable. Check your connection and try again."
            }
            if generation == requestID { isLoading = false }
        }
    }

    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
        service.cancel()
        isLoading = false
    }
}
