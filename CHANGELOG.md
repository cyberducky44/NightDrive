# Changelog

## 0.2.0 — 2026-10-25

- Added real OSRM driving routes from GPS or a chosen map start, mint road geometry, route overview, time/distance estimates and maneuver lists.
- Added foreground GPS guidance, bounded local progress, sustained off-route detection, explicit rerouting, arrival, cancellation and precise-location pause states.
- Added optional voice prompts with per-turn cue limits and short-lived audio ducking.
- Shared one route and location manager between the phone and a compiled CarPlay template/map adapter; included system cancellation, search, trip previews, turn estimates, panning, recenter, overview and mute.
- Prepared approval-gated CarPlay scene, navigation entitlement and background-location configuration. These are inactive until Apple approval and subsequent validation. Submitted the navigation entitlement request with the owner-approved addendum and three simulator screenshots; Apple confirmed receipt and approval is pending.
- Reset the route panel scroll position when guidance starts, keeping the next turn visible after browsing the turn list on Duo.
- Prepared release build 4 for internal TestFlight distribution.

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


### Compact controls and POIs milestone
- Added an optional gold POI layer using real named OpenMapTiles points, with collision-aware labels from zoom 15 and an original bundled marker.
- Replaced the large dashboard and bottom camera selector with a compact left rail: speed/details, camera menu, POI toggle, 2D/3D, info and hide.
- Added left-swipe dismissal from the rail or GPS drawer, a restore button, and an accessible hide-button alternative. Hiding controls preserves map selections and visible attribution.
- Kept GPS permission/accuracy and network retry details in the speed drawer; denied location automatically reveals the explanation.
- Extended UI regression checks for POI state, drawer/rail swipes, full-screen restoration, camera menus, attribution, denied location and landscape reachability.
- Passed the 11-check full suite on each simulator and final targeted short-swipe reruns on both; visually verified real POIs and Duo folding.
- Built and signature-verified the signed device update and installed it on the connected Duo. After unlocking, launched and visually verified the updated physical UI, POI labels and swipe-away/restore controls.


### POI filters and recenter milestone
- Replaced dot markers with original gold outlined-circle exclamation marks inspired by Cyberpunk side-job icons.
- Added eight POI category groups, Driving essentials / All / Clear shortcuts, Light / Balanced / Detailed density, and optional street-level place names.
- Defaulted enabled POIs to Light density and icons only; rank/category predicates exclude features before symbol placement. Cached style settings avoid repeating layout-affecting updates on every GPS refresh.
- Added an always-available recenter arrow that resumes Follow, retains Drive when active, and explains unavailable or denied GPS.
- Added category/rank tests and UI checks for filters, full-screen recenter access, permission denial and recentering after panning in simulated Colchester.
- Passed all 15 distinct checks on each simulator, including targeted reruns after correcting switch targeting and compact-sheet scrolling in UI tests.
- Built, signature-verified, installed and launched the signed update on the physical Duo; visually confirmed the updated map and recenter control.
- Documented icon research and a public Colchester sample: Light/all reduced candidate named POIs from 922 to 71 before collision placement; real-device FPS remains unmeasured.

### Apple Places and tappable spots milestone
- Added native Apple Maps address/postcode/place search, an adaptive map/results view, tappable Apple POIs and Apple's place-detail cards with available contact details and richer content.
- Kept Apple data on its corresponding Apple map, preserving attribution and avoiding any secondary POI/review database or overlay onto the neon map.
- Made rendered gold OpenStreetMap POIs tappable and added press-and-hold dropped pins with a highlighted selection and spot-details sheet.
- Added an explicit Find in Apple Maps transition from a selected spot, without assuming a database match.
- Added cancellation, stale-response protection, a 25-result limit and honest empty/loading/failure states; documented search/map-area privacy.
- Validation is simulator-only at the owner's request; no physical Duo installation or testing.
- Passed all 20 checks on each simulator, including live Apple search; manually verified neon-marker selection and native Apple POI cards. Physical Duo testing was excluded as requested; open/folding Places validation remains limited by the simulator display.

### Native search and attribution milestone
- Replaced the separate Apple Maps surface with original navy/cyan search and selected-place panels over the neon map.
- Added free, account-free Photon address/place search with eight-result limit, request cooldown, cancellation, stale-result suppression and honest network/empty states.
- Selecting a result centres the neon map on a gold pin and shows supplied address/category data. Closing details preserves the pin; tapping it reopens details. GPS recenter clears selection.
- Removed Apple Maps requests and native cards; basic search does not claim phone numbers, hours or reviews.
- Moved the linked map attribution to the bottom-left corner while preserving all provider credits and full-screen visibility.
- Aligned the location/recenter button inside the sidebar on Duo-sized layouts (440pt+). It floats at bottom right when the sidebar is hidden or search/details are open.
- Passed 13 unit checks and all 8 UI scenarios on each simulator, with targeted corrections for panel accessibility and Duo safe-area width. No physical-device testing.

### TestFlight preparation
- Prepared Release 0.1.0 (2), built its archive successfully and added the standard-networking encryption declaration.
- Registered the app identifier and created the NightDrive Neon Maps App Store Connect record after the owner resolved the agreement requirement. Distribution/upload status is recorded separately.

### Internal TestFlight milestone
- Uploaded 0.1.0 (2) with explicitly authorized automatic distribution signing and the Internal Only distribution option.
- Confirmed Apple's processed build status is Testing and assigned it to NightDrive Internal with the existing owner as the sole tester; future build assignment remains manual.
- Retained matching upstream MapLibre device symbols locally after a non-blocking upload warning; Apple-side MapLibre crash symbolication remains unverified.
- Added the verified Duo sidebar-location screenshot and recorded release/testing limits. No physical Duo installation or testing, external beta review or App Store submission.
