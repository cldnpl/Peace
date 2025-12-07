import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            EmotionTrackerView()
                .tabItem {
                    Label("Umore", systemImage: selectedTab == 1 ? "heart.fill" : "heart")
                }
                .tag(1)

            AIInsightsView()
                .tabItem {
                    Label("Riflessioni", systemImage: selectedTab == 2 ? "quote.bubble.fill" : "quote.bubble")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .tint(.mmAccent2)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
