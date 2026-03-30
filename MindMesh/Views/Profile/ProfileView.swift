import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("darkModeEnabled") private var darkModeOn = false
    @AppStorage("peace.userName") private var storedUserName = ""
    @EnvironmentObject private var premiumStore: PremiumStore
    @ObservedObject private var reminderStore = ReminderStore.shared
    @State private var showPremiumSheet = false
    @State private var showProfile = false

    private let version = "1.0.0"

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                List {
                    Section("App") {
                        Toggle("Tema scuro", isOn: $darkModeOn)
                            .tint(.mmAccent)

                        Toggle("Promemoria giornaliero", isOn: Binding(
                            get: { reminderStore.isEnabled },
                            set: { reminderStore.setEnabled($0) }
                        ))
                            .tint(.mmAccent)

                        if reminderStore.isEnabled {
                            DatePicker(
                                "Orario",
                                selection: Binding(
                                    get: { reminderStore.reminderTime },
                                    set: { reminderStore.updateReminderTime($0) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }

                        Text(reminderStore.statusText)
                            .font(MMFont.body(13))
                            .foregroundStyle(.mmTextMuted)

                        Button {
                            showPremiumSheet = true
                        } label: {
                            Label(
                                premiumStore.hasPremiumAccess ? "Gestisci Peace Premium" : "Peace Premium",
                                systemImage: premiumStore.hasPremiumAccess ? "checkmark.circle.fill" : "sparkles"
                            )
                        }
                        .foregroundStyle(.mmTextPrimary)
                    }

                    Section("Info") {
                        LabeledContent("Versione", value: version)

                    }

                    Section {
                        Button("Esci dal profilo", role: .destructive) {
                            storedUserName = ""
                            hasSeenOnboarding = false
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.large)
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
                    .accessibilityLabel("Apri profilo")
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
    @EnvironmentObject private var premiumStore: PremiumStore
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
        return trimmed.isEmpty ? "Tu" : trimmed
    }

    private var planLabel: String {
        premiumStore.hasPremiumAccess ? "Peace Premium" : "Piano base"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
                        profileHeader

                        HStack(spacing: MMSpacing.md) {
                            StatCard(value: "\(moodStore.entries.count)", label: "Check-in salvati", color: .mmAccent)
                            StatCard(value: "\(recentCheckinsCount)", label: "Check-in ultimi 7 giorni", color: .mmAccent3)
                        }

                        MMPrimaryButton(
                            title: premiumStore.hasPremiumAccess ? "Premium attivo" : "Scopri Premium",
                            icon: premiumStore.hasPremiumAccess ? "checkmark.circle.fill" : "sparkles",
                            gradient: .mmRoseGradient,
                            glowColor: .mmRose
                        ) {
                            showPremiumSheet = true
                        }
                    }
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
        }
    }

    private var profileHeader: some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.9)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                HStack(spacing: MMSpacing.md) {
                    Circle()
                        .fill(LinearGradient.mmAccentGradient)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayName)
                            .font(MMFont.display(28, weight: .bold))
                            .foregroundStyle(.mmTextPrimary)

                        Text(planLabel)
                            .font(MMFont.body(14))
                            .foregroundStyle(.mmTextMuted)
                    }

                    Spacer()
                }

                Text("Qui trovi il tuo spazio personale, con un riepilogo semplice di quello che stai usando davvero.")
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }
}

struct PremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premiumStore: PremiumStore

    private let features = [
        ("sparkles", "Riflessioni più profonde", "Spunti meno generici e più mirati."),
        ("bubble.left.and.bubble.right", "Chat emotiva guidata", "Uno spazio premium per elaborare i momenti piu difficili."),
        ("clock.arrow.trianglehead.counterclockwise.rotate.90", "Cronologia chat recenti", "Riprendi le conversazioni premium senza perderne il filo."),
        ("icloud", "Sync tra dispositivi", "Apri il tuo spazio ovunque, senza ricominciare.")
    ]

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MMSpacing.xxxl) {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.mmAccent.opacity(0.12))
                            .frame(width: 76, height: 76)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.mmAccent)
                            )

                        Text("Peace Premium")
                            .font(MMFont.display(30, weight: .bold))
                            .foregroundStyle(.mmTextPrimary)

                        Text("Per chi vuole più continuità e più profondità, senza complicare il resto.")
                            .font(MMFont.body(15))
                            .foregroundStyle(.mmTextMuted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, MMSpacing.md)
                    }
                    .padding(.top, MMSpacing.xxxl)

                    MMCard {
                        VStack(spacing: MMSpacing.lg) {
                            ForEach(features, id: \.0) { icon, title, subtitle in
                                HStack(alignment: .top, spacing: 14) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.mmSurface)
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.mmAccent)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(MMFont.title(15, weight: .semibold))
                                            .foregroundStyle(.mmTextPrimary)

                                        Text(subtitle)
                                            .font(MMFont.body(13))
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
                                .font(MMFont.body(13))
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
                                .font(MMFont.body(13))
                                .foregroundStyle(.mmTextPrimary)
                        }
                    }

                    Text(premiumStore.storeStatusText)
                        .font(MMFont.body(13))
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

                        MMSecondaryButton(title: "Ripristina acquisti", icon: "arrow.clockwise.circle", tint: .mmAccent3) {
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
                .padding(.horizontal, MMSpacing.xl)
            }
        }
        .task {
            await premiumStore.prepare()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .previewDisplayName("Impostazioni")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))

            ProfileView()
                .previewDisplayName("Profilo")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))

            PremiumSheet()
                .previewDisplayName("Premium")
                .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: false))
        }
    }
}
