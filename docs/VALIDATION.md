# Validation — 2026-10-25

Application source validated at `e42f03f` on the user's Apple Silicon Mac, macOS 27.0.1, Xcode 27.1 (27A9275). Deployment target: iOS 26.0. MapLibre package: 6.31.0, locked revision `13e41ab3d77ff5113e7e5d4ee87803b1f81f5683`.

## Executed checks

| Check | Result |
| --- | --- |
| iOS simulator build | Passed |
| Generic iOS / physical-device architecture build, **unsigned** | Passed; no device installation or provisioning |
| iPhone 18 Pro, iOS 27.0 | 7 unit tests + 3 UI tests passed, zero failures |
| iPhone Duo, iOS 27.1 | 7 unit tests + 3 UI tests passed, zero failures |
| Map and glyph requests | Live OpenFreeMap data rendered; original navy/cyan/red style and 3D buildings visually inspected |
| Regular iPhone portrait and landscape | Controls and linked attribution visible/hittable; About sheet opens and dismisses |
| Duo open and folded closed | Wide sidebar and compact layouts visually inspected; screenshots saved |
| Foreground permission grant | System When In Use prompt exercised on Duo; accepted simulated fix and GPS marker verified |
| Denied permission | Automated on both devices; explanation, Settings link and Explore fallback verified |
| Driving camera | Simulated public London waypoints at 8 m/s displayed 18 mph and followed movement |
| Manual pan during Drive | Verified that it returns to Explore while continuing to show the GPS fix |
| Stale/invalid GPS | Unit tests cover old/future/invalid/inaccurate fixes and unknown speed; stale simulator fix visibly changes to Waiting for GPS |
| Repository hygiene | Staged path and text scan found no signing files, Xcode user state, tokens or private-key patterns; Git diff whitespace checks passed |

The simulator tracks use public demonstration coordinates, not the user's actual location or a recorded journey. Simulation was cleared after checks. No physical driving test was performed.

Unit tests cover location freshness/accuracy, unavailable speed, mph conversion, course vs heading selection, north-up Follow policy, and bundled style/source/attribution structure. UI tests cover denied location, map controls, attribution, About dismissal and landscape accessibility. The same 10 tests passed on each device (20 test executions total).

An initial UI run failed because the assertion checked a button before the About sheet dismissal finished. The test now waits for the control to become hittable; both complete reruns passed. Initial camera framing and inherited accessibility identifiers were corrected before final validation.

Xcode emitted non-failing tool/runtime diagnostics about its operating-system build-number parsing, duplicate simulator accessibility classes and skipped App Intents metadata. Final application compilation had no source warnings or errors. The app does not use App Intents.

## Evidence

- [Duo open](screenshots/duo-open.png)
- [Duo closed](screenshots/duo-closed.png)
- [Regular iPhone with simulated GPS](screenshots/iphone-simulated-gps.png)

Local result bundles from this run (not committed): `/tmp/NightDrive-iPhone-Final.xcresult` and `/tmp/NightDrive-Duo-Final.xcresult`. These temporary files may be removed by macOS. Tests are reproducible through the shared NightDrive scheme and commands in README.

## Not yet verified / blocked on later decisions

- iOS 26 runtime execution: no iOS 26 simulator runtime is installed; only the deployment target and compilation are checked for this minimum.
- Physical-device GPS/heading accuracy, orientation/calibration, reduced-accuracy behavior, background/foreground transitions in real use, battery/thermal use and long drives.
- Exhaustive Dynamic Type/VoiceOver, low-connectivity, tile outages and all geographic/building coverage.
- Real-device installation was subsequently completed, as recorded below. Physical GPS and driving acceptance remain separate checks.
- Routing and CarPlay remain architecture only, deliberately unimplemented in Stage 1.

At the initial simulator milestone, no Apple Developer team was selected, automatic signing enabled, or certificate/profile created. No CarPlay entitlement request, TestFlight upload, or App Store/Apple review submission has been made.


## Physical-device development installation — 2026-10-25

The owner explicitly authorized the necessary development certificates/profiles and connected their iPhone Duo. After the owner signed in to Xcode, the single available individual developer team was verified. The device was paired with Developer Mode already enabled.

- Added shared signing configuration plus an ignored local team override; no team ID, device identifier, credential, certificate or profile is stored in Git.
- Automatic Apple Development signing built successfully for the connected physical iPhone Duo running iOS 27.1.
- Xcode generated a development provisioning profile containing the connected device, expiring 25 October 2027.
- Strict recursive code-signature verification passed; the embedded profile allows development debugging and includes the connected device.
- Device installation and launch both succeeded through Apple's device tools.
- The real device screen was inspected in Device Hub: the map and controls rendered successfully. No physical-device screenshot or location was saved to Git.
- Xcode has the physical Duo selected for subsequent Run actions. The unsigned simulator build also still passes after the signing configuration change.
- Real GPS permission and road-use/battery/compass acceptance have not been claimed from installation alone.

This was a development installation only. No archive distribution, CarPlay approval, TestFlight upload or App Store submission was performed.


## Compact rail and POIs — 2026-10-25

- The full suite passed on regular iPhone 18 Pro (iOS 27.0) and Duo (iOS 27.1): 7 unit checks and 4 UI checks on each, zero failures.
- Verified real named POIs render with gold dots/labels, and disappear when toggled off. The style adds one collision-aware symbol layer, initially hidden, with zoom 15 minimum.
- UI checks cover menu choices, 2D/3D, permission denial, GPS drawer dismissal, POI state across hide/restore, retained attribution, About and landscape controls.
- A follow-up rail-only swipe check exposed that the distance threshold was too large for short gestures on a narrow button. Reduced the threshold and added a rail-width drag check in addition to the existing drawer swipe. Final targeted reruns passed on both the regular iPhone and Duo.
- Visually inspected the compact rail and POIs on regular iPhone, Duo open, partially open and closed; full-screen mode and restoring the rail work across Duo folding.
- Simulator screenshots use the public London demonstration map, with no physical-device location captured.

Current evidence: [regular iPhone with POIs](screenshots/compact-pois.png), [Duo compact rail](screenshots/duo-compact.png), [Duo full-screen map](screenshots/duo-fullscreen.png). The earlier screenshots above document the previous dashboard.

Local result bundles: `/tmp/NightDrive-Controls-iPhone.xcresult`, `/tmp/NightDrive-Controls-Duo.xcresult`, `/tmp/NightDrive-ShortSwipe-iPhone.xcresult`, and `/tmp/NightDrive-ShortSwipe-Duo.xcresult`. One multi-destination retry was interrupted while Xcode stalled collecting failure diagnostics; subsequent verification uses individual destinations.

A simulator crash report records a MapLibre worker-thread crash just after the first unit-test suite finished and its host was shutting down (14:01:03 UTC). The suite itself reported success. It did not recur in the later Duo full suite, targeted reruns or manual map checks. This is recorded as an unresolved test-host teardown issue; it is not proof that extended physical use is crash-free.

The updated signed Debug build and strict signature verification passed, and installation on the physical Duo succeeded. Launch was blocked by the device lock screen; the updated physical UI has not yet been inspected.
