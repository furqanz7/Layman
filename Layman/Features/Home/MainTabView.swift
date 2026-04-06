import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(LaymanTheme.text(colorScheme))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(LaymanTheme.background(colorScheme))
            appearance.shadowColor = UIColor(LaymanTheme.text(colorScheme).opacity(0.08))

            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(LaymanTheme.text(colorScheme).opacity(0.45))
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(LaymanTheme.text(colorScheme).opacity(0.5))]
            itemAppearance.selected.iconColor = UIColor(LaymanTheme.text(colorScheme))
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(LaymanTheme.text(colorScheme))]
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
