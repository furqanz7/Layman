import SwiftUI

@main
struct LaymanApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
