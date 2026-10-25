import XCTest
import MapKit
@testable import NightDrive

@MainActor
final class ApplePlaceSearchTests: XCTestCase {
    private final class ControlledSearch: ApplePlaceSearching {
        var pending: [String: CheckedContinuation<[MKMapItem], Error>] = [:]
        var started: ((String) -> Void)?
        func search(query: String, region: MKCoordinateRegion) async throws -> [MKMapItem] {
            try await withCheckedThrowingContinuation { continuation in
                pending[query] = continuation
                started?(query)
            }
        }
        func cancel() {} // Simulates a provider that finishes even after cancellation.
        func resolve(_ query: String, _ result: Result<[MKMapItem], Error>) {
            pending.removeValue(forKey: query)?.resume(with: result)
        }
    }
    private let request = PlacesRequest(center: .init(latitude: 51.8893, longitude: 0.9012))

    func testBlankSearchDoesNotContactProvider() {
        let service = ControlledSearch()
        let model = ApplePlaceSearchModel(request: request, service: service)
        model.query = "  \n "
        model.search()
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(service.pending.isEmpty)
        XCTAssertTrue(model.results.isEmpty)
        XCTAssertEqual(model.message, "Enter an address, postcode or place.")
    }

    func testSupersededSearchCannotReplaceNewerResults() async {
        let service = ControlledSearch()
        let model = ApplePlaceSearchModel(request: request, service: service)
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
        let item = MKMapItem(location: CLLocation(latitude: 51.8893, longitude: 0.9012), address: nil)
        item.name = "New result"
        service.resolve("new", .success([item]))
        for _ in 0..<50 where model.isLoading { await Task.yield() }
        XCTAssertEqual(model.results.first?.title, "New result")
        service.resolve("old", .success([]))
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.results.first?.title, "New result")
        XCTAssertFalse(model.isLoading)
    }

    func testFailureAndCancellationHaveHonestStates() async {
        let service = ControlledSearch()
        let model = ApplePlaceSearchModel(request: request, service: service)
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
}
