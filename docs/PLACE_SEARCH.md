# Native search and attribution

## Current experience

A navy/cyan search panel overlays the neon MapLibre map. Select a result to focus its gold marker and read its name, category and address in an original compact panel. Closing the panel keeps the marker; tapping it reopens details. GPS recenter clears it. Existing rendered POIs and dropped pins use the same panel, with explicit search by name/area. Search does not enable all POIs or increase their density.

The user chose the free, no-account starting point. Photon by Komoot supplies OSM-based address/place search. A live public Colchester Castle request returned its correct museum category, street, postcode, city and coordinates. It does not supply a dependable contact/review directory. Missing data is not fabricated. No Apple Maps SDK views or search requests remain.

## Provider boundaries

- Explicit search only; no autocomplete, pan-triggered requests, bulk queries or background search.
- Eight results maximum; invalid/out-of-range coordinates rejected and OSM identities deduplicated.
- Two-second minimum request interval across search panels; HTTP 429 adds a 30-second minimum cooldown (Retry-After seconds honoured up to one hour, default one minute).
- Ephemeral networking, bounded timeout, cancellation and late-response rejection. Closing a panel cancels work. No query logging, saved history or persistent results cache.
- The query, user-viewed map centre and IP address reach Photon/Komoot. Location permission is not required to search. No separate GPS stream is sent.
- OSM listing URLs are constructed only from a known object type and positive ID; response data cannot introduce arbitrary link schemes.
- Community service availability is not guaranteed. Use a dedicated/self-hosted service before significant public traffic; endpoint changes belong in PhotonPlaceSearch. No paid account or key has been created.

## Attribution

The linked provider strip is placed at the map's bottom-left corner, clear of the right-hand recenter control, and remains when the rail is hidden. Search also credits Photon and OpenStreetMap. Font size/contrast is retained; this change moves credits rather than hiding or removing them. The user has not requested removal.

## Sources checked 25 October 2026

- [Photon README and public service policy](https://github.com/komoot/photon): reasonable use, throttling/blocking and no availability guarantee.
- [Photon API documentation](https://github.com/komoot/photon/blob/master/docs/api-v1.md): query, location bias, limits and GeoJSON results.
- [OSMF attribution guidance](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines): readable attribution in any corner, licensing link and geocoder credit. It also permits conditional collapse with discoverable licence information; the current UI deliberately retains a visible strip.
- [OpenFreeMap quick start](https://openfreemap.org/quick_start/): provider attribution and MapLibre mobile integration.

Geoapify was considered for richer OSM details but requires an API account. The owner chose the free starting point. Routing, richer contact data, reviews and CarPlay remain separate future work.
