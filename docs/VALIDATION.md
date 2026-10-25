# Validation

Validation is in progress on 2026-10-25. The simulator application builds with Xcode 27.1, MapLibre 6.31.0 and the iOS 26 deployment target. Seven unit tests passed in the initial run. A UI test exposed a sheet-dismissal timing issue; the assertion now waits for the control to become hittable. Final results will replace this note after rerunning the updated app.

No real device, Apple signing, CarPlay, TestFlight or App Store validation has been performed.
