import SwiftUI

@main
struct MindMeshApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
