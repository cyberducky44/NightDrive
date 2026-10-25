# NightDrive stages

## Stage 1: real map and foreground GPS

SwiftUI owns presentation state. A single MainActor LocationService creates Core Location on the main thread; delegate conformance uses `@preconcurrency` because the Objective-C protocol does not express that callback guarantee. MapLibre does not create another user-location manager. The bridge draws a position annotation from accepted fixes and updates the camera only when mode, fix timestamp or heading changes. Gesture reasons switch back to Explore. The bundled style uses the published OpenMapTiles layers and real building heights where available (6 m fallback when absent).

The UI responds to measured width/height and accessibility text size. Wide screens get a sidebar; narrow or short screens get bottom camera controls. The renderer and style remain the same across device layouts.

## Stage 2: routing

Choose a provider after comparing coverage, licensing, cost, offline needs and privacy. Implement RoutingService to return DriveRoute geometry and RouteManeuver instructions. Add a navigation session with route progress, off-route detection, rerouting, destination search and cancellation. Keep geometry/progress independent of SwiftUI and MapLibre; add a route source/layers without replacing the base style. Use genuine route responses; no decorative route line presented as navigation. Add replay tests using public fixture coordinates and manual real-device acceptance before driving use.

## Stage 3: CarPlay

Only after explicit authorization and the necessary Apple entitlement/approval, add a CarPlay scene and platform presentation adapter consuming the same navigation session. Respect CarPlay templates and driver-distraction rules. Entitlements, background operation, audio guidance and provisioning must be reviewed at this stage. No CarPlay framework, scene declaration or entitlement is shipped in Stage 1.

## Future hardening

Real-device GPS and compass calibration, energy/thermal behavior, poor-network tile coverage, accessibility sizes, and long-session map behavior need physical-device validation. No location persistence or analytics is required for the current design. Any offline download feature needs a deliberate storage, licensing and provider-policy review.
