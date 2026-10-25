# Apple Places integration

## Scope

Native MapKit is supplied by iOS; no web key, server, credential or new certificate is needed. NightDrive uses MKLocalSearch for submitted addresses/postcodes/place names, MKMapView for Apple results and tappable built-in POIs, MKMapItemRequest for feature details, and MKMapItemDetailViewController for native place cards.

The Apple map remains visible alongside search results, and the native card displays its own inline map. Apple's map attribution/legal links and card layout remain intact. Available cards may include phone, address, website, hours, photos and ratings. The app does not invent missing values or scrape/extract written reviews. The SDK's map item exposes address/contact fields, not a general raw reviews feed.

The neon map keeps its original OpenFreeMap/OpenStreetMap markers. Tapping a rendered gold marker shows its supplied name/category; long press creates a dropped spot. A user can explicitly open Places around that spot and search for a matching Apple result. Matching is not assumed or silently merged.

## Data and request boundaries

- Search is user-submitted, not a request on every pan or GPS update.
- At most 25 search results/annotations are retained on the Apple map.
- Starting another search cancels prior work; generation checks discard late responses.
- Closing Places cancels search, releases its transient state and tears down feature requests.
- Loading, no-results, empty-input and connection-failure states are visible.
- Apple results are never fed to MapLibre, saved as favourites/history, exported or used to build a secondary database.
- Opening Places requests the viewed map area from Apple. Submitting search sends its query and geographic hint. It does not start a second GPS manager or require location permission merely to search.
- Native card actions are operated by the user. Validation does not place phone calls, submit ratings or start external directions.

## Source basis — checked 25 October 2026

- [Apple Developer Program License Agreement, Attachment 6](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/), especially 2.4: Apple map data must be accompanied by the corresponding Apple map, and map plotting is limited to Apple maps. This is why the app uses a separate integrated Places surface instead of adding Apple POIs to the neon base map.
- [MKLocalSearch](https://developer.apple.com/documentation/mapkit/mklocalsearch) and [result types](https://developer.apple.com/documentation/mapkit/mklocalsearch/resulttype): place/address queries.
- [MKMapItemDetailViewController](https://developer.apple.com/documentation/mapkit/mkmapitemdetailviewcontroller): native place detail presentation; not subclassed or restyled internally.
- [Apple Maps interface guidelines](https://developer.apple.com/design/human-interface-guidelines/maps): place-card information and platform presentation.

The installed Xcode 27.1 SDK headers were also checked. iOS 26 MKMapItem.location/address APIs are used instead of deprecated placemark access. The app still targets iOS 26+.

## Remaining scope

This milestone adds discovery and place inspection. Route calculation, turn-by-turn guidance, saved journeys and CarPlay remain future work. No physical-device test/install, provisioning, distribution or Apple approval action is part of this milestone.
