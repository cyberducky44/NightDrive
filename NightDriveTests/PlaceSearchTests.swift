import XCTest
import CoreLocation
@testable import NightDrive

@MainActor
final class PlaceSearchTests: XCTestCase {
    private final class ControlledSearch: PlaceSearching {
        var pending: [String: CheckedContinuation<[SearchPlace], Error>] = [:]
        var started: ((String) -> Void)?
        func search(query: String, center: CLLocationCoordinate2D) async throws -> [SearchPlace] {
            try await withCheckedThrowingContinuation { continuation in
                pending[query] = continuation
                started?(query)
            }
        }
        func resolve(_ query: String, _ result: Result<[SearchPlace], Error>) {
            pending.removeValue(forKey: query)?.resume(with: result)
        }
    }
    private let request = PlacesRequest(center: .init(latitude: 51.8893, longitude: 0.9012))

    func testBlankSearchDoesNotContactProvider() {
        let service = ControlledSearch()
        let model = PlaceSearchModel(request: request, service: service)
        model.query = "  \n "
        model.search()
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(service.pending.isEmpty)
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertEqual(model.message, "Enter an address, postcode or place.")
    }

    func testSupersededSearchCannotReplaceNewerResults() async {
        let service = ControlledSearch()
        let model = PlaceSearchModel(request: request, service: service)
        let oldStarted = expectation(description: "Old search started")
        service.started = { _ in oldStarted.fulfill() }
        model.query = "old"
        model.search()
        await fulfillment(of: [oldStarted], timeout: 2)
        let newStarted = expectation(description: "New search started")
        service.started = { _ in newStarted.fulfill() }
        model.query = "new"
        model.search()
        await fulfillment(of: [newStarted], timeout: 2)
        let item = SearchPlace(id: "new", name: "New result", address: "Colchester", category: nil, coordinate: request.center, sourceURL: nil)
        service.resolve("new", .success([item]))
        for _ in 0..<50 where model.isLoading { await Task.yield() }
        XCTAssertEqual(model.results.first?.name, "New result")
        service.resolve("old", .success([]))
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.results.first?.name, "New result")
        XCTAssertFalse(model.isLoading)
    }

    func testFailureAndCancellationHaveHonestStates() async {
        let service = ControlledSearch()
        let model = PlaceSearchModel(request: request, service: service)
        let started = expectation(description: "Search started")
        service.started = { _ in started.fulfill() }
        model.query = "Colchester"
        model.search()
        await fulfillment(of: [started], timeout: 2)
        service.resolve("Colchester", .failure(URLError(.notConnectedToInternet)))
        for _ in 0..<50 where model.isLoading { await Task.yield() }
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertEqual(model.message, "Search unavailable. Check your connection and try again.")
        model.cancel()
        XCTAssertFalse(model.isLoading)
    }
    func testPhotonDecodingValidatesCoordinatesDeduplicatesAndBuildsAddress() throws {
        let json = #"{"features":[{"geometry":{"type":"Point","coordinates":[0.903,51.89]},"properties":{"osm_type":"W","osm_id":28621900,"name":"Colchester Castle","street":"Mayor’s Walk","city":"Colchester","postcode":"CO1 1TJ","osm_value":"museum"}},{"geometry":{"type":"Point","coordinates":[0.903,51.89]},"properties":{"osm_type":"W","osm_id":28621900}},{"geometry":{"type":"Point","coordinates":[0,999]},"properties":{}}]}"#
        let results = try PhotonPlaceSearch.decode(Data(json.utf8))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].coordinate.latitude, 51.89)
        XCTAssertEqual(results[0].coordinate.longitude, 0.903)
        XCTAssertEqual(results[0].address, "Mayor’s Walk, Colchester, CO1 1TJ")
        XCTAssertEqual(results[0].sourceURL?.absoluteString, "https://www.openstreetmap.org/way/28621900")
        XCTAssertEqual(results[0].spot.name, "Colchester Castle")
        XCTAssertThrowsError(try PhotonPlaceSearch.decode(Data("not JSON".utf8)))
    }
}
