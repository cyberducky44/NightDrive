import SwiftUI
import CoreLocation

struct MapSpot: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
    let category: String?
    var address: String? = nil
    var sourceURL: URL? = nil
    var coordinateText: String { String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude) }
}

struct MapSpotPanel: View {
    let spot: MapSpot
    let findPlaces: () -> Void
    let route: () -> Void
    let close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SELECTED SPOT").font(.system(.caption, design: .monospaced, weight: .bold)).tracking(2)
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("Close selected spot").accessibilityIdentifier("closeSpot")
            }.foregroundStyle(NightTheme.cyan)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Label(spot.name, systemImage: "exclamationmark.circle").font(.title2).foregroundStyle(.yellow)
                    if let category = spot.category { Text(category.replacingOccurrences(of: "_", with: " ").capitalized).font(.subheadline) }
                    if let address = spot.address, !address.isEmpty { Text(address).font(.subheadline).foregroundStyle(NightTheme.muted) }
                    Text(spot.coordinateText).font(.system(.caption, design: .monospaced)).foregroundStyle(NightTheme.muted)
                    Button(action: route) {
                        Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("spotDirections")
                    Button(action: findPlaces) {
                        Label(spot.category == nil ? "Search this area" : "Search this name", systemImage: "magnifyingglass")
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("findSpotPlaces")
                    if let sourceURL = spot.sourceURL {
                        Link("View OpenStreetMap listing", destination: sourceURL).font(.caption)
                    }
                    Text("OpenStreetMap place data. Address coverage varies; phone numbers and reviews are not supplied.")
                        .font(.caption2).foregroundStyle(NightTheme.muted)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(14)
        .background(NightTheme.panel.opacity(0.98), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NightTheme.cyan.opacity(0.45)))
    }
}
