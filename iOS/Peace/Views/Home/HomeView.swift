import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var expandedNoteEntryID: UUID?
    @State private var contentHeight: CGFloat = 0

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                GeometryReader { proxy in
                    let layout = MMLayoutMetrics(size: proxy.size, horizontalSizeClass: horizontalSizeClass)
                    let verticalInset = min(
                        max(MMSpacing.lg, (proxy.size.height - contentHeight) / 2),
                        layout.isPad ? 64 : MMSpacing.xxxl
                    )

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                            greetingBlock(layout: layout)

                            if layout.prefersSplitLayout {
                                HStack(alignment: .top, spacing: layout.sectionSpacing) {
                                    overviewCard(layout: layout)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)

                                    moodCard(layout: layout)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                    overviewCard(layout: layout)
                                    moodCard(layout: layout)
                                }
                            }
                        }
                        .background(
                            GeometryReader { contentProxy in
                                Color.clear
                                    .preference(key: HomeContentHeightPreferenceKey.self, value: contentProxy.size.height)
                            }
                        )
                        .frame(maxWidth: layout.screenContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, verticalInset)
                        .padding(.bottom, MMSpacing.xl)
                    }
                    .safeAreaPadding(.horizontal, layout.horizontalPadding)
                    .safeAreaPadding(.bottom, MMSpacing.sm)
                    .onPreferenceChange(HomeContentHeightPreferenceKey.self) { contentHeight = $0 }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func greetingBlock(layout: MMLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greetingLine(language: languageStore.selectedLanguage))
                .font(MMFont.display(layout.isPad ? 34 : 26, weight: .bold))
                .foregroundStyle(.mmTextPrimary)

            Text(t.homeSubtitle)
                .font(MMFont.body(layout.isPad ? 16 : 14))
                .foregroundStyle(.mmTextMuted)
                .lineSpacing(3)
        }
        .padding(.bottom, MMSpacing.md)
    }

    private func overviewCard(layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, cornerRadius: MMRadius.md, borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                MMSectionLabel(text: t.summarySection)

                Text(vm.dailyTitle(language: languageStore.selectedLanguage))
                    .font(MMFont.display(layout.isPad ? 28 : 22, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text(vm.dailyMessage(language: languageStore.selectedLanguage))
                    .font(MMFont.body(layout.isPad ? 15 : 13))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: layout.cardMinHeight, alignment: .topLeading)
        }
    }

    private func moodCard(layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding, cornerRadius: MMRadius.md, backgroundColor: Color.mmCard.opacity(0.88)) {
            VStack(alignment: .leading, spacing: MMSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        MMSectionLabel(text: t.trendSection)
                        Text(t.lastSevenDays)
                            .font(MMFont.title(layout.isPad ? 22 : 18, weight: .semibold))
                            .foregroundStyle(.mmTextPrimary)
                    }

                    Spacer()

                    if let latestMood = vm.moodEntries.last?.mood {
                        MMInlineBadge(title: latestMood.label(in: languageStore.selectedLanguage), icon: latestMood.symbolName, tint: latestMood.color)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(vm.weekMoods(language: languageStore.selectedLanguage), id: \.day) { item in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill((item.entry?.mood.color ?? Color.mmSurface).opacity(item.entry == nil ? 0.45 : 0.14))
                                .frame(width: layout.isPad ? 42 : 34, height: layout.isPad ? 42 : 34)
                                .overlay(
                                    Image(systemName: item.entry?.mood.symbolName ?? "minus")
                                        .font(.system(size: layout.isPad ? 15 : 13, weight: .semibold))
                                        .foregroundStyle(item.entry?.mood.color ?? .mmTextDim)
                                )

                            Text(item.day)
                                .font(MMFont.caption(layout.isPad ? 11 : 10, weight: .medium))
                                .foregroundStyle(.mmTextDim)

                            if hasNote(for: item.entry) {
                                Button {
                                    toggleNote(for: item.entry)
                                } label: {
                                    Text(t.notePill)
                                        .font(MMFont.caption(layout.isPad ? 10 : 9, weight: .semibold))
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
                                    .frame(height: layout.isPad ? 23 : 21)
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

                            Text(t.yourNote(day: selectedNote.day))
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
                            .font(MMFont.body(layout.isPad ? 14 : 13))
                            .foregroundStyle(.mmTextMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, layout.isPad ? 18 : 14)
                    .padding(.vertical, layout.isPad ? 16 : 12)
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
            .frame(maxWidth: .infinity, minHeight: layout.cardMinHeight, alignment: .topLeading)
        }
    }

    private var expandedWeekNote: (day: String, entry: MoodEntry)? {
        vm.weekMoods(language: languageStore.selectedLanguage).first { item in
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

private struct HomeContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
