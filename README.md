# NightDrive

A personal native SwiftUI map for **iOS 26+**, inspired by dark navy maps, cyan streets and red 3D buildings. Built with **MapLibre Native 6.31.0**, OpenFreeMap vector tiles and OpenMapTiles / OpenStreetMap data. No API key is needed.

![Circled POIs and recenter control at simulated Colchester city centre](docs/screenshots/colchester-pois.png)

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

- **Camera menu (hand / location / car icon):** choose Explore, Follow or Drive.
- **Explore:** pan, zoom, rotate and tilt the real map. The initial view is central London, a public demonstration location, not your position.
- **Follow:** request When In Use access and follow a fresh location north-up.
- **Drive:** follow position with a tilted, course-aligned camera. At low speed, an available compass heading is used. This is **not turn-by-turn navigation**.
- **2D / 3D:** switch building extrusion and map tilt. Any map gesture returns the camera to Explore.
- **Circled !:** open POI filters. Enable places, select categories, or use Driving essentials (parking/fuel/charging). Light, Balanced and Detailed control density; Light is the default for busy centres. Gold circled exclamation marks appear from zoom 15; optional place names start at zoom 17. More places qualify as you zoom in. POIs start off and choices last for the current app session. Coverage comes from named OpenStreetMap POIs; these neon-map markers use OpenStreetMap data. Apple place search is available separately through Places.
- **Recenter arrow (bottom right):** return to your current position and Follow. In Drive it retains the driving camera. It remains available with the rail hidden. If a fresh fix is unavailable, GPS details explain the status; permission denial preserves Explore.
- **Search (magnifying glass):** open Places to search Apple Maps by address, postcode or name. Results stay on an embedded Apple map; tap a result or an Apple POI for its native card with available address/contact details, hours, photos and ratings. Search is submitted explicitly, capped at 25 results, and has loading/empty/failure states.
- **Select a spot:** tap a visible gold POI on the neon map, or press and hold anywhere to drop a pin. Its sheet shows the OSM name/category or selected coordinates. Find in Apple Maps opens Places around that spot with a suggested query; choose the matching Apple result rather than assuming both databases identify the same place.
- **Speed badge:** compact MPH display; tap to open/close GPS status, accuracy and permission details.
- **Full-screen map:** swipe left across the rail or GPS details, or tap the bottom chevron. Restore controls with the small sidebar button. POI/camera selections are preserved while hidden and map attribution stays visible.
- **Info:** map credits, privacy details and the scope of later stages.

A compact left-hand icon rail leaves the map visible on regular iPhones and both Duo screen sizes. GPS details open only when requested or when access is denied. Controls and details scroll on shorter screens or with larger text. No model-name checks are used; Reduce Motion is respected.

## GPS and privacy

The app requests **When In Use** location only from Follow/Drive or the recenter button. It never requests Always access, enables background location, saves a location trail or sends analytics. Updates stop when the app is not active. Denied/restricted access leaves map exploration available; denied access provides a Settings link. Reduced accuracy is identified. Stale (>15 seconds), invalid and very poor (>1 km) fixes are not used for camera tracking; unavailable speed stays unknown rather than becoming zero.

Apple Places uses the system MapKit framework without a separate API key. Searches and the displayed map region are sent to Apple when Places is used. Results are kept only in that screen’s memory, with no saved search history or secondary place database. Apple data is displayed with Apple maps and never copied onto the MapLibre map. Apple place-card content varies by place and region; written reviews are not imported into a custom NightDrive database.

Map tiles and glyphs require network access for uncached regions. OpenFreeMap receives your IP address and requested map areas. No bulk/offline download feature is implemented. GPS speed is informational and is not a calibrated vehicle speedometer.

## Architecture

- `App/`: SwiftUI entry point.
- `UI/`: collapsible compact rail, controls and linked attribution.
- `Location/LocationService.swift`: the single Core Location owner and permission/lifecycle state.
- `Map/NightMapView.swift`: UIKit MapLibre bridge, GPS marker and camera synchronization. Gestures release follow mode.
- `Map/POISettings.swift`: category groups and zoom-dependent density filters applied before symbol placement.
- `Map/CameraMode.swift`: camera policy and location-quality rules.
- `Resources/nightdrive.json`: original style bundled with the app; remote vector tiles and fonts only. Regenerate with `python3 scripts/generate_style.py`.
- `Places/`: cancellable MapKit search, Apple map and unmodified native place cards; separate OSM/dropped-spot selection sheet.
- `Navigation/NavigationContracts.swift`: provider-neutral route/maneuver and presentation interfaces for later routing and CarPlay.
- `NightDriveTests/` and `NightDriveUITests/`: meaningful location/camera/style checks and UI regression checks.

See [Apple Places integration](docs/APPLE_PLACES.md) for capabilities and map-data boundaries. See [POI design and performance notes](docs/POI_DESIGN.md) for icon research, filtering and the Colchester sample. See [validation notes](docs/VALIDATION.md) for executed checks and limitations, and [architecture plan](docs/ARCHITECTURE.md) for subsequent stages.

## Signing and future Apple work

**Development signing is configured locally on the owner’s Mac**, using the confirmed Apple Developer team. A signed Debug build has been installed and launched on the connected physical iPhone Duo. Certificates remain in Keychain and profiles in Xcode-managed storage; neither is committed.

A fresh checkout remains unsigned by default. `Config/Signing.xcconfig` optionally includes ignored `Config/Local.xcconfig`. To configure another authorized Mac, copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`, set the confirmed `DEVELOPMENT_TEAM`, and keep the device-only `CODE_SIGNING_ALLOWED[sdk=iphoneos*] = YES` override. The app uses automatic **Apple Development** signing. Select the connected device in Xcode and Run. Simulator builds stay unsigned.

The owner explicitly authorized the development certificates/profiles needed for the initial device installation on 25 October 2026. Confirm authorization before provisioning for a different account or changing account security. Do not commit local signing overrides, credentials, certificates, profiles or device identifiers.

No CarPlay entitlements, approval applications, TestFlight uploads, App Store submissions or Apple review requests have been made. These are separate future actions.

## Credits

- [MapLibre Native](https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/gettingstarted/) — BSD 2-Clause.
- [OpenFreeMap](https://openfreemap.org/quick_start/) — tile and glyph hosting.
- [OpenMapTiles](https://openmaptiles.org/) and [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) — map data/schema; linked attribution remains visible on the map.

This is an independent personal project, not affiliated with CD Projekt Red. Styling and the app icon are original; no game assets, reference screenshots or third-party app code are distributed in this repository. See [third-party notices](THIRD_PARTY_NOTICES.md).
