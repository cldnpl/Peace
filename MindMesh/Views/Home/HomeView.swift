import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MMSpacing.xl) {
                        greetingBlock
                        overviewCard
                        moodCard
                    }
                    .padding(.top, MMSpacing.sm)
                    .padding(.bottom, MMSpacing.xl)
                }
                .safeAreaPadding(.horizontal, MMSpacing.md)
                .safeAreaPadding(.bottom, MMSpacing.sm)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greetingLine)
                .font(MMFont.display(26, weight: .bold))
                .foregroundStyle(.mmTextPrimary)

            Text("Qui trovi il punto della giornata e l'andamento recente, senza altro rumore.")
                .font(MMFont.body(14))
                .foregroundStyle(.mmTextMuted)
                .lineSpacing(3)
        }
    }

    private var overviewCard: some View {
        MMCard(padding: MMSpacing.lg, cornerRadius: MMRadius.md, borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                MMSectionLabel(text: "Sintesi")

                Text(vm.dailyTitle)
                    .font(MMFont.display(22, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text(vm.dailyMessage)
                    .font(MMFont.body(13))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        }
    }

    private var moodCard: some View {
        MMCard(padding: MMSpacing.lg, cornerRadius: MMRadius.md, backgroundColor: Color.mmCard.opacity(0.88)) {
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        MMSectionLabel(text: "Andamento")
                        Text("Ultimi sette giorni")
                            .font(MMFont.title(18, weight: .semibold))
                            .foregroundStyle(.mmTextPrimary)
                    }

                    Spacer()

                    if let latestMood = vm.moodEntries.last?.mood {
                        MMInlineBadge(title: latestMood.label, icon: latestMood.symbolName, tint: latestMood.color)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(vm.weekMoods, id: \.day) { item in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill((item.entry?.mood.color ?? Color.mmSurface).opacity(item.entry == nil ? 0.45 : 0.14))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: item.entry?.mood.symbolName ?? "minus")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(item.entry?.mood.color ?? .mmTextDim)
                                )

                            Text(item.day)
                                .font(MMFont.caption(10, weight: .medium))
                                .foregroundStyle(.mmTextDim)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
