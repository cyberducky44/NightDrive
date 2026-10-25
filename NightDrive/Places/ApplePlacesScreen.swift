import SwiftUI
import MapKit

struct ApplePlacesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: ApplePlaceSearchModel
    @State private var selected: ApplePlace?
    @State private var mapMessage: String?
    @FocusState private var searchFocused: Bool

    init(request: PlacesRequest) {
        _model = StateObject(wrappedValue: ApplePlaceSearchModel(request: request))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Address, postcode or place", text: $model.query)
                            .textInputAutocapitalization(.words).autocorrectionDisabled()
                            .submitLabel(.search).focused($searchFocused)
                            .accessibilityIdentifier("placeSearchField")
                            .onSubmit(submit)
                        if !model.query.isEmpty {
                            Button { model.query = ""; model.search() } label: { Image(systemName: "xmark.circle.fill") }
                                .accessibilityLabel("Clear search")
                        }
                        Button("Search", action: submit).accessibilityIdentifier("submitPlaceSearch")
                    }.padding(12).background(NightTheme.panel)
                    if geometry.size.width > 700 {
                        HStack(spacing: 0) { results.frame(width: 310); map }
                    } else {
                        VStack(spacing: 0) { map.frame(height: max(180, geometry.size.height * 0.43)); results }
                    }
                }
            }
            .background(NightTheme.navy)
            .navigationTitle("Places").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closePlaces") } }
            .sheet(item: $selected) { place in
                ApplePlaceCard(place: place) { selected = nil }
            }
            .onDisappear { model.cancel() }
        }
    }

    private var map: some View {
        ApplePlacesMap(initialRegion: model.region, results: model.results, resultVersion: model.resultVersion,
                       onRegion: { model.region = $0 }, onPlace: { selected = $0 }, onError: { mapMessage = $0 })
            .overlay(alignment: .top) {
                if let mapMessage {
                    Text(mapMessage).font(.caption).padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)).padding(8)
                }
            }
    }
    private var results: some View {
        List {
            Section {
                if model.isLoading { ProgressView("Searching Apple Maps…").accessibilityIdentifier("placeSearchLoading") }
                else { Text(model.message).font(.subheadline).accessibilityIdentifier("placeSearchStatus") }
                ForEach(model.results) { place in
                    Button { searchFocused = false; selected = place } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle").foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.title).font(.headline)
                                Text(place.address).font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 4)
                    }.accessibilityIdentifier("placeResult")
                }
            }
            Section {
                Text("Search and place details by Apple Maps. Tap a map POI or a result for its place card. Addresses, phone numbers, photos and ratings depend on availability.")
                Text("Your search and the map area are sent to Apple when you use Places. NightDrive does not save a search history.")
            }.font(.caption).foregroundStyle(.secondary)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    private func submit() {
        searchFocused = false
        mapMessage = nil
        model.search()
    }
}
