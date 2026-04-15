import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("peace.userName") private var storedUserName = ""
    @ObservedObject private var moodStore = MoodJournalStore.shared
    @State private var showPremiumSheet = false

    private var recentCheckinsCount: Int {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return moodStore.entries.filter { $0.date >= cutoff }.count
    }

    private var displayName: String {
        let trimmed = storedUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? t.you : trimmed
    }

    private var planLabel: String {
        premiumStore.hasPremiumAccess ? t.premiumTitle : t.basicPlan
    }

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                GeometryReader { proxy in
                    let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                            if layout.prefersSplitLayout {
                                HStack(alignment: .top, spacing: layout.sectionSpacing) {
                                    profileHeader(layout: layout)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)

                                    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                        LazyVGrid(columns: [GridItem(.flexible(), spacing: MMSpacing.md), GridItem(.flexible(), spacing: MMSpacing.md)], spacing: MMSpacing.md) {
                                            StatCard(value: "\(moodStore.entries.count)", label: t.savedCheckins, color: .mmAccent, isPadLayout: true)
                                            StatCard(value: "\(recentCheckinsCount)", label: t.checkinsLast7Days, color: .mmAccent3, isPadLayout: true)
                                        }

                                        MMPrimaryButton(
                                            title: premiumStore.hasPremiumAccess ? t.premiumActive : t.discoverPremium,
                                            icon: premiumStore.hasPremiumAccess ? "checkmark.circle.fill" : "sparkles",
                                            gradient: .mmRoseGradient,
                                            glowColor: .mmRose
                                        ) {
                                            showPremiumSheet = true
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                            } else {
                                profileHeader(layout: layout)

                                HStack(spacing: MMSpacing.md) {
                                    StatCard(value: "\(moodStore.entries.count)", label: t.savedCheckins, color: .mmAccent, isPadLayout: layout.isPad)
                                    StatCard(value: "\(recentCheckinsCount)", label: t.checkinsLast7Days, color: .mmAccent3, isPadLayout: layout.isPad)
                                }

                                MMPrimaryButton(
                                    title: premiumStore.hasPremiumAccess ? t.premiumActive : t.discoverPremium,
                                    icon: premiumStore.hasPremiumAccess ? "checkmark.circle.fill" : "sparkles",
                                    gradient: .mmRoseGradient,
                                    glowColor: .mmRose
                                ) {
                                    showPremiumSheet = true
                                }
                            }
                        }
                        .frame(maxWidth: layout.screenContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 40)
                    }
                    .safeAreaPadding(.horizontal, layout.horizontalPadding)
                    .safeAreaPadding(.bottom, MMSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MMNavigationBarTitle(text: t.profileTitle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(t.close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
        }
    }

    private func profileHeader(layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.9)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                HStack(spacing: MMSpacing.md) {
                    Circle()
                        .fill(LinearGradient.mmAccentGradient)
                        .frame(width: layout.isPad ? 82 : 72, height: layout.isPad ? 82 : 72)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: layout.isPad ? 32 : 28, weight: .medium))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayName)
                            .font(MMFont.display(layout.isPad ? 32 : 28, weight: .bold))
                            .foregroundStyle(.mmTextPrimary)

                        Text(planLabel)
                            .font(MMFont.body(layout.isPad ? 15 : 14))
                            .foregroundStyle(.mmTextMuted)
                    }

                    Spacer()
                }

                Text(t.profileSummary)
                    .font(MMFont.body(layout.isPad ? 15 : 14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
