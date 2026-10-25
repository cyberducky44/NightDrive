# NightDrive stages

## Stage 1: real map and foreground GPS

SwiftUI owns presentation state. A single MainActor LocationService creates Core Location on the main thread; delegate conformance uses `@preconcurrency` because the Objective-C protocol does not express that callback guarantee. MapLibre does not create another user-location manager. The bridge draws a position annotation from accepted fixes and updates the camera only when mode, fix timestamp or heading changes. Gesture reasons switch back to Explore. The bundled style uses the published OpenMapTiles layers and real building heights where available (6 m fallback when absent).

The UI responds to measured width/height and accessibility text size. All screens use a collapsible compact rail. Search and selected-place panels sit over the existing map, with bounded width/height and scrollable content. The renderer and style remain the same across device layouts.

## Search and place inspection

Neon-map selection reads visible POI features from the existing symbol layer, with a bounded tap area. Long press selects a coordinate. Both produce MapSpot. Photon search results carry a name, address, category, validated coordinate and optional OSM source URL; selecting one creates the same MapSpot and a one-time focus request. Closing its panel preserves the selected marker, which can be tapped again. Recenter clears it. Subsequent GPS updates do not overwrite the search camera in Explore mode.

PlaceSearchModel owns transient results and injects PlaceSearching for tests. Explicit submissions cancel prior work and discard late replies using a generation token. PhotonPlaceSearch uses an ephemeral URLSession, a 15-second request timeout, eight-result cap, coordinate validation/deduplication and shared request cooldown. There are no searches on typing, map pan, tile taps or location updates. No paid API credential is needed. The endpoint is isolated in the provider for replacement before public scaling.

PlaceSearchPanel and MapSpotPanel use NightDrive colours and typography over MapLibre, with no MapKit surface or Apple requests remaining. The previous Apple integration is recorded only as historical documentation. Selecting Directions passes the same destination to the shared routing session.

## Stage 2: routing and guidance

OSRMRoutingService supplies genuine car geometry and maneuvers. NavigationSession owns destination, cancelable requests, preview, active guidance, stale/off-route states and arrival. RouteGeometry projects fixes locally within a bounded progress window. Route source/layers are added to MapLibre without replacing the base style. Manual rerouting is deliberately explicit on the modest-use public service. VoiceGuidance formats bounded cues and manages short-lived voicePrompt audio sessions. See [routing details](ROUTING.md).

## Stage 3: CarPlay entitlement and integration

NavigationRuntime shares one location manager and routing session across phone and the prepared CarPlaySceneDelegate. CarPlay renders map content in its own window and uses CPMapTemplate, CPSearchTemplate, CPTrip and CPNavigationSession for interactions and instructions. Search is explicit, all essential destination/route actions are available through templates, and system cancellation ends the shared route. The source is compiled, but the scene, entitlement and background location mode are isolated behind the optional approval-gated configuration. Apple approval and CarPlay runtime/hardware testing are outstanding; see [CarPlay setup](CARPLAY.md).

## Future hardening

Real-device GPS and compass calibration, energy/thermal behavior, poor-network tile coverage, accessibility sizes, and long-session map behavior need physical-device validation. No location persistence or analytics is required for the current design. Any offline download feature needs a deliberate storage, licensing and provider-policy review.
