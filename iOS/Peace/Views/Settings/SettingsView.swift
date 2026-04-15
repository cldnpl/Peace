import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("darkModeEnabled") private var darkModeOn = false
    @AppStorage("peace.userName") private var storedUserName = ""
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var reminderStore = ReminderStore.shared
    @State private var showPremiumSheet = false
    @State private var showProfile = false

    private let version = "1.0.0"

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                GeometryReader { proxy in
                    let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                    VStack(spacing: 0) {
                        MMNavigationHeaderBlock(
                            text: t.settingsTitle,
                            topPadding: layout.headerTopPadding,
                            bottomPadding: layout.isPad ? MMSpacing.xl : MMSpacing.md
                        )
                        .padding(.horizontal, layout.horizontalPadding)

                        List {
                            Section(t.settingsAppSection) {
                                Toggle(t.darkTheme, isOn: $darkModeOn)
                                    .tint(.mmAccent)

                                Toggle(t.dailyReminder, isOn: Binding(
                                    get: { reminderStore.isEnabled },
                                    set: { reminderStore.setEnabled($0) }
                                ))
                                .tint(.mmAccent)

                                if reminderStore.isEnabled {
                                    DatePicker(
                                        t.reminderTime,
                                        selection: Binding(
                                            get: { reminderStore.reminderTime },
                                            set: { reminderStore.updateReminderTime($0) }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                }

                                Button {
                                    showPremiumSheet = true
                                } label: {
                                    Label(
                                        premiumStore.hasPremiumAccess ? t.managePremium : t.premiumTitle,
                                        systemImage: premiumStore.hasPremiumAccess ? "checkmark.circle.fill" : "sparkles"
                                    )
                                }
                                .foregroundStyle(.mmTextPrimary)
                            }

                            Section(t.settingsLanguageSection) {
                                Picker(t.settingsAppLanguage, selection: $languageStore.selectedLanguage) {
                                    ForEach(AppLanguage.allCases) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                            }

                            Section(t.settingsLegalSection) {
                                NavigationLink {
                                    PrivacyPolicyView()
                                } label: {
                                    Label(t.privacyPolicyTitle, systemImage: "hand.raised.fill")
                                }

                                Link(destination: AppLegalLinks.termsOfUseURL) {
                                    Label(t.termsOfUseTitle, systemImage: "doc.text.fill")
                                }
                                .foregroundStyle(.mmTextPrimary)
                            }

                            Section(t.infoSection) {
                                LabeledContent(t.versionLabel, value: version)
                            }

                            Section {
                                Button(t.signOut, role: .destructive) {
                                    storedUserName = ""
                                    hasSeenOnboarding = false
                                }
                            }
                        }
                        .frame(maxWidth: layout.formContentWidth)
                        .frame(maxWidth: .infinity)
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                reminderStore.refreshAuthorizationStatus()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.mmAccent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t.openProfile)
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
