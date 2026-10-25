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
- Real-device installation: the user must confirm the Apple Developer team and bundle ID before signing; any new certificates/profiles require explicit permission.
- Routing and CarPlay remain architecture only, deliberately unimplemented in Stage 1.

No Apple Developer team was selected, automatic signing enabled, certificate/profile created, CarPlay entitlement requested, TestFlight build uploaded, or App Store/Apple review submission made.
