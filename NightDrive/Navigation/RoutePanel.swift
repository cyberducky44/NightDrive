import SwiftUI
import CoreLocation

struct RoutePanel: View {
    @ObservedObject var session: NavigationSession
    @ObservedObject private var voice = NavigationRuntime.shared.voice
    let gpsStatus: String
    let canUseGPS: Bool
    let fromGPS: () -> Void
    let chooseMapStart: () -> Void
    let start: () -> Void
    let overview: () -> Void
    let close: () -> Void
    @State private var showsTurns = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.phase == .navigating ? "ON ROUTE" : session.phase == .arrived ? "ROUTE END" : "DRIVING ROUTE")
                    .font(.system(.caption, design: .monospaced, weight: .bold)).tracking(2)
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("End route").accessibilityIdentifier("endRoute")
            }.foregroundStyle(NightTheme.cyan)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(session.destination?.name ?? "Destination").font(.headline).lineLimit(2)
                    if session.phase == .loading {
                        ProgressView("Finding a driving route…").accessibilityIdentifier("routeLoading")
                    } else if session.phase == .choosingStart {
                        Text("Choose your start").font(.subheadline)
                        if let message = session.message { Text(message).foregroundStyle(.yellow).accessibilityIdentifier("routeError") }
                        Button(action: fromGPS) { Label(canUseGPS ? "Route from my location" : "Enable / refresh GPS", systemImage: "location.fill").frame(minHeight: 44) }
                            .accessibilityIdentifier("routeFromGPS")
                        if !canUseGPS { Text(gpsStatus + " · a fresh, precise fix is required.").font(.caption).foregroundStyle(NightTheme.muted) }
                        Button(action: chooseMapStart) { Label("Choose start on map", systemImage: "scope").frame(minHeight: 44) }
                            .accessibilityIdentifier("chooseRouteStart")
                        privacy
                    } else if let route = session.route {
                        if session.phase == .navigating {
                            if let status = session.guidanceStatus {
                                Label(status, systemImage: "location.slash").foregroundStyle(.yellow).accessibilityIdentifier("guidanceStatus")
                            } else if let turn = session.nextManeuver {
                                Label {
                                    VStack(alignment: .leading) {
                                        Text(RouteFormatting.distance(session.distanceToManeuver)).font(.title2.monospacedDigit())
                                        Text(turn.instruction).font(.headline)
                                    }
                                } icon: { Image(systemName: turn.symbol).font(.largeTitle) }
                                .foregroundStyle(NightTheme.cyan).accessibilityIdentifier("nextTurn")
                            }
                        } else if session.phase == .arrived {
                            Label("Route end reached", systemImage: "flag.checkered").font(.title2).foregroundStyle(NightTheme.cyan)
                            Text("Check the map for the final approach to your destination.").font(.caption)
                        } else {
                            Text("From \(session.originName)").font(.caption).foregroundStyle(NightTheme.muted)
                            if let first = route.maneuvers.first { Text(first.instruction).font(.subheadline) }
                        }
                        if session.phase != .arrived {
                            Text("\(RouteFormatting.distance(session.phase == .preview ? route.distanceMeters : session.remainingMeters)) · ~\(RouteFormatting.time(session.phase == .preview ? route.durationSeconds : session.remainingSeconds))")
                                .font(.system(.title3, design: .monospaced, weight: .semibold))
                                .accessibilityIdentifier("routeSummary")
                            Text("Estimated driving time · no live traffic").font(.caption2).foregroundStyle(NightTheme.muted)
                        }
                        if let message = session.message { Text(message).font(.caption).foregroundStyle(.yellow).accessibilityIdentifier("routeError") }
                        if session.phase == .preview {
                            Button(action: start) { Label("Start guidance", systemImage: "arrow.triangle.turn.up.right.diamond.fill").frame(minHeight: 44) }
                                .accessibilityIdentifier("startGuidance")
                        }
                        Button { voice.isMuted.toggle() } label: {
                            Label(voice.isMuted ? "Voice off" : "Voice on", systemImage: voice.isMuted ? "speaker.slash" : "speaker.wave.2")
                                .frame(minHeight: 44)
                        }.accessibilityIdentifier("routeVoice")
                        HStack {
                            Button(action: overview) { Label("Overview", systemImage: "map").frame(minHeight: 44) }.accessibilityIdentifier("routeOverview")
                            Spacer()
                            Button { showsTurns.toggle() } label: { Label("Turns", systemImage: "list.bullet").frame(minHeight: 44) }.accessibilityIdentifier("routeTurns")
                        }
                        if session.phase != .arrived {
                            Button(action: fromGPS) {
                                Label("Recalculate from my location", systemImage: "arrow.trianglehead.2.clockwise").frame(minHeight: 44)
                            }.accessibilityIdentifier("reroute")
                            if session.isOffRoute { Text("Request a new route when safe. Progress is held while off route.").font(.caption).foregroundStyle(.yellow) }
                        }
                        if showsTurns {
                            ForEach(route.maneuvers) { step in
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(step.instruction, systemImage: step.symbol)
                                    if step.distanceMeters > 0 { Text("Then \(RouteFormatting.distance(step.distanceMeters))").font(.caption).foregroundStyle(NightTheme.muted) }
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                            }
                        }
                        Text("Foreground guidance only. Keep NightDrive open. Routes end on the nearest accessible road.")
                            .font(.caption2).foregroundStyle(NightTheme.muted)
                        privacy
                    }
                    HStack {
                        Link("OSRM / FOSSGIS", destination: URL(string: "https://routing.openstreetmap.de/about.html")!)
                        Spacer()
                        Link("Fix the map", destination: URL(string: "https://www.openstreetmap.org/fixthemap")!)
                    }.font(.caption2)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.scrollIndicators(.visible).accessibilityIdentifier("routeContents")
        }.padding(12)
        .background(NightTheme.panel.opacity(0.98), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NightTheme.cyan.opacity(0.5)))
    }
    private var privacy: some View {
        Text("Requesting a route sends start and destination coordinates to FOSSGIS (OSRM), which logs requests. GPS progress stays on this device. Free beta service; availability varies.")
            .font(.caption2).foregroundStyle(NightTheme.muted)
    }
}
