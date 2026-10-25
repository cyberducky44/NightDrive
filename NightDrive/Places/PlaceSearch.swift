import Foundation
import CoreLocation
import Combine

struct PlacesRequest: Identifiable {
    let id = UUID()
    var query = ""
    var center: CLLocationCoordinate2D
}

struct SearchPlace: Identifiable {
    let id: String
    let name: String
    let address: String
    let category: String?
    let coordinate: CLLocationCoordinate2D
    let sourceURL: URL?
    var spot: MapSpot {
        MapSpot(coordinate: coordinate, name: name, category: category,
                address: address, sourceURL: sourceURL)
    }
}

@MainActor
protocol PlaceSearching {
    func search(query: String, center: CLLocationCoordinate2D) async throws -> [SearchPlace]
}

enum PlaceSearchError: Error {
    case busy, unavailable
}

/// Modest, explicit searches against Photon's public community service.
/// No autocomplete, background lookup, persistent cache or account is needed.
@MainActor
final class PhotonPlaceSearch: PlaceSearching {
    private static var nextRequestAt = Date.distantPast
    private let session: URLSession
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        config.urlCache = nil
        config.httpCookieStorage = nil
        session = URLSession(configuration: config)
    }
    func search(query: String, center: CLLocationCoordinate2D) async throws -> [SearchPlace] {
        guard Date() >= Self.nextRequestAt else { throw PlaceSearchError.busy }
        Self.nextRequestAt = Date().addingTimeInterval(2)
        var url = URLComponents(string: "https://photon.komoot.io/api/")!
        url.queryItems = [URLQueryItem(name: "q", value: query),
                         URLQueryItem(name: "limit", value: "8"),
                         URLQueryItem(name: "lang", value: "en"),
                         URLQueryItem(name: "lat", value: String(center.latitude)),
                         URLQueryItem(name: "lon", value: String(center.longitude))]
        var request = URLRequest(url: url.url!)
        request.setValue("NightDrive/0.1 (https://github.com/cyberducky44/NightDrive)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw PlaceSearchError.unavailable }
        if response.statusCode == 429 {
            let retry = Double(response.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 60
            Self.nextRequestAt = Date().addingTimeInterval(max(30, min(retry, 3600)))
            throw PlaceSearchError.busy
        }
        guard (200..<300).contains(response.statusCode) else { throw PlaceSearchError.unavailable }
        return try Self.decode(data)
    }
    static func decode(_ data: Data) throws -> [SearchPlace] {
        let response = try JSONDecoder().decode(PhotonResponse.self, from: data)
        var seen = Set<String>()
        return response.features.compactMap { feature -> SearchPlace? in
            let point = feature.geometry.coordinates
            guard feature.geometry.type == "Point", point.count >= 2,
                  point[0].isFinite, point[1].isFinite,
                  (-180...180).contains(point[0]), (-90...90).contains(point[1]) else { return nil }
            let p = feature.properties
            let street = [p.housenumber, p.street].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            var parts: [String] = []
            for part in [street, p.city ?? p.district ?? "", p.postcode ?? "", p.country ?? ""] where !part.isEmpty {
                if !parts.contains(part) { parts.append(part) }
            }
            let name = p.name ?? (street.isEmpty ? (p.city ?? p.postcode ?? "Map place") : street)
            let id = "\(p.osm_type ?? "")\(p.osm_id.map(String.init) ?? "\(point[0]),\(point[1])")"
            guard seen.insert(id).inserted else { return nil }
            let kind = ["N": "node", "W": "way", "R": "relation"][p.osm_type ?? ""]
            let source = kind.flatMap { kind in p.osm_id.flatMap { $0 > 0 ? URL(string: "https://www.openstreetmap.org/\(kind)/\($0)") : nil } }
            return SearchPlace(id: id, name: name, address: parts.joined(separator: ", "),
                               category: p.osm_value, coordinate: .init(latitude: point[1], longitude: point[0]), sourceURL: source)
        }.prefix(8).map { $0 }
    }
}

private struct PhotonResponse: Decodable {
    let features: [Feature]
    struct Feature: Decodable {
        let geometry: Geometry
        let properties: Properties
    }
    struct Geometry: Decodable { let type: String; let coordinates: [Double] }
    struct Properties: Decodable {
        let osm_type: String?
        let osm_id: Int64?
        let osm_value: String?
        let name: String?
        let housenumber: String?
        let street: String?
        let district: String?
        let city: String?
        let postcode: String?
        let country: String?
    }
}

@MainActor
final class PlaceSearchModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [SearchPlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message = "Search for an address, postcode or place."
    let center: CLLocationCoordinate2D
    private let service: any PlaceSearching
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(request: PlacesRequest, service: (any PlaceSearching)? = nil) {
        query = request.query
        center = request.center
        self.service = service ?? PhotonPlaceSearch()
    }
    func search() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        cancel()
        results = []
        guard !text.isEmpty else { message = "Enter an address, postcode or place."; return }
        guard text.count <= 200 else { message = "Try a shorter search (up to 200 characters)."; return }
        let requestID = UUID()
        generation = requestID
        isLoading = true
        message = "Searching…"
        task = Task {
            do {
                let places = try await service.search(query: text, center: center)
                guard !Task.isCancelled, generation == requestID else { return }
                results = Array(places.prefix(8))
                message = results.isEmpty ? "No places found. Try a town, postcode or a more specific name." : "\(results.count) results · Choose a place to show it on the map."
            } catch {
                guard !Task.isCancelled, generation == requestID else { return }
                message = error is PlaceSearchError && (error as? PlaceSearchError) == .busy
                    ? "Search is busy. Please wait a moment before trying again."
                    : "Search unavailable. Check your connection and try again."
            }
            if generation == requestID { isLoading = false }
        }
    }
    func cancel() {
        generation = UUID()
        task?.cancel()
        task = nil
        isLoading = false
    }
}
