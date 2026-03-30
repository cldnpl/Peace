import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var expandedNoteEntryID: UUID?

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
                    .padding(.bottom, MMSpacing.xl)
                }
                .safeAreaPadding(.horizontal, MMSpacing.md)
                .safeAreaPadding(.bottom, MMSpacing.sm)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
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

                            if hasNote(for: item.entry) {
                                Button {
                                    toggleNote(for: item.entry)
                                } label: {
                                    Text("Nota")
                                        .font(MMFont.caption(9, weight: .semibold))
                                        .foregroundStyle(expandedNoteEntryID == item.entry?.id ? Color.white : (item.entry?.mood.color ?? .mmAccent))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    expandedNoteEntryID == item.entry?.id
                                                        ? (item.entry?.mood.color ?? .mmAccent)
                                                        : (item.entry?.mood.color ?? .mmAccent).opacity(0.12)
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .strokeBorder((item.entry?.mood.color ?? .mmAccent).opacity(0.18), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear
                                    .frame(height: 21)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if let selectedNote = expandedWeekNote {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedNote.entry.mood.color)

                            Text("\(selectedNote.day) · La tua nota")
                                .font(MMFont.caption(12, weight: .semibold))
                                .foregroundStyle(.mmTextPrimary)

                            Spacer()

                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                    expandedNoteEntryID = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.mmTextDim)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.mmSurface.opacity(0.7))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Text(selectedNote.entry.note.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(MMFont.body(13))
                            .foregroundStyle(.mmTextMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.mmSurface.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.mmBorderStrong, lineWidth: 1)
                            )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        }
    }

    private var expandedWeekNote: (day: String, entry: MoodEntry)? {
        vm.weekMoods.first { item in
            item.entry?.id == expandedNoteEntryID && hasNote(for: item.entry)
        }.flatMap { item in
            guard let entry = item.entry else { return nil }
            return (item.day, entry)
        }
    }

    private func hasNote(for entry: MoodEntry?) -> Bool {
        guard let entry else { return false }
        return entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func toggleNote(for entry: MoodEntry?) {
        guard let entry, hasNote(for: entry) else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            expandedNoteEntryID = expandedNoteEntryID == entry.id ? nil : entry.id
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
