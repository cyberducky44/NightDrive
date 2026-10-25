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

### Validation milestone
- Passed simulator and unsigned generic iOS builds in Xcode 27.1.
- Passed all 10 tests on iPhone 18 Pro (iOS 27.0) and all 10 on iPhone Duo (iOS 27.1).
- Verified live map rendering, Duo open/closed adaptation, When In Use permission, simulated GPS/speed, driving camera and pan-to-Explore behavior.
- Corrected initial camera framing before layout, inherited accessibility identifiers, 2D building visibility and UI-test sheet-dismissal timing.
- Added screenshots and exact validation limits, including untested physical GPS and the missing iOS 26 runtime.
- Opened the project in Xcode with the NightDrive scheme and iPhone simulator selected. Signing remains disabled pending team confirmation.


### Physical-device development milestone
- Confirmed the owner's developer team after Xcode account sign-in and provisioned the connected physical iPhone Duo with authorization.
- Added reproducible automatic Apple Development signing with a Git-ignored local team override; fresh checkouts and simulators remain unsigned.
- Built the signed Debug app, verified the signature and device provisioning, and installed/launched NightDrive on the physical Duo.
- Kept certificates, profiles, device identifiers and local account settings out of Git; no Apple distribution or approval submission was performed.
