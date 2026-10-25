import SwiftUI

struct DriveScreen: View {
    @StateObject private var gps = LocationService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicType
    @State private var mode: CameraMode = .free
    @State private var is3D = true
    @State private var mapStatus = "Loading map…"
    @State private var reloadID = 0
    @State private var showingInfo = false

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && geometry.size.height >= 450 && !dynamicType.isAccessibilitySize
            ZStack(alignment: .topLeading) {
                NightMapView(mode: $mode, mapStatus: $mapStatus, location: gps.currentLocation,
                             heading: gps.heading, is3D: is3D, reloadID: reloadID, reduceMotion: reduceMotion)
                    .ignoresSafeArea()
                LinearGradient(colors: [NightTheme.navy.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 160).ignoresSafeArea().allowsHitTesting(false)
                if wide {
                    VStack(alignment: .leading, spacing: 18) {
                        brand
                        statusPanel
                        cameraControls
                        Spacer()
                        Text("THE CITY, AFTER DARK.")
                            .font(.system(.caption2, design: .monospaced)).tracking(2).foregroundStyle(NightTheme.muted)
                    }
                    .padding(20).frame(width: 290)
                    .background(NightTheme.navy.opacity(0.94))
                    HStack { Spacer(); utilityControls }.padding(20)
                } else {
                    VStack(spacing: 12) {
                        HStack(alignment: .top) { brand; Spacer(); utilityControls }
                        if geometry.size.height >= 450 { statusPanel.frame(maxWidth: 360, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading) }
                        Spacer()
                    }.padding(16)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 8) {
                VStack(spacing: 10) {
                    if !wide { cameraControls.padding(.horizontal, 16) }
                    attribution
                }
                .padding(.bottom, 4)
            }
        }
        .background(NightTheme.navy)
        .sheet(isPresented: $showingInfo) { information }
        .onChange(of: scenePhase) { _, phase in gps.setActive(phase == .active) }
        .onChange(of: gps.authorization) { _, _ in
            if !gps.isAuthorized && gps.authorization != .notDetermined { mode = .free }
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

    private var utilityControls: some View {
        VStack(spacing: 10) {
            Button { is3D.toggle() } label: {
                Text(is3D ? "3D" : "2D").font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .frame(width: 48, height: 48)
            }.accessibilityLabel(is3D ? "Switch to 2D map" : "Switch to 3D map").accessibilityIdentifier("toggle3D")
            Button { showingInfo = true } label: {
                Image(systemName: "info").frame(width: 48, height: 48)
            }.accessibilityLabel("About NightDrive").accessibilityIdentifier("aboutButton")
        }
        .foregroundStyle(NightTheme.cyan)
        .background(NightTheme.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NightTheme.cyan.opacity(0.25)))
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocationQuality.speedMPH(gps.currentLocation).map(String.init) ?? "—")
                    .font(.system(size: 38, weight: .light, design: .monospaced)).monospacedDigit()
                Text("MPH").font(.system(.caption2, design: .monospaced)).foregroundStyle(NightTheme.muted)
                Spacer()
                Image(systemName: gps.currentLocation == nil ? "location.slash" : "location.fill").foregroundStyle(NightTheme.cyan)
            }.accessibilityElement(children: .combine).accessibilityLabel("Speed, \(LocationQuality.speedMPH(gps.currentLocation).map { "\($0) miles per hour" } ?? "unavailable")")
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

    private var cameraControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mode == .free ? "FREE EXPLORATION" : mode == .follow ? "FOLLOWING POSITION" : "DRIVING CAMERA")
                    .font(.system(.caption2, design: .monospaced, weight: .semibold)).tracking(1)
                    .accessibilityIdentifier("cameraStatus")
                Spacer(minLength: 4)
                Circle().fill(NightTheme.cyan).frame(width: 5, height: 5)
            }.foregroundStyle(NightTheme.muted)
            HStack(spacing: 6) {
                ForEach(CameraMode.allCases) { option in
                    Button {
                        mode = option
                        if option != .free {
                            if option == .driving { is3D = true }
                            if option == .follow { is3D = false }
                            gps.requestAccess()
                            if gps.authorization == .denied || gps.authorization == .restricted { mode = .free }
                        }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: option.symbol).font(.title3)
                            Text(option.title).font(.system(.caption, design: .monospaced, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .foregroundStyle(mode == option ? NightTheme.navy : NightTheme.cyan)
                        .background(mode == option ? NightTheme.cyan : NightTheme.cyan.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("mode_\(option.rawValue)")
                    .accessibilityAddTraits(mode == option ? [.isSelected] : [])
                }
            }
            if mode == .driving {
                Text("Camera only · Turn-by-turn routing comes later")
                    .font(.caption2).foregroundStyle(NightTheme.muted)
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

    private var information: some View {
        NavigationStack {
            List {
                Section("NightDrive · Stage 1") {
                    Text("A neon map of the real world. Explore freely, follow your location north-up, or use a tilted driving camera aligned to your direction of travel.")
                    Text("Pan, zoom or rotate to return to Explore. Drive is a camera mode; route planning and turn-by-turn directions are not available yet.")
                }
                Section("Location & privacy") {
                    Text("Location is used only while NightDrive is active. No location history or analytics is recorded by the app. Map tiles and fonts are requested from OpenFreeMap, which can see your IP address and the map areas requested.")
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
