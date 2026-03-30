import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var languageStore: AppLanguageStore

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(t.tabHome, systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            EmotionTrackerView()
                .tabItem {
                    Label(t.tabMood, systemImage: selectedTab == 1 ? "heart.fill" : "heart")
                }
                .tag(1)

            AIInsightsView()
                .tabItem {
                    Label(t.tabInsights, systemImage: selectedTab == 2 ? "quote.bubble.fill" : "quote.bubble")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label(t.tabSettings, systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
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
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
