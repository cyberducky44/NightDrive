import SwiftUI

@main
struct NightDriveApp: App {
    var body: some Scene {
        WindowGroup {
            DriveScreen()
                .preferredColorScheme(.dark)
                .tint(NightTheme.cyan)
        }
    }
}
