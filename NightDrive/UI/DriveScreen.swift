import SwiftUI
import CoreLocation

struct DriveScreen: View {
    @StateObject private var gps = LocationService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: CameraMode = .free
    @State private var is3D = true
    @State private var mapStatus = "Loading map…"
    @State private var reloadID = 0
    @State private var showingInfo = false
    @State private var poiSettings = POISettings()
    @State private var showingPOIFilters = false
    @State private var recenterID = 0
    @State private var controlsVisible = true
    @State private var showingDetails = false
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
    @State private var selectedSpot: MapSpot?
    @State private var placesRequest: PlacesRequest?
    @State private var pendingPlaces: PlacesRequest?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                NightMapView(mode: $mode, mapStatus: $mapStatus, location: gps.currentLocation,
                             heading: gps.heading, is3D: is3D, poiSettings: poiSettings, recenterID: recenterID,
                             reloadID: reloadID, reduceMotion: reduceMotion,
                             selectedSpot: selectedSpot,
                             onSpot: { mode = .free; selectedSpot = $0 },
                             onCenter: { mapCenter = $0 })
                    .ignoresSafeArea()
                if controlsVisible {
                    HStack(alignment: .top, spacing: 8) {
                        ScrollView { controlRail }
                            .scrollIndicators(.hidden)
                            .frame(width: 56)
                            .fixedSize(horizontal: false, vertical: true)
                        if showingDetails {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        brand
                                        Spacer(minLength: 0)
                                        Button { showingDetails = false } label: {
                                            Image(systemName: "xmark").frame(width: 44, height: 44)
                                        }.accessibilityLabel("Close GPS details")
                                    }
                                    statusPanel
                                    Text("Swipe left to hide controls")
                                        .font(.caption).foregroundStyle(NightTheme.muted)
                                }.padding(12)
                            }
                            .frame(width: min(290, max(180, geometry.size.width - 88)))
                            .fixedSize(horizontal: false, vertical: true)
                            .background(NightTheme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(12)
                    .simultaneousGesture(DragGesture(minimumDistance: 10).onEnded { value in
                        if value.translation.width < -12 && abs(value.translation.width) > abs(value.translation.height) {
                            setControlsVisible(false)
                        }
                    })
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Button { setControlsVisible(true) } label: {
                        Image(systemName: "sidebar.left").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Show map controls").accessibilityIdentifier("showControls")
                    .background(NightTheme.panel.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                    .padding(12)
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .topTrailing) {
                if !showingDetails || !controlsVisible {
                    Button { placesRequest = PlacesRequest(center: mapCenter) } label: {
                        Image(systemName: "magnifyingglass").font(.title3).frame(width: 48, height: 48)
                    }
                    .accessibilityLabel("Search addresses and places").accessibilityIdentifier("openPlaces")
                    .background(NightTheme.panel.opacity(0.96), in: Circle())
                    .overlay(Circle().stroke(NightTheme.cyan.opacity(0.3))).padding(12)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    selectMode(mode == .driving ? .driving : .follow)
                    recenterID += 1
                    if gps.currentLocation == nil { showingDetails = true; controlsVisible = true }
                } label: {
                    Image(systemName: "location.fill").font(.title3).frame(width: 48, height: 48)
                }
                .accessibilityLabel("Recenter on my location").accessibilityIdentifier("recenterButton")
                .background(NightTheme.panel.opacity(0.96), in: Circle())
                .overlay(Circle().stroke(NightTheme.cyan.opacity(0.3)))
                .padding(16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { attribution.padding(.bottom, 4) }

        }
        .background(NightTheme.navy)
        .fullScreenCover(item: $placesRequest) { request in ApplePlacesScreen(request: request) }
        .sheet(item: $selectedSpot, onDismiss: {
            if let pendingPlaces { placesRequest = pendingPlaces; self.pendingPlaces = nil }
        }) { spot in
            MapSpotSheet(spot: spot) {
                pendingPlaces = PlacesRequest(query: spot.category == nil ? "" : spot.name, center: spot.coordinate)
                selectedSpot = nil
            }
        }
        .sheet(isPresented: $showingInfo) { information }
        .sheet(isPresented: $showingPOIFilters) { poiFilters }
        .onChange(of: scenePhase) { _, phase in gps.setActive(phase == .active) }
        .onChange(of: gps.authorization) { _, _ in
            if !gps.isAuthorized && gps.authorization != .notDetermined { mode = .free; showingDetails = true }
        }
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 0) {
                Text("NIGHT").foregroundStyle(.white)
                Text("DRIVE").foregroundStyle(NightTheme.cyan)
            }.font(.system(.title2, design: .rounded, weight: .black)).tracking(2)
            HStack(spacing: 6) {
                Rectangle().fill(NightTheme.red).frame(width: 18, height: 3)
                Text("NEON GRID / 01").font(.system(.caption2, design: .monospaced)).tracking(2)
            }.foregroundStyle(NightTheme.muted)
        }.accessibilityElement(children: .combine)
    }

    private var controlRail: some View {
        VStack(spacing: 2) {
            Button { showingDetails.toggle() } label: {
                VStack(spacing: 0) {
                    Text(LocationQuality.speedMPH(gps.currentLocation).map(String.init) ?? "—")
                        .font(.system(.title3, design: .monospaced, weight: .semibold)).monospacedDigit()
                    Text("MPH").font(.system(size: 9, weight: .bold, design: .monospaced))
                }.frame(width: 52, height: 52)
            }
            .accessibilityLabel("Speed, \(LocationQuality.speedMPH(gps.currentLocation).map { "\($0) miles per hour" } ?? "unavailable"). \(gps.status). Show GPS details")
            .accessibilityIdentifier("speedDetails")
            Divider().overlay(NightTheme.cyan.opacity(0.3)).padding(.horizontal, 8)
            Menu {
                ForEach(CameraMode.allCases) { option in
                    Button { selectMode(option) } label: {
                        Label(option.title, systemImage: mode == option ? "checkmark" : option.symbol)
                    }.accessibilityIdentifier("mode_\(option.rawValue)")
                }
            } label: {
                Image(systemName: mode.symbol).frame(width: 52, height: 44)
            }
            .accessibilityLabel("Camera mode, \(mode.title)")
            .accessibilityIdentifier("cameraMenu")
            Button { showingPOIFilters = true } label: {
                Image(systemName: "exclamationmark.circle")
                    .frame(width: 52, height: 44)
                    .foregroundStyle(poiSettings.enabled ? Color.yellow : NightTheme.cyan)
                    .background(poiSettings.enabled ? NightTheme.cyan.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Points of interest filters")
            .accessibilityValue(poiSettings.enabled ? "On" : "Off").accessibilityIdentifier("poiFilters")
            Button { is3D.toggle() } label: {
                Text(is3D ? "3D" : "2D").font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .frame(width: 52, height: 44)
            }.accessibilityLabel(is3D ? "Switch to 2D map" : "Switch to 3D map").accessibilityIdentifier("toggle3D")
            Button { showingInfo = true } label: {
                Image(systemName: "info.circle").frame(width: 52, height: 44)
            }.accessibilityLabel("About NightDrive").accessibilityIdentifier("aboutButton")
            Button { setControlsVisible(false) } label: {
                Image(systemName: "chevron.left").frame(width: 52, height: 44)
            }.accessibilityLabel("Hide map controls").accessibilityIdentifier("hideControls")
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .foregroundStyle(NightTheme.cyan)
        .background(NightTheme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NightTheme.cyan.opacity(0.25)))
    }

    private func setControlsVisible(_ visible: Bool) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            controlsVisible = visible
            if !visible { showingDetails = false }
        }
    }

    private func selectMode(_ option: CameraMode) {
        mode = option
        guard option != .free else { return }
        is3D = option == .driving
        gps.requestAccess()
        if gps.authorization == .denied || gps.authorization == .restricted { mode = .free; showingDetails = true }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(gps.status).font(.subheadline).accessibilityIdentifier("gpsStatus")
            if let location = gps.currentLocation {
                Text("ACCURACY ±\(Int(location.horizontalAccuracy)) M")
                    .font(.system(.caption2, design: .monospaced)).foregroundStyle(NightTheme.muted)
            } else {
                Text(gps.isAuthorized ? "Your position will appear when a fresh fix arrives." : "Explore the map, or enable GPS to follow your position.")
                    .font(.caption).foregroundStyle(NightTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
            if gps.authorization == .denied {
                Button("Open location settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                    .font(.subheadline)
            }
            if mapStatus != "Map ready" {
                HStack {
                    Text(mapStatus).font(.caption).foregroundStyle(NightTheme.muted)
                    if mapStatus.contains("unavailable") { Button("Retry") { mapStatus = "Loading map…"; reloadID += 1 } }
                }
            }
        }.modifier(HUDPanel())
    }

    private var attribution: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { attributionLinks }
            VStack(spacing: 6) { attributionLinks }
        }
        .font(.system(size: 10)).foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(NightTheme.navy.opacity(0.95), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder private var attributionLinks: some View {
        Link("OpenFreeMap", destination: URL(string: "https://openfreemap.org")!)
        Link("© OpenMapTiles", destination: URL(string: "https://openmaptiles.org")!)
        Link("© OpenStreetMap", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
    }

    private var poiFilters: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show points of interest", isOn: $poiSettings.enabled).accessibilityIdentifier("togglePOIs")
                    Picker("Detail", selection: $poiSettings.density) {
                        ForEach(POIDensity.allCases) { density in Text(density.title).tag(density) }
                    }.accessibilityIdentifier("poiDensity")
                    Toggle("Show place names", isOn: $poiSettings.showsNames).accessibilityIdentifier("poiNames")
                    Text("Light shows fewer places for busy centres. More appear as you zoom in; names appear at street level. Try 2D for a lighter map when many buildings are visible.")
                        .font(.caption).foregroundStyle(NightTheme.muted)
                }
                Section("Quick filters") {
                    Button("Driving essentials") { poiSettings.categories = [.parking, .fuel]; poiSettings.enabled = true }
                        .accessibilityIdentifier("poiDriving")
                    Button("All categories") { poiSettings.categories = Set(POICategory.allCases) }
                        .accessibilityIdentifier("poiAll")
                    Button("Clear categories") { poiSettings.categories = [] }
                        .accessibilityIdentifier("poiClear")
                }
                Section("Categories") {
                    ForEach(POICategory.allCases) { category in
                        Toggle(category.title, isOn: Binding(
                            get: { poiSettings.categories.contains(category) },
                            set: { selected in
                                if selected { poiSettings.categories.insert(category) }
                                else { poiSettings.categories.remove(category) }
                            }))
                            .accessibilityIdentifier("poi_\(category.rawValue)")
                    }
                    if poiSettings.categories.isEmpty { Text("No categories selected — no POIs will appear.").font(.caption) }
                }
            }
            .navigationTitle("Points of interest")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingPOIFilters = false } } }
        }.presentationDragIndicator(.visible)
    }

    private var information: some View {
        NavigationStack {
            List {
                Section("NightDrive · Maps & Places") {
                    Text("A neon map of the real world. Explore freely, follow your location north-up, or use a tilted driving camera aligned to your direction of travel.")
                    Text("Pan, zoom or rotate to return to Explore. Drive is a camera mode; route planning and turn-by-turn directions are not available yet.")
                }
                Section("Map controls") {
                    Text("Tap the speed badge for GPS details. The camera menu switches between Explore, Follow and Drive. Tap the circled exclamation mark to choose POI categories, detail and place names. Tap the separate location arrow to recenter and follow your position; Drive keeps its driving camera. Zoom in for more places. Coverage depends on the map data. Tap a gold marker to inspect it, or hold the map to drop a pin. The search button opens Apple Maps Places for addresses, postcodes and place cards. Route guidance is not available yet.")
                    Text("Swipe left across the controls, or tap the chevron, for a full-screen map. Tap the sidebar icon to bring the controls back. Attribution stays visible.")
                }
                Section("Location & privacy") {
                    Text("Location is used only while NightDrive is active. No location history or analytics is recorded by the app. Places sends searches and the viewed map area to Apple; results stay in memory for that screen and are not added to the neon map. Map tiles and fonts are requested from OpenFreeMap, which can see your IP address and the map areas requested.")
                    Text("Approximate location is supported. GPS accuracy and building coverage depend on the device and available map data. A network connection is needed for uncached areas.")
                }
                Section("Map credits") {
                    attributionLinks
                    Link("MapLibre Native · BSD 2-Clause", destination: URL(string: "https://github.com/maplibre/maplibre-native/blob/main/LICENSE.md")!)
                    Text("Original NightDrive styling. Independent personal project; not affiliated with CD Projekt Red. No Cyberpunk 2077 assets included.")
                }
                Section("Later stages") {
                    Text("Routing will use a separate provider. CarPlay will follow as a separate integration after the required authorization. Neither is enabled in this build.")
                }
            }
            .navigationTitle("NightDrive")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingInfo = false } } }
        }.presentationDragIndicator(.visible)
    }
}

#Preview("iPhone") { DriveScreen() }
#Preview("Wide", traits: .fixedLayout(width: 900, height: 650)) { DriveScreen() }
