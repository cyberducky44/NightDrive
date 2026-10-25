# NightDrive stages

## Stage 1: real map and foreground GPS

SwiftUI owns presentation state. A single MainActor LocationService creates Core Location on the main thread; delegate conformance uses `@preconcurrency` because the Objective-C protocol does not express that callback guarantee. MapLibre does not create another user-location manager. The bridge draws a position annotation from accepted fixes and updates the camera only when mode, fix timestamp or heading changes. Gesture reasons switch back to Explore. The bundled style uses the published OpenMapTiles layers and real building heights where available (6 m fallback when absent).

The UI responds to measured width/height and accessibility text size. All screens use a collapsible compact rail. Search and selected-place panels sit over the existing map, with bounded width/height and scrollable content. The renderer and style remain the same across device layouts.

## Search and place inspection

Neon-map selection reads visible POI features from the existing symbol layer, with a bounded tap area. Long press selects a coordinate. Both produce MapSpot. Photon search results carry a name, address, category, validated coordinate and optional OSM source URL; selecting one creates the same MapSpot and a one-time focus request. Closing its panel preserves the selected marker, which can be tapped again. Recenter clears it. Subsequent GPS updates do not overwrite the search camera in Explore mode.

PlaceSearchModel owns transient results and injects PlaceSearching for tests. Explicit submissions cancel prior work and discard late replies using a generation token. PhotonPlaceSearch uses an ephemeral URLSession, a 15-second request timeout, eight-result cap, coordinate validation/deduplication and shared request cooldown. There are no searches on typing, map pan, tile taps or location updates. No paid API credential is needed. The endpoint is isolated in the provider for replacement before public scaling.

PlaceSearchPanel and MapSpotPanel use NightDrive colours and typography over MapLibre, with no MapKit surface or Apple requests remaining. The previous Apple integration is recorded only as historical documentation. Search provides discovery, not routes or turn-by-turn navigation.

## Stage 2: routing

Choose a provider after comparing coverage, licensing, cost, offline needs and privacy. Implement RoutingService to return DriveRoute geometry and RouteManeuver instructions. Add a navigation session with route progress, off-route detection, rerouting, destination search and cancellation. Keep geometry/progress independent of SwiftUI and MapLibre; add a route source/layers without replacing the base style. Use genuine route responses; no decorative route line presented as navigation. Add replay tests using public fixture coordinates and manual real-device acceptance before driving use.

## Stage 3: CarPlay

Only after explicit authorization and the necessary Apple entitlement/approval, add a CarPlay scene and platform presentation adapter consuming the same navigation session. Respect CarPlay templates and driver-distraction rules. Entitlements, background operation, audio guidance and provisioning must be reviewed at this stage. No CarPlay framework, scene declaration or entitlement is shipped in Stage 1.

## Future hardening

Real-device GPS and compass calibration, energy/thermal behavior, poor-network tile coverage, accessibility sizes, and long-session map behavior need physical-device validation. No location persistence or analytics is required for the current design. Any offline download feature needs a deliberate storage, licensing and provider-policy review.
