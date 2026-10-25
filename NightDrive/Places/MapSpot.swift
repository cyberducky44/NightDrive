import SwiftUI
import CoreLocation

/// A spot selected from OpenMapTiles or directly by the user, never Apple data.
struct MapSpot: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
    let category: String?
    var coordinateText: String { String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude) }
}

struct MapSpotSheet: View {
    let spot: MapSpot
    let findPlaces: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(spot.name, systemImage: "exclamationmark.circle").font(.title2).foregroundStyle(.yellow)
                    if let category = spot.category { Text(category.replacingOccurrences(of: "_", with: " ").capitalized) }
                    Text(spot.coordinateText).font(.system(.subheadline, design: .monospaced)).textSelection(.enabled)
                }
                Section {
                    Button(action: findPlaces) { Label("Find in Apple Maps", systemImage: "magnifyingglass") }
                        .accessibilityIdentifier("findSpotInAppleMaps")
                    Text("Opens Places around this spot. Search to choose a matching result; map databases may describe places differently.").font(.caption)
                }
                Section {
                    Text(spot.category == nil ? "A spot you selected on the map." : "Place from OpenStreetMap / OpenMapTiles. This tile does not include phone numbers, reviews or full address details.")
                }.font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("Selected spot").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
    }
}
