# Third-party notices

## MapLibre Native

NightDrive links MapLibre Native 6.31.0 via the official Swift Package Manager distribution. It is licensed under the BSD 2-Clause license. The framework's upstream license and bundled third-party notices apply.

- https://github.com/maplibre/maplibre-native/blob/ios-v6.31.0/LICENSE.md
- https://github.com/maplibre/maplibre-gl-native-distribution

## Map data and fonts

Map data is served by OpenFreeMap using OpenMapTiles and OpenStreetMap contributors' data. OpenStreetMap is licensed under the Open Data Commons Open Database License (ODbL). Preserve the visible linked attribution and the source attribution in the bundled style.

- https://openfreemap.org/
- https://openmaptiles.org/
- https://www.openstreetmap.org/copyright

Noto Sans glyphs are fetched from OpenFreeMap and are subject to the Noto fonts' SIL Open Font License. No glyph/font binaries or map tiles are redistributed in this repository.

NightDrive's custom style and app icon are original. The screenshots supplied by the user were viewed as visual references only and are not included.

## Place search

Photon by Komoot provides the public OpenStreetMap-based geocoding service. Search data is credited to OpenStreetMap with its ODbL link; Photon is credited in the search panel. No Photon server code is bundled. The public service permits reasonable project use, may throttle/block excessive requests and has no availability guarantee.

- https://github.com/komoot/photon
- https://www.openstreetmap.org/copyright

The previous Apple Maps integration has been removed. Its implementation notes and screenshots remain only as historical milestone evidence.

## OSRM / FOSSGIS routing

Driving routes use the [FOSSGIS public OSRM service](https://routing.openstreetmap.de/about.html), based on OpenStreetMap. No OSRM server software is bundled. This endpoint is limited to reasonable non-commercial use, no more than one request per second, and has no availability guarantee. NightDrive spaces explicit requests by at least two seconds and does not automatically reroute or upload GPS traces. Start/destination requests are logged by the provider. Attribution and a Fix the map link are shown in the route UI. Broader distribution requires appropriate service capacity and terms.
