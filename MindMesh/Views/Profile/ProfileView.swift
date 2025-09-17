import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("darkModeEnabled") private var darkModeOn = false
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
                            Label("MindMesh Premium", systemImage: "sparkles")
                        }
                        .foregroundStyle(.mmTextPrimary)
                    }

                    Section("Info") {
                        LabeledContent("Versione", value: version)

                        Link(destination: URL(string: "https://mindmesh.app")!) {
                            Label("Sito web", systemImage: "safari")
                        }
                    }

                    Section {
                        Button("Esci dal profilo", role: .destructive) {
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
    @ObservedObject private var moodStore = MoodJournalStore.shared
    @State private var showPremiumSheet = false

    private var recentCheckinsCount: Int {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return moodStore.entries.filter { $0.date >= cutoff }.count
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

                        MMPrimaryButton(title: "Scopri Premium", icon: "sparkles", gradient: .mmRoseGradient, glowColor: .mmRose) {
                            showPremiumSheet = true
                        }
                    }
                    .padding(.top, MMSpacing.lg)
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
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
                        Text("Claudia")
                            .font(MMFont.display(28, weight: .bold))
                            .foregroundStyle(.mmTextPrimary)

                        Text("Piano base")
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

private struct PremiumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showComingSoon = false

    private let features = [
        ("sparkles", "Riflessioni più profonde", "Spunti meno generici e più mirati."),
        ("square.and.arrow.up", "Export pulito", "Condividi mappe e riepiloghi senza attrito."),
        ("chart.line.uptrend.xyaxis", "Cronologia leggibile", "Vedi i cambi di tono nel tempo."),
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

                        Text("MindMesh Premium")
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

                    VStack(spacing: 12) {
                        MMPrimaryButton(
                            title: "Passa a Premium · €4,99 al mese",
                            icon: "sparkles",
                            gradient: LinearGradient.mmAccentGradient,
                            glowColor: .mmAccent
                        ) {
                            showComingSoon = true
                        }

                        MMSecondaryButton(title: "Non adesso") {
                            dismiss()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, MMSpacing.xl)
            }
        }
        .alert("Acquisti in arrivo", isPresented: $showComingSoon) {
            Button("Va bene", role: .cancel) {}
        } message: {
            Text("Per ora è un'anteprima. Quando gli acquisti saranno pronti, potrai attivarli da qui.")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .previewDisplayName("Impostazioni")

            ProfileView()
                .previewDisplayName("Profilo")

            PremiumSheet()
                .previewDisplayName("Premium")
        }
    }
}
