# NightDrive

A personal native SwiftUI map for **iOS 26+**, inspired by dark navy maps, cyan streets and red 3D buildings. Built with **MapLibre Native 6.31.0**, OpenFreeMap vector tiles and OpenMapTiles / OpenStreetMap data. No API key is needed.

![NightDrive on the open iPhone Duo simulator](docs/screenshots/duo-open.png)

## Run

Open `NightDrive.xcodeproj`, choose the **NightDrive** scheme and an installed iPhone simulator, then Run. Xcode resolves the pinned Swift package automatically. On Xcode 27, simulator windows are in **Device Hub**. The deployment target is iOS 26; validation on this Mac uses its installed iOS 27.0 and 27.1 runtimes.

The checked-in project is ready to open. To regenerate it after changing targets/settings, install XcodeGen (`brew install xcodegen`) and run `xcodegen generate`. `project.yml` is the settings source of truth; keep regenerated project changes together with it. The shared scheme includes unit and UI tests.

```sh
xcodebuild -project NightDrive.xcodeproj -scheme NightDrive \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO

# Substitute a device ID from: xcrun simctl list devices available
xcodebuild -project NightDrive.xcodeproj -scheme NightDrive \
  -destination 'platform=iOS Simulator,id=DEVICE_ID' \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

## Use

- **Explore:** pan, zoom, rotate and tilt the real map. The initial view is central London, a public demonstration location, not your position.
- **Follow:** request When In Use access and follow a fresh location north-up.
- **Drive:** follow position with a tilted, course-aligned camera. At low speed, an available compass heading is used. This is **not turn-by-turn navigation**.
- **2D / 3D:** switch building extrusion and map tilt. Any map gesture returns the camera to Explore.
- **Info:** map credits, privacy details and the scope of later stages.

Controls adapt to available space: compact bottom controls on regular/narrow iPhones, a side dashboard on wide Duo/open or tablet displays, and compact landscape support. No model-name checks are used. Dynamic Type and Reduce Motion are supported.

## GPS and privacy

The app requests **When In Use** location only from Follow/Drive. It never requests Always access, enables background location, saves a location trail or sends analytics. Updates stop when the app is not active. Denied/restricted access leaves map exploration available; denied access provides a Settings link. Reduced accuracy is identified. Stale (>15 seconds), invalid and very poor (>1 km) fixes are not used for camera tracking; unavailable speed stays unknown rather than becoming zero.

Map tiles and glyphs require network access for uncached regions. OpenFreeMap receives your IP address and requested map areas. No bulk/offline download feature is implemented. GPS speed is informational and is not a calibrated vehicle speedometer.

## Architecture

- `App/`: SwiftUI entry point.
- `UI/`: adaptive dashboard, controls and linked attribution.
- `Location/LocationService.swift`: the single Core Location owner and permission/lifecycle state.
- `Map/NightMapView.swift`: UIKit MapLibre bridge, GPS marker and camera synchronization. Gestures release follow mode.
- `Map/CameraMode.swift`: camera policy and location-quality rules.
- `Resources/nightdrive.json`: original style bundled with the app; remote vector tiles and fonts only. Regenerate with `python3 scripts/generate_style.py`.
- `Navigation/NavigationContracts.swift`: provider-neutral route/maneuver and presentation interfaces for later routing and CarPlay.
- `NightDriveTests/` and `NightDriveUITests/`: meaningful location/camera/style checks and UI regression checks.

See [validation notes](docs/VALIDATION.md) for executed checks and limitations, and [architecture plan](docs/ARCHITECTURE.md) for subsequent stages.

## Signing and future Apple work

**No Apple Developer team is configured.** Simulator builds use `CODE_SIGNING_ALLOWED=NO`, with signing disabled in the project. A physical-device run first requires confirming the intended Apple Developer team and bundle ID. Only then enable automatic **development** signing locally. Ask before creating any new certificate/profile or changing account security. Keep personal signing overrides out of Git.

No CarPlay entitlements, approval applications, TestFlight uploads, App Store submissions or Apple review requests have been made. These are separate future actions.

## Credits

- [MapLibre Native](https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/gettingstarted/) — BSD 2-Clause.
- [OpenFreeMap](https://openfreemap.org/quick_start/) — tile and glyph hosting.
- [OpenMapTiles](https://openmaptiles.org/) and [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) — map data/schema; linked attribution remains visible on the map.

This is an independent personal project, not affiliated with CD Projekt Red. Styling and the app icon are original; no game assets, reference screenshots or third-party app code are distributed in this repository. See [third-party notices](THIRD_PARTY_NOTICES.md).
