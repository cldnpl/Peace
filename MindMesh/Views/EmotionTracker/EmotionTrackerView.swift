import SwiftUI

struct EmotionTrackerView: View {
    @StateObject private var vm = EmotionViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var crownSelection = Double(MoodLevel.neutral.rawValue)

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
                        VStack(alignment: .leading, spacing: 0) {
                            MMNavigationHeaderBlock(
                                text: t.moodTitle,
                                topPadding: layout.headerTopPadding,
                                bottomPadding: layout.isPad ? MMSpacing.xl : MMSpacing.md
                            )

                            if layout.prefersSplitLayout {
                                HStack(alignment: .top, spacing: layout.sectionSpacing) {
                                    emotionSelector(layout: layout)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)

                                    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                        noteField(layout: layout)
                                        logButton

                                        if vm.showSuccess {
                                            successBanner(layout: layout)
                                        }

                                        energyChart(layout: layout)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                                    emotionSelector(layout: layout)
                                    noteField(layout: layout)
                                    logButton

                                    if vm.showSuccess {
                                        successBanner(layout: layout)
                                    }

                                    energyChart(layout: layout)
                                }
                            }
                        }
                        .frame(maxWidth: layout.screenContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 40)
                    }
                    .safeAreaPadding(.horizontal, layout.horizontalPadding)
                    .safeAreaPadding(.bottom, MMSpacing.md)
                    .scrollDismissesKeyboard(.interactively)
                    .mmCrownSelection($crownSelection, range: 0...Double(MoodLevel.allCases.count - 1))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sensoryFeedback(.selection, trigger: vm.selectedMood?.rawValue ?? -1)
            .sensoryFeedback(.success, trigger: vm.showSuccess) { _, newValue in
                newValue
            }
            .onAppear {
                crownSelection = Double(vm.selectedMood?.rawValue ?? MoodLevel.neutral.rawValue)
            }
            .onChange(of: crownSelection) { _, newValue in
                vm.selectedMood = MoodLevel(rawValue: Int(newValue.rounded()))
            }
            .onChange(of: vm.selectedMood?.rawValue ?? MoodLevel.neutral.rawValue) { _, newValue in
                crownSelection = Double(newValue)
            }
        }
    }

    private func emotionSelector(layout: MMLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.lg) {
            Text(t.moodSelectorHint)
                .font(.system(size: layout.isPad ? 17 : 16))
                .foregroundStyle(.mmTextMuted)
                .lineSpacing(4)

            LazyVGrid(
                columns: layout.moodGridColumns,
                spacing: MMSpacing.md
            ) {
                ForEach(MoodLevel.allCases) { mood in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            vm.selectedMood = mood
                        }
                    } label: {
                        MoodCard(mood: mood, isSelected: vm.selectedMood == mood, isPadLayout: layout.isPad)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func noteField(layout: MMLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            MMSectionLabel(text: t.noteSection)

            TextField(t.notePlaceholder, text: $vm.noteText, axis: .vertical)
                .font(.system(size: layout.isPad ? 15 : 14))
                .foregroundStyle(.mmTextPrimary)
                .lineLimit(3...5)
                .padding(layout.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                        .fill(Color.mmCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: MMRadius.md, style: .continuous)
                                .strokeBorder(Color.mmBorder, lineWidth: 1)
                        )
                        .mmCardShadow()
                )
        }
    }

    private var logButton: some View {
        MMPrimaryButton(
            title: vm.hasLoggedToday ? t.updateDay : t.saveHowYouFeel,
            icon: "checkmark",
            gradient: .mmRoseGradient,
            glowColor: .mmRose
        ) {
            vm.logMood()
        }
        .disabled(vm.selectedMood == nil)
        .opacity(vm.selectedMood == nil ? 0.48 : 1)
    }

    private func successBanner(layout: MMLayoutMetrics) -> some View {
        MMCard(
            padding: layout.cardPadding,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmAccent3.opacity(0.18),
            backgroundColor: Color.mmAccent3.opacity(0.08)
        ) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.mmAccent3)

                Text(t.doneReady)
                    .font(.system(size: layout.isPad ? 15 : 14, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func energyChart(layout: MMLayoutMetrics) -> some View {
        MMCard(padding: layout.cardPadding) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    MMSectionLabel(text: t.trendSection)
                    Text(t.energyMovement)
                        .font(.system(size: layout.isPad ? 26 : 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.mmTextPrimary)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(vm.weekBarData(language: languageStore.selectedLanguage), id: \.day) { bar in
                        VStack(spacing: 8) {
                            Spacer()

                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(bar.color.opacity(bar.height <= 0.05 ? 0.55 : 1))
                                .frame(maxWidth: .infinity)
                                .frame(height: max(layout.isPad ? 14 : 10, bar.height * (layout.isPad ? 122 : 104)))

                            Text(bar.day)
                                .font(.system(size: layout.isPad ? 11 : 10, weight: .medium))
                                .foregroundStyle(.mmTextDim)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: layout.isPad ? 152 : 128)
            }
        }
    }
}

private struct MoodCard: View {
    let mood: MoodLevel
    let isSelected: Bool
    let isPadLayout: Bool
    @EnvironmentObject private var languageStore: AppLanguageStore

    var body: some View {
        MMCard(
            padding: isPadLayout ? 24 : MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: isSelected ? mood.color.opacity(0.50) : Color.mmBorder,
            backgroundColor: isSelected ? Color.mmCard.opacity(0.98) : Color.mmCard.opacity(0.86)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(mood.color.opacity(isSelected ? 0.18 : 0.12))
                        .frame(width: isPadLayout ? 50 : 44, height: isPadLayout ? 50 : 44)
                        .overlay(
                            Image(systemName: mood.symbolName)
                                .font(.system(size: isPadLayout ? 20 : 18, weight: .semibold))
                                .foregroundStyle(mood.color)
                        )

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(mood.color)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mood.label(in: languageStore.selectedLanguage))
                        .font(.system(size: isPadLayout ? 17 : 16, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(mood.detail(in: languageStore.selectedLanguage))
                        .font(.system(size: isPadLayout ? 13 : 12))
                        .foregroundStyle(.mmTextMuted)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isPadLayout ? 144 : 128, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .shadow(
            color: isSelected ? mood.color.opacity(0.16) : .clear,
            radius: isSelected ? 14 : 0,
            x: 0,
            y: 6
        )
    }
}

struct EmotionTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionTrackerView()
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
    }
}
