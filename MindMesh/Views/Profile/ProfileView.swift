import SwiftUI
import WebKit

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
                        .frame(maxWidth: layout.formContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity)

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
                    .safeAreaPadding(.horizontal, layout.horizontalPadding)
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

struct PremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    private var features: [(String, String, String)] {
        [
            ("sparkles", t.premiumFeatureInsightsTitle, t.premiumFeatureInsightsBody),
            ("bubble.left.and.bubble.right", t.premiumFeatureChatTitle, t.premiumFeatureChatBody),
            ("clock.arrow.trianglehead.counterclockwise.rotate.90", t.premiumFeatureHistoryTitle, t.premiumFeatureHistoryBody),
            ("icloud", t.premiumFeatureSyncTitle, t.premiumFeatureSyncBody)
        ]
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            GeometryReader { proxy in
                let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MMSpacing.xxxl) {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.mmAccent.opacity(0.12))
                                .frame(width: layout.isPad ? 88 : 76, height: layout.isPad ? 88 : 76)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: layout.isPad ? 34 : 30, weight: .semibold))
                                        .foregroundStyle(.mmAccent)
                                )

                            Text(t.premiumTitle)
                                .font(MMFont.display(layout.isPad ? 34 : 30, weight: .bold))
                                .foregroundStyle(.mmTextPrimary)

                            Text(t.premiumHeroSubtitle)
                                .font(MMFont.body(layout.isPad ? 16 : 15))
                                .foregroundStyle(.mmTextMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, MMSpacing.md)
                        }
                        .padding(.top, MMSpacing.xxxl)

                        storeKitStateCard(layout: layout)

                        MMCard(padding: layout.cardPadding) {
                            VStack(spacing: MMSpacing.lg) {
                                ForEach(features, id: \.0) { icon, title, subtitle in
                                    HStack(alignment: .top, spacing: 14) {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.mmSurface)
                                            .frame(width: layout.isPad ? 48 : 42, height: layout.isPad ? 48 : 42)
                                            .overlay(
                                                Image(systemName: icon)
                                                    .font(.system(size: layout.isPad ? 18 : 16, weight: .semibold))
                                                    .foregroundStyle(.mmAccent)
                                            )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(title)
                                                .font(MMFont.title(layout.isPad ? 16 : 15, weight: .semibold))
                                                .foregroundStyle(.mmTextPrimary)

                                            Text(subtitle)
                                                .font(MMFont.body(layout.isPad ? 14 : 13))
                                                .foregroundStyle(.mmTextMuted)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }

                        if let purchaseNotice = premiumStore.purchaseNotice {
                            MMCard(
                                padding: MMSpacing.md,
                                cornerRadius: MMRadius.md,
                                borderColor: Color.mmAccent3.opacity(0.18),
                                backgroundColor: Color.mmAccent3.opacity(0.10)
                            ) {
                                Text(purchaseNotice)
                                    .font(MMFont.body(layout.isPad ? 14 : 13))
                                    .foregroundStyle(.mmTextPrimary)
                            }
                        }

                        if let purchaseError = premiumStore.purchaseError {
                            MMCard(
                                padding: MMSpacing.md,
                                cornerRadius: MMRadius.md,
                                borderColor: Color.mmRose.opacity(0.18),
                                backgroundColor: Color.mmRose.opacity(0.08)
                            ) {
                                Text(purchaseError)
                                    .font(MMFont.body(layout.isPad ? 14 : 13))
                                    .foregroundStyle(.mmTextPrimary)
                            }
                        }

                        Text(premiumStore.storeStatusText)
                            .font(MMFont.body(layout.isPad ? 14 : 13))
                            .foregroundStyle(.mmTextMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        VStack(spacing: 12) {
                            MMPrimaryButton(
                                title: premiumStore.purchaseButtonTitle,
                                icon: premiumStore.purchaseButtonIcon,
                                gradient: LinearGradient.mmAccentGradient,
                                glowColor: .mmAccent
                            ) {
                                Task {
                                    await premiumStore.purchasePremium()
                                    if premiumStore.hasPremiumAccess {
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(premiumStore.hasPremiumAccess || premiumStore.isPurchasing || premiumStore.isLoadingProducts)
                            .opacity((premiumStore.hasPremiumAccess || premiumStore.isPurchasing) ? 0.7 : 1)

                            MMSecondaryButton(title: t.restorePurchases, icon: "arrow.clockwise.circle", tint: .mmAccent3) {
                                Task {
                                    await premiumStore.restorePurchases()
                                    if premiumStore.hasPremiumAccess {
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(premiumStore.isRestoring)
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: layout.modalContentWidth, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, layout.horizontalPadding)
                }
            }
        }
        .task {
            await premiumStore.prepare(force: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await premiumStore.prepare(force: true)
            }
        }
    }

    @ViewBuilder
    private func storeKitStateCard(layout: MMLayoutMetrics) -> some View {
        if let productName = premiumStore.premiumProductName,
           let productPrice = premiumStore.premiumProductPrice {
            MMCard(
                padding: layout.cardPadding,
                cornerRadius: MMRadius.md,
                borderColor: Color.mmAccent.opacity(0.16),
                backgroundColor: Color.mmAccent.opacity(0.08)
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(t.storeOfferReadyTitle)
                        .font(MMFont.caption(11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(.mmAccent)

                    Text(productName)
                        .font(MMFont.title(layout.isPad ? 20 : 18, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    HStack {
                        MMTag(text: productPrice, color: .mmAccent)
                        Spacer(minLength: 0)
                    }

                    Text(t.storeOfferReadyBody(name: productName, price: productPrice))
                        .font(MMFont.body(layout.isPad ? 14 : 13))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(3)
                }
            }
        } else {
            MMCard(
                padding: layout.cardPadding,
                cornerRadius: MMRadius.md,
                borderColor: Color.mmAmber.opacity(0.18),
                backgroundColor: Color.mmAmber.opacity(0.08)
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(t.storeOfferMissingTitle)
                        .font(MMFont.title(layout.isPad ? 18 : 17, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(t.storeOfferMissingBody)
                        .font(MMFont.body(layout.isPad ? 14 : 13))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(3)

                    MMSecondaryButton(
                        title: t.refreshShop,
                        icon: "arrow.clockwise",
                        tint: .mmAccent
                    ) {
                        Task {
                            await premiumStore.prepare(force: true)
                        }
                    }
                    .disabled(premiumStore.isLoadingProducts)
                    .opacity(premiumStore.isLoadingProducts ? 0.7 : 1)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @EnvironmentObject private var languageStore: AppLanguageStore

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            if let fileURL = Bundle.main.url(forResource: "privacy", withExtension: "html") {
                PrivacyPolicyWebView(fileURL: fileURL)
                    .clipShape(RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: MMRadius.lg, style: .continuous)
                            .strokeBorder(Color.mmBorder, lineWidth: 1)
                    )
                    .frame(maxWidth: 920)
                    .frame(maxWidth: .infinity)
                    .safeAreaPadding(.horizontal, MMSpacing.lg)
                    .safeAreaPadding(.vertical, MMSpacing.md)
            } else {
                ScrollView(showsIndicators: false) {
                    MMCard {
                        Text(t.privacyPolicyMissing)
                            .font(MMFont.body(15))
                            .foregroundStyle(.mmTextPrimary)
                    }
                    .padding(.horizontal, MMSpacing.lg)
                    .padding(.top, MMSpacing.lg)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                MMNavigationBarTitle(text: t.privacyPolicyTitle)
            }
        }
    }
}

private struct PrivacyPolicyWebView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != fileURL else { return }
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .previewDisplayName("Impostazioni")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
                .environmentObject(AppLanguageStore(initialLanguage: .italian))

            ProfileView()
                .previewDisplayName("Profilo")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))
                .environmentObject(AppLanguageStore(initialLanguage: .italian))

            PremiumSheet()
                .previewDisplayName("Premium")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
                .environmentObject(AppLanguageStore(initialLanguage: .italian))
        }
    }
}
