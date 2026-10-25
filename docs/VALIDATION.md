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

The updated signed Debug build and strict signature verification passed, and installation on the physical Duo succeeded. After the owner unlocked the device, launch succeeded. The physical screen showed the compact rail, GPS details, gold POI labels, swipe-away full-screen map and restored controls, with attribution retained. The app was observed in closed and open device layouts. No physical screenshot or location was saved to the repository. This confirms the UI smoke check; extended GPS/road-use acceptance remains unverified.

## POI filtering and recenter — 2026-10-25

- Simulator build passed. Nine unit tests passed on regular iPhone 18 Pro (iOS 27.0) and Duo (iOS 27.1), including category exclusion and bounded zoom-dependent density.
- Six UI scenarios were exercised on both: camera/About/attribution, landscape, denied location via recenter, category presets/empty selection, POI on/off plus swipe-away restoration, and recenter after panning from a simulated public Colchester location.
- The initial regular-iPhone toggle tap hit the Form row rather than reliably toggling the switch. Targeting the switch thumb and waiting for the sheet fixed the test; its targeted rerun passed.
- On Duo, a whole-app swipe moved the compact sheet's navigation chrome out of view. The category test now scrolls from a category control and returns upward before tapping Done; its targeted rerun passed.
- Visually verified the new original circled-exclamation markers at Colchester, optional names appearing after zooming in, and the recentered GPS marker at the public test coordinate. Simulation was cleared afterward.
- The [Colchester workload sample](POI_DESIGN.md) found 922 previous named candidates versus 71 in Light/all at zoom 16. This is candidate filtering evidence, not a measured frame-rate improvement or proof all lag is resolved.
- Signed Debug build and strict signature verification passed. Updated app installed and launched successfully on the connected physical Duo.

Evidence: [filter sheet](screenshots/poi-filters.png), [Colchester circled POIs](screenshots/colchester-pois.png), [optional street-level names](screenshots/colchester-names.png). These screenshots contain only a public simulator test location.

Local test result bundles: `/tmp/NightDrive-Filters-iPhone.xcresult`, `/tmp/NightDrive-Filters-iPhone-Retry.xcresult`, `/tmp/NightDrive-Filters-Duo.xcresult`, `/tmp/NightDrive-Filters-Duo-Retry.xcresult`. The regular-iPhone category-scroll follow-up is `/tmp/NightDrive-Filters-iPhone-Category.xcresult`.

Physical city-centre frame rate, battery, thermals and road-use GPS/heading remain unmeasured. The earlier minimum-runtime and accessibility limitations still apply. No distribution or Apple approval action was performed.

The regular-iPhone category-scroll follow-up also passed. All 15 distinct checks have now passed on each simulator, with the targeted corrections above. On the physical Duo, the running updated map, compact rail and separate recenter arrow were visually observed in the open layout; extended interaction/performance acceptance is still separate.

## Apple Places and map inspection — 2026-10-25

- Simulator build succeeded. Final full suites passed on iPhone 18 Pro (iOS 27.0) and iPhone Duo (iOS 27.1): **12 unit tests and 8 UI tests per simulator, zero failures**.
- New unit coverage verifies blank-query handling, failure states and suppression of an older response arriving after a newer search. UI coverage exercises a dropped pin, opening/closing Places, search access with controls hidden and a live Colchester Castle search. Existing filters, recenter, landscape, permissions and map-control checks still pass.
- Manually tapped the neon map's Charing Cross tube station marker: the selected-spot sheet showed the OSM name/category; Find in Apple Maps prefilled the name in Places. Long-press selection remains available independently of visible POIs.
- Manually opened Colchester Castle's native Apple card from a live result on the closed Duo simulator; address, phone, website, hours and a rating were present. Tapping Apple's built-in Trafalgar Square map feature on the regular iPhone also opened its native card with the correct address and rating. No calls, rating submissions or external directions were started.
- Fixed a SwiftUI state-update warning by deferring the neon map's camera-centre callback. Neither final suite contains that warning. Xcode's unrelated App Intents metadata warning remains (the app has no App Intents dependency).
- The regular iPhone full suite preceded a small overlay change that hides search while the GPS drawer is open to prevent overlapping its Close button; the Duo full suite includes that change. Subsequent source changes are whitespace and documentation only.
- An initial iPhone run completed its tests but stalled in result collection; its runner was stopped after the independent final suite completed successfully. Final evidence is the two successful bundles below.
- The Duo simulator's fold controls did not reliably switch to a rendered open display during this run (black/stale display). The new Places screen has a width-based side-by-side layout, but open/folding Places presentation is **not visually accepted** from this run. Closed layouts and existing landscape regression checks passed.
- No physical Duo interaction, installation, signing/provisioning or Apple distribution action was performed. The missing iOS 26 runtime, physical performance, extended accessibility and driving limitations above remain. Routing/CarPlay are still future milestones.

Evidence: [selected neon POI](screenshots/selected-poi.png), [Apple place card](screenshots/apple-place-card.png). Public London/Colchester simulator content only.

Final local result bundles (not committed): `/tmp/NightDrive-Places-iPhone-Final.xcresult` and `/tmp/NightDrive-Places-Duo.xcresult`.

## Native Photon search, attribution and Duo rail — 2026-10-25

- Thirteen unit checks passed on both regular iPhone and Duo simulators, including coordinate validation, deduplication, address parsing, empty/failure states and late-response suppression.
- All eight UI scenarios passed on each simulator, including real Photon search and selection of Colchester Castle on the neon map, dropped-pin search, hidden-rail search, POI filters, recenter, denied permission and landscape. Initial new-panel checks used a container identifier that propagated to its children; removing it and targeting the actual Close button fixed the checks.
- After adding the sidebar location button, the full eight-case iPhone suite passed. The Duo suite exposed safe-area width reduction near its camera cutout. Using full display width fixed the adaptive rule; final targeted landscape, recenter and denied-permission checks all passed on Duo. The other seven UI cases had passed before that width correction.
- Manual simulator inspection confirmed the live Colchester Castle result's name/address/category, gold marker on the castle, original navy/cyan panels, and bottom-left provider attribution. No physical Duo interaction, installation or testing occurred.
- Final result evidence: `/tmp/NightDrive-Photon-iPhone-Retry.xcresult`, `/tmp/NightDrive-Photon-Duo.xcresult`, `/tmp/NightDrive-Photon-Rail-iPhone.xcresult`, `/tmp/NightDrive-Photon-Duo-Rail-Retry.xcresult`. The initial iPhone runner was stopped after its tests finished and result collection stalled; successful independent reruns provide final evidence.
- The public Photon service is suitable only for modest use; no load test was run. Broader availability, iOS 26 runtime, physical driving/thermal acceptance and fully opened Duo presentation remain unverified.

Screenshots: [native search](screenshots/nightdrive-native-search.png), [selected result on neon map](screenshots/nightdrive-native-place.png), [Duo sidebar location button](screenshots/nightdrive-duo-sidebar-location.png). Public simulator coordinates only.

## TestFlight preparation — 2026-10-25

The owner requested internal TestFlight setup and personally resolved Apple's agreement blocker. Registered the explicit NightDrive identifier under the same confirmed development team and created the App Store Connect record as **NightDrive Neon Maps** (the shorter NightDrive name was unavailable). Bundle/display name remain unchanged.

Release archive **0.1.0 (2)** built successfully using existing development signing, with no provisioning-update flag. Added the non-exempt-encryption declaration for this build's standard HTTPS networking; MapLibre includes its own required-reason privacy manifest. Distribution signing/upload is a separate subsequent step; archive success alone is not TestFlight availability.

## Internal TestFlight release — 2026-10-25

- Following explicit owner approval for automatic distribution signing and upload, Xcode uploaded **0.1.0 (2)** using **TestFlight Internal Only**. Organizer reports Uploaded to Apple; App Store Connect processed it and reports **Testing**.
- Assigned the build to **NightDrive Internal**, with only the existing account owner as its one tester. Automatic distribution is disabled; future builds must be assigned deliberately. No external tester group or beta/App Store review submission was made.
- Xcode reported a non-blocking missing MapLibre dSYM warning. Downloaded the separate device symbols from the [official 6.31.0 release](https://github.com/maplibre/maplibre-native/releases/tag/ios-v6.31.0), verified their UUID matches the archived arm64 framework, and retained them in the local archive's dSYMs directory for local crash diagnosis. They were recovered after upload, so Apple-side MapLibre symbolication is **not verified**. Include matching upstream device symbols before future archive uploads. No SDK upgrade or binary replacement was made.
- Archive and signing materials remain local; no credentials or personal tester details are committed. The app record is [NightDrive Neon Maps](https://appstoreconnect.apple.com/apps/6826899785).
- Saved build-specific What to Test notes. The final internal tester record reports **Installed 0.1.0 (2)** on iPhone Duo. This is Apple-reported installation status, not an agent-run launch or physical UI test; no physical device was controlled during this milestone. Prior simulator acceptance remains the evidence for this build's UI.
