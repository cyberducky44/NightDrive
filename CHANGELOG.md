# Changelog

## 0.1.0 — 2026-10-25

### Repository foundation
- Initialized the private NightDrive project and milestone workflow.
- Excluded credentials, signing material, build products and personal Xcode state.
- Recorded the map/GPS scope and deferred routing and CarPlay milestones.

### Native map and GPS milestone
- Added a real iOS 26+ SwiftUI Xcode project, shared scheme, pinned MapLibre 6.31.0 dependency and XcodeGen specification.
- Created a bundled 24-layer navy/cyan/red OpenFreeMap style with building extrusion, street/place labels and linked map attribution.
- Added foreground When In Use Core Location, permission/accuracy/freshness handling, unknown-speed display and a GPS marker.
- Added Explore, Follow and Drive camera modes, manual-gesture release, 2D/3D controls and adaptive compact/wide layouts.
- Added original app icon, information/privacy sheet and routing/CarPlay architecture boundaries.
- Built the simulator app and passed seven initial location/camera/style unit tests; UI and final layout validation in progress.
