# Routing and guidance

NightDrive 0.2 adds driving routes from a selected search result, map POI or dropped pin. Directions opens an explicit origin choice: current precise GPS or a chosen map centre. The latter is planning only until the device has a fresh fix within 100 m of the route's road start. Preview the mint route, distance, estimated travel time and turns, then start guidance. Recenter resumes the driving camera; Overview releases it. End immediately cancels requests and clears the route.

## Provider and data boundaries

The provider is the [FOSSGIS OSRM car service](https://routing.openstreetmap.de/about.html), endpoint `https://routing.openstreetmap.de/routed-car/route/v1/driving/`. It supplies real OSM-based geometry, durations and maneuvers. English instructions are formatted locally from those maneuvers. Routes can terminate on a nearby road; this is not door-to-door or pedestrian-access guidance. The 100 m road snapping radius limits unexpected distant road matches. No traffic, road-closure feed, alternative routes, toll avoidance or offline routing is claimed.

The [demo-service policy](https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server) permits reasonable non-commercial usage, at most one request per second, with no availability/data freshness guarantee. This private personal beta spaces explicit requests by at least two seconds and respects a cooldown on rate limiting. No background searches, continuous server map matching or automatic reroute loop runs. Use appropriately provisioned hosted/self-hosted routing before wider/commercial distribution. Required OSM, OSRM/FOSSGIS attribution and Fix the map link are present in the route interface.

Only explicit Route/Recalculate actions send origin and destination coordinates to FOSSGIS, which logs requests. Requests use HTTPS and an identifying User-Agent, ephemeral sessions, no cookies/cache and bounded timeouts. Responses are checked for geometry, coordinates, step consistency and sensible sizes. Queries, GPS history and route history are not stored by NightDrive. The app needs connectivity to obtain or recalculate a route.

## Local navigation

NavigationSession owns cancelable route requests, preview, guidance, arrival and error states. A generation token excludes superseded responses. RouteGeometry caches cumulative distances and projects accepted fixes onto a bounded portion of the polyline. A local forward window avoids jumping to far-away sections at route crossings; short backward movement is allowed. This is a conservative first implementation, not production-grade probabilistic map matching.

Guidance requires a fix no older than 15 seconds and horizontal accuracy at most 50 m. Poor or stale fixes pause instructions. Sustained divergence (at least six seconds beyond an accuracy-adjusted distance) holds progress and offers an explicit reroute. Long gaps, backtracking or ambiguous intersections can require recalculation. Arrival requires both little remaining route distance and physical proximity to the road endpoint.

Voice cues announce upcoming maneuvers once per distance band, can be muted and stop on cancellation or a location pause. Playback uses the voicePrompt category mode with audio ducking; activation/deactivation runs on a serial queue and releases the audio session between utterances. Live voice/audio interruption and extended road behavior still require physical acceptance.

## Shared phone and CarPlay architecture

NavigationRuntime owns one LocationService and NavigationSession for all presenters. The phone and compiled CarPlay adapter consume the same route and progress, so destination changes/cancellation are shared. CarPlay uses native templates and a map-only rendering view; MapKit is used only to construct local CPTrip endpoints, with no Apple search/directions request.

CarPlay registration, its navigation entitlement and location background mode are **not active in the ordinary phone build**. See [CarPlay setup](CARPLAY.md). Phone-only guidance pauses when NightDrive is not active. An approved CarPlay configuration enables background location only while connected and actively navigating; it does not request Always location permission.

## Acceptance limits

Simulated public coordinates and deterministic geometry/response fixtures can validate behavior but do not establish road safety, GPS quality, parallel-road matching or CarPlay hardware compatibility. iOS 26 runtime, physical vehicle audio, disconnect/reconnect, locked-phone navigation and CarPlay display acceptance remain separate checks. Apple entitlement approval is required before CarPlay activation; the app does not bypass that requirement.
