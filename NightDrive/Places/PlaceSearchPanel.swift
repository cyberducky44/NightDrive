import SwiftUI

struct PlaceSearchPanel: View {
    @StateObject private var model: PlaceSearchModel
    @FocusState private var focused: Bool
    let select: (SearchPlace) -> Void
    let close: () -> Void
    init(request: PlacesRequest, select: @escaping (SearchPlace) -> Void, close: @escaping () -> Void) {
        _model = StateObject(wrappedValue: PlaceSearchModel(request: request))
        self.select = select
        self.close = close
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("FIND A PLACE", systemImage: "magnifyingglass")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold)).tracking(1)
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("Close search").accessibilityIdentifier("closePlaces")
            }.foregroundStyle(NightTheme.cyan)
            HStack(spacing: 8) {
                TextField("Address, postcode or place", text: $model.query)
                    .focused($focused).submitLabel(.search)
                    .textInputAutocapitalization(.words).autocorrectionDisabled()
                    .accessibilityIdentifier("placeSearchField").onSubmit(submit)
                    .padding(10).background(NightTheme.navy, in: RoundedRectangle(cornerRadius: 8))
                Button(action: submit) {
                    Image(systemName: "arrow.right").frame(width: 44, height: 44)
                        .background(NightTheme.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }.accessibilityLabel("Search").accessibilityIdentifier("submitPlaceSearch")
                    .disabled(model.isLoading)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.isLoading { ProgressView("Searching…").tint(NightTheme.cyan) }
                    Text(model.message).font(.caption).foregroundStyle(NightTheme.muted)
                        .accessibilityIdentifier("placeSearchStatus")
                    ForEach(model.results) { place in
                        Button { focused = false; select(place) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle").foregroundStyle(.yellow).font(.title2)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(place.name).font(.headline).foregroundStyle(.white)
                                    if !place.address.isEmpty { Text(place.address).font(.caption).foregroundStyle(NightTheme.muted) }
                                }
                                Spacer(minLength: 0)
                            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(NightTheme.cyan.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain).accessibilityIdentifier("placeResult")
                    }
                    HStack {
                        Link("Photon", destination: URL(string: "https://photon.komoot.io")!)
                        Text("·")
                        Link("© OpenStreetMap", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    }.font(.caption).foregroundStyle(NightTheme.cyan).padding(.top, 6)
                    Text("Your search and map area go to Photon. Basic place data; no reviews or contact directory. No search history is saved.")
                        .font(.caption2).foregroundStyle(NightTheme.muted)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.scrollDismissesKeyboard(.interactively)
        }
        .padding(14)
        .background(NightTheme.panel.opacity(0.98), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NightTheme.cyan.opacity(0.45)))
        .onDisappear { model.cancel() }
    }
    private func submit() { focused = false; model.search() }
}
