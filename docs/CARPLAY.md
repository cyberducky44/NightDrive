# CarPlay navigation integration

The owner requested CarPlay integration and a navigation entitlement application on 25 October 2026. This supersedes the original prohibition on applying for CarPlay. It does not authorize unrelated App Store submissions.

## Prepared implementation

`CarPlaySceneDelegate` compiles against the installed Apple SDK. It uses CPMapTemplate, CPTrip previews, CPSearchTemplate/list results, CPNavigationSession maneuvers and estimates, route cancellation, reroute, panning, overview, recenter and voice mute. The same NavigationRuntime used on the phone owns GPS and routing. All CarPlay interaction uses Apple templates. The map view renders the neon map, route, GPS position and source attribution. There is no dashboard, instrument cluster, vehicle route-sharing or lane guidance claim.

The current app has **no active CarPlay entitlement or scene registration**. The adapter is staged for approval; compilation alone does not prove CarPlay runtime operation. Do not forge entitlements or override simulator entitlement enforcement.

## Activation after Apple approval

1. Verify approval for this app's `com.apple.developer.carplay-maps` entitlement in the confirmed developer account.
2. Enable CarPlay Navigation on the existing app identifier, with owner authorization for any new signing profile required.
3. Copy `Config/CarPlay.xcconfig.example` to ignored `Config/CarPlay.xcconfig`. Shared signing configuration includes it optionally. This activates the separate scene manifest, entitlement file and location background mode. Do not make this file active before approval.
4. Build/sign with the matching approved profile, inspect the built Info.plist and entitlements, and run the CarPlay simulator. Test launch without a phone UI scene, search, trip preview, directions, voice, mute, end, system cancellation, poor GPS, rerouting, background/locked-phone behavior, and reconnect/disconnect.
5. Test actual supported CarPlay hardware before claiming vehicle acceptance or distributing a CarPlay-enabled build. Retain honest limitations for beta testers.

Reference: [Apple entitlement process](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements), [scene integration](https://developer.apple.com/documentation/carplay/displaying-content-in-carplay), [current developer guide](https://developer.apple.com/carplay/documentation/CarPlay-App-Programming-Guide.pdf).

## Entitlement request

The Apple form requires a description, intended CarPlay features, three JPG navigation screenshots and agreement to the CarPlay Entitlement Addendum. The optional public App Store URL is blank because this app currently has only private internal TestFlight distribution. Application evidence uses public Colchester simulator locations. No account credentials, personal device locations or tester records belong in the repository.

Status: **submitted on 25 October 2026** after the owner explicitly approved acceptance of the CarPlay Entitlement Addendum. Apple's page confirmed “Thank you for your submission” and said it will review the request and contact the developer with a status update. **Approval is pending.** No entitlement or provisioning changes have been applied.

Submitted simulator evidence: [route overview](screenshots/nightdrive-routing-overview.jpg), [maneuver list](screenshots/nightdrive-routing-turns.jpg), [active guidance](screenshots/nightdrive-routing-guidance.jpg). These are genuine app screenshots using public Colchester coordinates; no simulated CarPlay screen was presented as a completed integration.
