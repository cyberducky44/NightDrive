# POI design and city-centre density

## Reference research — 25 October 2026

Cyberpunk 2077 uses different symbols for different map activities. The outlined yellow circle with an exclamation mark is its **side-job** marker; main jobs use a filled yellow circle with a dark exclamation mark. Shops and services use their own category symbols. The [visual icon reference](https://cyberpunkcentral.com/cyberpunk-2077-map-icons/) was inspected directly. NightDrive uses original ring/stem/dot geometry inspired by the outlined marker for its real-world POIs; it does not copy game artwork or imply that real places are missions.

CD Projekt Red's [official patch 1.5 notes](https://www.cyberpunk.net/en/news/41435/patch-1-5-next-generation-update-list-of-changes) describe both a zoom-dependent Dynamic map filter and a user-configurable Custom filter. NightDrive similarly combines category choices with zoom-dependent density.

## Implementation

The existing vector source supplies one POI symbol layer. [OpenMapTiles' POI schema](https://github.com/openmaptiles/openmaptiles/blob/master/layers/poi/poi.yaml) defines category classes and ascending local-importance rank. Native MapLibre predicates filter named features by selected classes and maximum rank **before symbol placement**. No per-place SwiftUI views, annotation collection or additional tile source is created.

| Detail | Zoom 15–16 | Zoom 17 | Zoom 18–19 |
|---|---:|---:|---:|
| Light | rank ≤2 | ≤4 | ≤8 |
| Balanced | ≤5 | ≤12 | ≤24 |
| Detailed | ≤10 | ≤30 | ≤60 |

Icons appear from zoom 15, with collision avoidance and padding. Place names are optional, off by default, and start at zoom 17. POIs initially remain off. Categories default to parking, fuel/charging, food/drink and sights/leisure. Driving essentials selects parking and fuel/charging. Settings are retained while hiding the rail, but reset at a fresh app launch.

Style properties are reapplied only when a setting or rank bucket changes, rather than on every GPS/timer refresh. GPS annotation coordinates only change for a new fix; compass changes only move the driving camera.

## Colchester sample

Decoded the public city-centre tile `14/8233/5420` from the OpenFreeMap `20261018_080001_pt` dataset on 25 October 2026. At display zoom 16:

| Selection | Candidate named POIs before collision placement |
|---|---:|
| Previous unbounded layer | 922 |
| Light, all categories | 71 |
| Balanced, all categories | 164 |
| Detailed, all categories | 273 |
| Light, Driving essentials | 1 |

Light/all removes approximately **92%** of the old candidate workload in this sample. These are decoded feature counts for **one tile**, not rendered-marker totals, whole-city coverage or an FPS benchmark. Rank is local importance across categories: restrictive categories plus Light can be sparse, so users can increase detail or zoom in.

The filters reduce symbol layout/drawing work; they do not reduce vector downloads/decoding or the cost of 3D buildings. The existing 2D button offers a lighter building view. Long-duration device frame-rate, battery and thermal performance still require real-use validation.

## Recenter

The independent location arrow remains visible with the rail hidden. It requests When In Use access if needed, recentres on a fresh fix, and resumes north-up Follow (or retains Drive if already selected). Repeated taps work even without a new fix. A pending fix is followed when it arrives; denied access leaves Explore available and reveals GPS details. Map gestures release Follow/Drive as before.
