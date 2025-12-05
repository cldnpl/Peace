import SwiftUI

struct AIInsightsView: View {
    @ObservedObject private var store = MoodJournalStore.shared
    @AppStorage("peace.premiumUnlocked") private var premiumUnlocked = false
    @State private var showPremiumSheet = false

    private var snapshot: MoodReflectionSnapshot? {
        store.reflectionSnapshot()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
                        if let snapshot {
                            reflectionCard(snapshot: snapshot)
                            overviewCard(snapshot: snapshot)
                            detailCard(snapshot: snapshot)
                            premiumCard(snapshot: snapshot)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationTitle("Riflessioni")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
        }
    }

    private func reflectionCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.16), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: "Ultimi 7 giorni")

                Text(snapshot.title)
                    .font(MMFont.display(30, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text(snapshot.message)
                    .font(MMFont.body(15))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func detailCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                Text(snapshot.detailTitle)
                    .font(MMFont.caption(13, weight: .semibold))
                    .foregroundStyle(.mmTextMuted)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(snapshot.detailValue)
                        .font(MMFont.display(34, weight: .bold))
                        .foregroundStyle(.mmTextPrimary)

                    Image(systemName: "waveform.path.ecg"
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.mmAccent3)
                }

                Text(snapshot.detailMessage)
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func overviewCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard(backgroundColor: Color.mmCard.opacity(0.9)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: "Panoramica")

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.dominantMoodLabel, label: "Voce che torna di più", color: .mmAccent)
                    StatCard(value: snapshot.trendLabel, label: "Andamento recente", color: .mmAccent3)
                }

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.energyLabel, label: "Energia media", color: .mmTeal)
                    StatCard(value: snapshot.consistencyLabel, label: "Quanto cambia il tono", color: .mmRose)
                }
            }
        }
    }

    @ViewBuilder
    private func premiumCard(snapshot: MoodReflectionSnapshot) -> some View {
        if premiumUnlocked {
            MMCard(borderColor: Color.mmAccent.opacity(0.18), backgroundColor: Color.mmCard.opacity(0.94)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    HStack {
                        MMSectionLabel(text: "Analisi completa")
                        Spacer()
                        MMInlineBadge(title: "Premium", icon: "sparkles", tint: .mmAccent)
                    }

                    Text(snapshot.premiumInsightTitle)
                        .font(MMFont.title(22, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(snapshot.premiumInsightMessage)
                        .font(MMFont.body(15))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(4)

                    MMCard(
                        padding: MMSpacing.lg,
                        cornerRadius: MMRadius.md,
                        borderColor: Color.mmAccent2.opacity(0.18),
                        backgroundColor: Color.mmSurface.opacity(0.72)
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spunto pratico")
                                .font(MMFont.caption(12, weight: .semibold))
                                .foregroundStyle(.mmTextMuted)

                            Text(snapshot.premiumSuggestion)
                                .font(MMFont.body(14))
                                .foregroundStyle(.mmTextPrimary)
                                .lineSpacing(3)
                        }
                    }
                }
            }
        } else {
            MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    HStack {
                        MMSectionLabel(text: "Analisi completa")
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.mmAccent)
                    }

                    Text("La panoramica è pronta. L'analisi completa si sblocca con Premium.")
                        .font(MMFont.title(22, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text("Con Premium puoi leggere un pattern più preciso, il livello di stabilità e uno spunto pratico costruito sui tuoi ultimi check-in.")
                        .font(MMFont.body(14))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(4)

                    MMPrimaryButton(title: "Sblocca l'analisi completa", icon: "sparkles") {
                        showPremiumSheet = true
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.mmSurface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.mmAccent)
                    )

                Text("Non ho ancora abbastanza dati per una riflessione approfondita.")
                    .font(MMFont.display(28, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text("Registra piu spesso il tuo umore nei prossimi giorni. Quando ci saranno almeno 3 registrazioni recenti, qui comparira una panoramica reale dell'andamento.")
                    .font(MMFont.body(15))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }
}

struct AIInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        AIInsightsView()
    }
}
