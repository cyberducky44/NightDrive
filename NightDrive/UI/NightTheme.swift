import SwiftUI

enum NightTheme {
    static let navy = Color(red: 0.025, green: 0.043, blue: 0.11)
    static let panel = Color(red: 0.035, green: 0.07, blue: 0.14)
    static let cyan = Color(red: 0.32, green: 0.86, blue: 0.93)
    static let red = Color(red: 0.98, green: 0.21, blue: 0.35)
    static let muted = Color(red: 0.58, green: 0.69, blue: 0.77)
}

struct HUDPanel: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16)
            .background(NightTheme.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(NightTheme.cyan.opacity(0.22), lineWidth: 1))
    }
}
