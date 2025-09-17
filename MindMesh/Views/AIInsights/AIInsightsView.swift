import SwiftUI

struct AIInsightsView: View {
    @ObservedObject private var store = MoodJournalStore.shared

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
                            detailCard(snapshot: snapshot)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.top, MMSpacing.lg)
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationTitle("Riflessioni")
            .navigationBarTitleDisplayMode(.large)
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

                    Image(systemName: "waveform.path.ecg")
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

                Text("Registra piu spesso il tuo umore nei prossimi giorni. Quando ci saranno almeno 3 registrazioni recenti, qui comparira un'analisi reale.")
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
